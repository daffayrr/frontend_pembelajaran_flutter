import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend_pembelajaran_flutter/screens/main_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // === BAGIAN ATAS ===
                Column(
                  children: [
                    const SizedBox(height: 40),
                    Lottie.asset(
                      'assets/animations/tosca_splash.json',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      repeat: false,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Gumregah Dongeng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: warnaTosca.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Belajar jadi lebih mudah dan bermakna',
                        style: TextStyle(
                          fontSize: 13,
                          color: warnaTosca,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // === BAGIAN BAWAH ===
                Column(
                  children: [
                    // Progress Bar Menyamping (Dibuat sedikit lebih ramping)
                    SizedBox(
                      width: 140, // Lebar diperkecil
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          minHeight: 5, // Ketebalan diperkecil
                          backgroundColor: Color(0xFFE0F2F1),
                          valueColor: AlwaysStoppedAnimation<Color>(warnaTosca),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Menyiapkan ruang belajarmu...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12, // Font diperkecil sedikit
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Logo Sponsor Landscape (Diperbesar secara signifikan)
                    Image.asset(
                      'assets/images/logo_sponsor.png',
                      height: 45, // ---> Tinggi logo diubah dari 40 menjadi 80
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            height: 80,
                            child: Text(
                              '[Logo Sponsor Area]',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
