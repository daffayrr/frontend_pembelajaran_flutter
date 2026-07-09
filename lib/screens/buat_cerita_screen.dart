//import 'dart:convert';
import 'dart:convert';

import 'package:flutter/foundation.dart'; // Untuk mengecek kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

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

  // Menggunakan XFile dan Uint8List agar aman di-debug via Chrome (Web) maupun Android
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

  // Fungsi untuk memilih gambar dari Galeri HP / File Explorer Web
  Future<void> _pilihSampul() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _sampulFile = pickedFile;
        _sampulBytes = bytes;
      });
    }
  }

  // Fungsi Upload ke CodeIgniter 4
  Future<void> _unggahCerita() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan isi cerita tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(endpointMateri));

      request.fields['judul'] = _judulController.text;
      request.fields['tipe'] = 'cerita';
      request.fields['sinopsis'] = _isiController.text;

      // Jika ada gambar sampul, lampirkan sebagai bytes (Aman untuk Chrome & Android)
      // Jika ada gambar sampul, lampirkan sebagai bytes (Aman untuk Chrome & Android)
      if (_sampulFile != null && _sampulBytes != null) {
        String originalName = _sampulFile!.name;

        // Deteksi apakah ada titiknya. Jika tidak ada (kasus Web/Chrome), paksa jadi jpg
        String ext = originalName.contains('.')
            ? originalName.split('.').last.toLowerCase()
            : 'jpg';
        String format = (ext == 'png') ? 'png' : 'jpeg';

        // Rakit nama file yang dijamin aman dan memiliki ekstensi
        String safeFilename = originalName.contains('.')
            ? originalName
            : 'sampul_cerita.$ext';

        request.files.add(
          http.MultipartFile.fromBytes(
            'file_sampul',
            _sampulBytes!,
            filename: safeFilename, // <--- Gunakan nama yang sudah dijamin aman
            contentType: MediaType('image', format),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hore! Ceritamu berhasil diterbitkan!'),
              backgroundColor: Colors.green,
            ),
          );
          _judulController.clear();
          _isiController.clear();
          setState(() {
            _sampulFile = null;
            _sampulBytes = null;
          });
        }
      } else {
        // --- KODE BARU UNTUK MENANGKAP ERROR ---
        String pesanError = 'Gagal mengunggah cerita.';
        try {
          final data = json.decode(response.body);
          print('--- DEBUG API CI4 ---');
          print(response.body); // Cetak detail error di Terminal VS Code
          print('---------------------');

          if (data['messages'] != null) {
            pesanError = (data['messages'] as Map).values.join('\n');
          } else if (data['message'] != null) {
            pesanError = data['message']; // Tangkap error database (500)
          }
        } catch (e) {
          print('Error response text: ${response.body}');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pesanError),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan jaringan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: warnaTosca)),
      );
    }

    // Tampilan jika pengguna adalah TAMU (Belum Login)
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_document, size: 90, color: Colors.grey[300]),
                const SizedBox(height: 20),
                const Text(
                  'Fitur Eksklusif Member',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Silakan masuk atau buat akun terlebih dahulu untuk bisa menulis dan membagikan ceritamu ke komunitas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warnaTosca,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'MASUK / DAFTAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tampilan Editor Cerita untuk PENGGUNA LOGIN
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tulis Cerita',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Tombol Publish di Pojok Kanan Atas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: ElevatedButton(
              onPressed: isUploading ? null : _unggahCerita,
              style: ElevatedButton.styleFrom(
                backgroundColor: warnaTosca,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Publish',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 25,
          right: 25,
          top: 10,
          bottom: 120,
        ), // Bottom padding untuk area Nav Bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Area Upload Gambar Sampul
            GestureDetector(
              onTap: isUploading ? null : _pilihSampul,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: _sampulBytes != null
                      ? Colors.black12
                      : warnaTosca.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: _sampulBytes != null
                      ? null
                      : Border.all(
                          color: warnaTosca.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                ),
                child: _sampulBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_sampulBytes!, fit: BoxFit.cover),
                            Container(
                              color: Colors.black.withOpacity(0.3),
                            ), // Efek redup agar ikon pensil terlihat
                            const Center(
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 50,
                            color: warnaTosca,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tambahkan Sampul Cerita (Opsional)',
                            style: TextStyle(
                              color: warnaTosca,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Input Judul Cerita
            TextField(
              controller: _judulController,
              enabled: !isUploading,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Judul Cerita...',
                hintStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
            ),

            const Divider(color: Colors.black12, thickness: 1, height: 30),

            // 3. Input Isi Cerita
            TextField(
              controller: _isiController,
              enabled: !isUploading,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Tuliskan kisah menarikmu di sini...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines:
                  null, // Membiarkan text area meluas ke bawah secara otomatis
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
    );
  }
}
