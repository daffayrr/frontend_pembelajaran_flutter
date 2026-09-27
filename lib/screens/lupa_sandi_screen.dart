import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class LupaSandiScreen extends StatefulWidget {
  // Boleh pakai const di sini
  const LupaSandiScreen({super.key});

  @override
  State<LupaSandiScreen> createState() => _LupaSandiScreenState();
}

class _LupaSandiScreenState extends State<LupaSandiScreen> {
  final _emailController = TextEditingController();
  final _sandiBaruController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailValid = false;
  bool _isObscureBaru = true;
  bool _isObscureKonfirmasi = true;

  Future<void> _cekEmail() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(endpointCekEmail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        setState(() => _isEmailValid = true);
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Email tidak ditemukan'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _resetPassword() async {
    if (_sandiBaruController.text.isEmpty ||
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
          content: Text('Konfirmasi sandi tidak cocok!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(endpointResetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password_baru': _sandiBaruController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sandi berhasil direset! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mereset sandi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    _emailController.dispose();
    _sandiBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaLatar,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: warnaTosca,
                ),
                const SizedBox(height: 20),
                Text(
                  _isEmailValid ? 'Buat Sandi Baru' : 'Lupa Kata Sandi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isEmailValid
                      ? 'Masukkan kata sandi baru untuk akun Anda.'
                      : 'Masukkan email akun Anda untuk verifikasi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                if (!_isEmailValid) ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Terdaftar',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: warnaTosca,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cekEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warnaTosca,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'LANJUTKAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],

                if (_isEmailValid) ...[
                  TextField(
                    controller: _sandiBaruController,
                    obscureText: _isObscureBaru,
                    decoration: InputDecoration(
                      labelText: 'Sandi Baru',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: warnaTosca,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscureBaru
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _isObscureBaru = !_isObscureBaru),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _konfirmasiController,
                    obscureText: _isObscureKonfirmasi,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Sandi Baru',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: warnaTosca,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscureKonfirmasi
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _isObscureKonfirmasi = !_isObscureKonfirmasi,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warnaTosca,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SIMPAN SANDI BARU',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
