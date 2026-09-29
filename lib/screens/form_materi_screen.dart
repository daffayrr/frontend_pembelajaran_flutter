import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class FormMateriScreen extends StatefulWidget {
  final dynamic materi;
  const FormMateriScreen({super.key, this.materi});

  @override
  State<FormMateriScreen> createState() => _FormMateriScreenState();
}

class _FormMateriScreenState extends State<FormMateriScreen> {
  final _judulController = TextEditingController();
  final _sinopsisController = TextEditingController();
  String _tipeAktif = 'pdf';
  bool _isLoading = false;
  late bool _isEdit;

  XFile? _sampulImage;
  Uint8List? _sampulBytes;

  XFile? _fileMateri;
  Uint8List? _fileMateriBytes;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.materi != null;
    if (_isEdit) {
      _judulController.text = widget.materi['judul'];
      _sinopsisController.text = widget.materi['sinopsis'] ?? '';
      _tipeAktif = widget.materi['tipe'];
    }
  }

  Future<void> _pilihSampul() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List? bytes;
      // 🚀 HANYA BACA KE RAM JIKA DI WEB
      if (kIsWeb) bytes = await pickedFile.readAsBytes();
      setState(() {
        _sampulImage = pickedFile;
        _sampulBytes = bytes;
      });
    }
  }

  Future<void> _pilihFileMateri() async {
    final XTypeGroup typeGroup = _tipeAktif == 'pdf'
        ? const XTypeGroup(
            label: 'Dokumen',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
          )
        : const XTypeGroup(
            label: 'Video',
            extensions: ['mp4'],
            mimeTypes: ['video/mp4'],
          );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      Uint8List? bytes;
      // 🚀 MENCEGAH FORCE CLOSE! Jangan muat file >100MB ke RAM Android
      if (kIsWeb) bytes = await file.readAsBytes();
      setState(() {
        _fileMateri = file;
        _fileMateriBytes = bytes;
      });
    }
  }

  Future<String> _uploadToS3(XFile file, String type) async {
    String extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : (type == 'cover' ? 'jpg' : type);
    String mimeType = 'application/octet-stream';
    if (type == 'cover') {
       mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    } else if (type == 'pdf') {
       mimeType = 'application/pdf';
    } else if (type == 'video') {
       mimeType = 'video/mp4';
    }

    var genUrlResponse = await http.post(
      Uri.parse('https://api-service.toscaflow.id/api/materi/generate-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': staticAuthToken,
      },
      body: jsonEncode({
        "type": type,
        "extension": extension,
        "content_type": mimeType
      }),
    );

    if (genUrlResponse.statusCode != 200) {
      throw Exception('Gagal meminta URL upload untuk $type');
    }

    var genUrlData = jsonDecode(genUrlResponse.body);
    String uploadUrl = genUrlData['data']['upload_url'];
    String fileKey = genUrlData['data']['file_key'];

    List<int> bytes = await file.readAsBytes();
    var s3Response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': mimeType,
      },
      body: bytes,
    );

    if (s3Response.statusCode != 200) {
      throw Exception('Gagal upload $type ke S3');
    }

    return fileKey;
  }

  Future<void> _simpanData() async {
    if (_judulController.text.isEmpty || _sinopsisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form teks wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isEdit && _tipeAktif != 'cerita' && _fileMateri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File PDF/Video wajib diunggah!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);

    try {
      String? fileSampulKey;
      String? fileMateriKey;

      if (_sampulImage != null) {
        fileSampulKey = await _uploadToS3(_sampulImage!, 'cover');
      }

      if (_tipeAktif != 'cerita' && _fileMateri != null) {
        fileMateriKey = await _uploadToS3(_fileMateri!, _tipeAktif);
      }

      var url = _isEdit
          ? Uri.parse('$endpointMateri/update/${widget.materi['id']}')
          : Uri.parse(endpointMateri);

      Map<String, dynamic> payload = {
        'judul': _judulController.text,
        'sinopsis': _sinopsisController.text,
      };
      
      if (!_isEdit) {
        payload['tipe'] = _tipeAktif;
      }

      if (fileSampulKey != null) payload['file_sampul'] = fileSampulKey;
      if (fileMateriKey != null) payload['file_materi'] = fileMateriKey;

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': staticAuthToken,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Materi berhasil diupdate!'
                  : 'Materi berhasil diunggah!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          'Gagal menyimpan ke server. Kode: ${response.statusCode}',
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Materi' : 'Tambah Materi Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown Tipe (Terkunci saat mode edit agar direktori S3 aman)
            if (!_isEdit) ...[
              const Text(
                'Tipe Materi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tipeAktif,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'pdf',
                        child: Text('E-Book (PDF)'),
                      ),
                      DropdownMenuItem(
                        value: 'video',
                        child: Text('Video Pembelajaran (MP4)'),
                      ),
                    ],
                    onChanged: (val) => setState(() {
                      _tipeAktif = val!;
                      _fileMateri = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: warnaTosca.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _tipeAktif == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.video_file,
                      color: warnaTosca,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mengedit Tipe: ${_tipeAktif.toUpperCase()}',
                      style: const TextStyle(
                        color: warnaTosca,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                labelText: 'Judul Materi',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sinopsisController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Sinopsis / Deskripsi Singkat',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Divider(height: 40),
            const Text(
              'File & Media',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),

            // Tombol Upload Sampul
            ListTile(
              tileColor: (_sampulImage != null || _sampulBytes != null)
                  ? Colors.green.withOpacity(0.1)
                  : const Color(0xFFF8F9FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              leading: const Icon(Icons.image, color: warnaTosca),
              title: Text(
                (_sampulImage != null || _sampulBytes != null)
                    ? 'Sampul Baru Dipilih'
                    : (_isEdit
                          ? 'Ganti Sampul (Opsional)'
                          : 'Upload Sampul (Opsional)'),
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.upload_rounded),
              onTap: _pilihSampul,
            ),
            const SizedBox(height: 10),

            // Tombol Upload File PDF/MP4
            if (_tipeAktif != 'cerita')
              ListTile(
                tileColor: (_fileMateri != null || _fileMateriBytes != null)
                    ? Colors.green.withOpacity(0.1)
                    : const Color(0xFFF8F9FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                leading: Icon(
                  _tipeAktif == 'pdf' ? Icons.picture_as_pdf : Icons.video_file,
                  color: warnaTosca,
                ),
                title: Text(
                  _fileMateri != null
                      ? _fileMateri!.name
                      : (_isEdit
                            ? 'Ganti File ${_tipeAktif.toUpperCase()} (Opsional)'
                            : 'Upload File ${_tipeAktif.toUpperCase()} *'),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.upload_rounded),
                onTap: _pilihFileMateri,
              ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnaTosca,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
