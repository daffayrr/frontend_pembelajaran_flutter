import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';
import 'package:dotted_border/dotted_border.dart';

class BuatCeritaScreen extends StatefulWidget {
  const BuatCeritaScreen({super.key});

  @override
  State<BuatCeritaScreen> createState() => _BuatCeritaScreenState();
}

class _BuatCeritaScreenState extends State<BuatCeritaScreen> {
  bool isLoggedIn = false;
  bool isCheckingAuth = true;
  bool isUploading = false;

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();

  XFile? _sampulFile;
  Uint8List? _sampulBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      isLoggedIn = token != null;
      isCheckingAuth = false;
    });
  }

  Future<void> _pilihSampul() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _sampulFile = pickedFile;
        _sampulBytes = bytes;
      });
    }
  }

  Future<void> _unggahCerita() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi cerita tidak boleh kosong!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(endpointMateri));
      request.fields['judul'] = _judulController.text;
      request.fields['tipe'] = 'cerita';
      request.fields['sinopsis'] = _isiController.text;

      if (_sampulFile != null && _sampulBytes != null) {
        String originalName = _sampulFile!.name;
        String ext = originalName.contains('.') ? originalName.split('.').last.toLowerCase() : 'jpg';
        String format = (ext == 'png') ? 'png' : 'jpeg';
        String safeFilename = originalName.contains('.') ? originalName : 'sampul_cerita.$ext';

        request.files.add(
          http.MultipartFile.fromBytes(
            'file_sampul',
            _sampulBytes!,
            filename: safeFilename,
            contentType: MediaType('image', format),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hore! Ceritamu berhasil diterbitkan!'), backgroundColor: Colors.green),
          );
          _judulController.clear();
          _isiController.clear();
          setState(() {
            _sampulFile = null;
            _sampulBytes = null;
          });
        }
      } else {
        String pesanError = 'Gagal mengunggah cerita.';
        try {
          final data = json.decode(response.body);
          if (data['messages'] != null) pesanError = (data['messages'] as Map).values.join('\n');
          else if (data['message'] != null) pesanError = data['message'];
        } catch (e) {
          // ignore
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesanError), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingAuth) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: warnaTosca)));
    }

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_document, size: 90, color: Colors.grey[300]),
                const SizedBox(height: 20),
                const Text('Fitur Eksklusif Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                const Text('Silakan masuk atau buat akun terlebih dahulu.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
                const SizedBox(height: 35),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    style: ElevatedButton.styleFrom(backgroundColor: warnaTosca, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
                    child: const Text('MASUK / DAFTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tulis Cerita', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Bagikan imajinasimu, ciptakan dongeng yang luar biasa', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : _unggahCerita,
              icon: isUploading ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 16, color: Colors.white),
              label: Text(isUploading ? 'Menyimpan...' : 'Simpan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: warnaTosca,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area Unggah Thumbnail
            GestureDetector(
              onTap: isUploading ? null : _pilihSampul,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: warnaTosca.withOpacity(0.5),
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  radius: const Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: warnaTosca.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _sampulBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_sampulBytes!, fit: BoxFit.cover),
                              Container(color: Colors.black.withOpacity(0.3)),
                              const Center(child: Icon(Icons.edit_rounded, color: Colors.white, size: 40)),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_rounded, size: 50, color: warnaTosca),
                            const SizedBox(height: 10),
                            const Text('Unggah Gambar Thumbnail', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('Pilih gambar dari galeri atau ambil foto untuk cerita Anda', style: TextStyle(color: Colors.grey[500], fontSize: 11), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: isUploading ? null : _pilihSampul,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: warnaTosca,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                minimumSize: const Size(120, 36),
                              ),
                              child: const Text('Pilih Gambar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Input Judul Cerita
            const Text('Judul Cerita', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _judulController,
                enabled: !isUploading,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Misal: Kancil dan Buaya',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.description_outlined, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Area Editor Teks
            const Text('Cerita Kamu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Toolbar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_bold_rounded, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 16),
                            Icon(Icons.format_italic_rounded, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 16),
                            Icon(Icons.link_rounded, color: Colors.grey[600], size: 20),
                          ],
                        ),
                        Text('0 kata', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                  // Editor
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _isiController,
                      enabled: !isUploading,
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(height: 1.6, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Tulis dongeng di sini...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tips Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warnaTosca.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: warnaTosca, shape: BoxShape.circle),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tips: Ceritakan tokoh, latar, dan pesan moral agar dongeng kamu lebih menarik!',
                      style: TextStyle(color: warnaTosca, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
