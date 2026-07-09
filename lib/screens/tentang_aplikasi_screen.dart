import 'package:flutter/material.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      // Dibungkus SingleChildScrollView agar tidak overflow (layar nabrak bawah) saat di HP kecil
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO APLIKASI ---
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: warnaTosca.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.auto_stories_rounded,
                      size: 60,
                      color: warnaTosca,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- NAMA APLIKASI ---
              const Text(
                'Gumregah Dongeng', // ---> Sudah diubah menjadi Gumregah
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),

              // --- VERSI ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Versi 1.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- PENJELASAN APLIKASI ---
              const Text(
                'Gumregah Dongeng adalah ruang interaktif yang didedikasikan untuk menghidupkan kembali tradisi bercerita dan literasi. Aplikasi ini menyajikan berbagai kisah inspiratif, cerita dari komunitas, serta materi edukatif yang dirancang untuk membangun karakter, kreativitas, dan imajinasi dalam satu genggaman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
              ),
              const SizedBox(height: 60),

              // --- FOOTER DEDIKASI ---
              const Divider(color: Colors.black12),
              const SizedBox(height: 20),
              Text(
                'Dikembangkan dengan sepenuh hati',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 5),
              const Text(
                'Untuk Literasi Nusantara',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: warnaTosca,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // --- LOGO SPONSOR ---
              Image.asset(
                'assets/images/logo_sponsor.png',
                height: 40, // Tinggi disesuaikan dengan yang di Splash Screen
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 40,
                  child: Text(
                    '[Logo Sponsor Area]',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
