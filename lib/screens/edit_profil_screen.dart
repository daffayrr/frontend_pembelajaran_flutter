import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  String? _currentProfileUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _currentProfileUrl = prefs.getString('user_foto');
    });

    final userId = prefs.getString('user_id');
    if (userId != null) {
      try {
        final response = await http.get(
          Uri.parse('/'),
          headers: {'Authorization': staticAuthToken},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['data'] != null) {
            setState(() {
              _namaController.text = data['data']['nama'] ?? _namaController.text;
              _emailController.text = data['data']['email'] ?? _emailController.text;
              if (data['data']['foto_profil'] != null) {
                _currentProfileUrl = data['data']['foto_profil'];
                prefs.setString('user_foto', data['data']['foto_profil']);
              }
              prefs.setString('user_email', _emailController.text);
              prefs.setString('user_name', _namaController.text);
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetch profile: ');
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    }
  }

  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Potong Foto Profil',
          toolbarColor: warnaTosca,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Potong Foto Profil',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }

  Future<void> _simpanProfil() async {
    if (_namaController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan Email tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User ID tidak ditemukan. Silakan login ulang.');
      }

      // UPDATE NAMA & EMAIL DAHULU VIA JSON
      final uri = Uri.parse('$endpointUserProfil/$userId');
      var response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': staticAuthToken,
        },
        body: jsonEncode({
          'nama': _namaController.text,
          'email': _emailController.text,
        }),
      );
      
      var responseBody = response.body;

      if (response.statusCode == 200 && _imageFile != null) {
        // TAHAP 1: MINTA URL UPLOAD KE BACKEND
        String extension = _imageFile!.path.split('.').last.toLowerCase();
        String mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        
        var genUrlResponse = await http.post(
          Uri.parse('https://api-service.toscaflow.id/api/user/profil/generate-url/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': staticAuthToken,
          },
          body: jsonEncode({
            "extension": extension,
            "content_type": mimeType
          }),
        );
        
        if (genUrlResponse.statusCode == 200) {
          var genUrlData = jsonDecode(genUrlResponse.body);
          String uploadUrl = genUrlData['data']['upload_url'];
          String fileKey = genUrlData['data']['file_key'];
          
          // TAHAP 2: DIRECT UPLOAD KE S3
          List<int> imageBytes = await _imageFile!.readAsBytes();
          var s3Response = await http.put(
            Uri.parse(uploadUrl),
            headers: {
              'Content-Type': mimeType,
            },
            body: imageBytes,
          );
          
          if (s3Response.statusCode == 200) {
            // TAHAP 3: KONFIRMASI KE BACKEND
            var confirmResponse = await http.post(
              Uri.parse('https://api-service.toscaflow.id/api/user/profil/confirm/$userId'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': staticAuthToken,
              },
              body: jsonEncode({
                "file_key": fileKey
              }),
            );
            
            // Kita gabungkan respons dari update profil dengan confirm foto
            if (confirmResponse.statusCode == 200) {
               responseBody = confirmResponse.body;
            } else {
               responseBody = confirmResponse.body;
               response = confirmResponse;
            }
          } else {
             throw Exception('Gagal upload S3');
          }
        } else {
            throw Exception('Gagal generate URL S3');
        }
      }

      // CETAK KE TERMINAL UNTUK DEBUGGING
      print('=== DEBUG UPLOAD FOTO ===');
      print('Status Code: ${response.statusCode}');
      print('Raw Response: $responseBody');
      print('=========================');

      // Validasi keamanan: Pastikan respons diawali kurung kurawal/siku (tanda JSON)
      if (responseBody.trim().startsWith('{') || responseBody.trim().startsWith('[')) {
        var data = json.decode(responseBody);

        if (response.statusCode == 200) {
          await prefs.setString('user_name', _namaController.text);
          await prefs.setString('user_email', _emailController.text);

          if (data['data'] != null && data['data']['foto_profil'] != null) {
            await prefs.setString('user_foto', data['data']['foto_profil']);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil berhasil diperbarui!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          String errorMessage = data['message'] ?? 'Gagal memperbarui profil.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // ERROR SERVER MENTAH (HTML/Teks) - BUKAN JSON
        print('Peringatan: Server mengembalikan HTML/Teks mentah. Kemungkinan file terlalu besar atau server crash.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan pada server (Bukan JSON). Coba foto dengan ukuran lebih kecil.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error Exception saat upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koneksi terputus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE0F2F1),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : (_currentProfileUrl != null &&
                                  _currentProfileUrl!.isNotEmpty
                              ? NetworkImage(_currentProfileUrl!)
                              : null),
                    child:
                        (_imageFile == null &&
                            (_currentProfileUrl == null ||
                                _currentProfileUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: warnaTosca)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: warnaTosca,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ketuk untuk mengganti foto',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
            _buildTextField(
              'Nama Lengkap',
              Icons.person_outline,
              _namaController,
            ),
            const SizedBox(height: 20),
            _buildTextField('Email', Icons.email_outlined, _emailController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanProfil,
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
                        'Simpan Perubahan',
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

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: warnaTosca),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
