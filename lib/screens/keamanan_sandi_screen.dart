import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class KeamananSandiScreen extends StatefulWidget {
  const KeamananSandiScreen({super.key});

  @override
  State<KeamananSandiScreen> createState() => _KeamananSandiScreenState();
}

class _KeamananSandiScreenState extends State<KeamananSandiScreen> {
  final TextEditingController _sandiLamaController = TextEditingController();
  final TextEditingController _sandiBaruController = TextEditingController();
  final TextEditingController _konfirmasiController = TextEditingController();

  bool _isObscureLama = true;
  bool _isObscureBaru = true;
  bool _isLoading = false;

  Future<void> _perbaruiSandi() async {
    if (_sandiLamaController.text.isEmpty ||
        _sandiBaruController.text.isEmpty ||
        _konfirmasiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sandiBaruController.text != _konfirmasiController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok!'),
          backgroundColor: Colors.orange,
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

      final response = await http.put(
        Uri.parse('$endpointUserPassword/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password_lama': _sandiLamaController.text,
          'password_baru': _sandiBaruController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sandi berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        String errorMessage = data['message'] ?? 'Gagal memperbarui sandi.';
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan.'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _sandiLamaController.dispose();
    _sandiBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Keamanan & Sandi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            const Text(
              'Ubah Kata Sandi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pastikan kata sandi baru Anda terdiri dari minimal 6 karakter agar akun tetap aman.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            _buildPasswordField(
              'Kata Sandi Saat Ini',
              _sandiLamaController,
              _isObscureLama,
              () => setState(() => _isObscureLama = !_isObscureLama),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              'Kata Sandi Baru',
              _sandiBaruController,
              _isObscureBaru,
              () => setState(() => _isObscureBaru = !_isObscureBaru),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              'Konfirmasi Sandi Baru',
              _konfirmasiController,
              _isObscureBaru,
              () => setState(() => _isObscureBaru = !_isObscureBaru),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _perbaruiSandi,
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
                        'Perbarui Kata Sandi',
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

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscure,
    VoidCallback toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: warnaTosca),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggleVisibility,
        ),
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
