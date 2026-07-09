import 'package:flutter/material.dart';
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
      body: Stack(
        children: [
          // Gradasi Pojok Kiri Atas
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [warnaTosca.withOpacity(0.4), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          // Gradasi Pojok Kanan Bawah
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [warnaTosca.withOpacity(0.3), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          // Konten Utama
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 60),
                        Image.asset(
                          'assets/icon/app_icon.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.menu_book_rounded, size: 140, color: warnaTosca),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Gumregah\nDongeng',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            height: 1.1,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: warnaTosca.withOpacity(0.5), width: 1.5),
                          ),
                          child: const Text(
                            'Belajar jadi lebih mudah dan bermakna',
                            style: TextStyle(fontSize: 12, color: warnaTosca, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor: Color(0xFFE0F2F1),
                              valueColor: AlwaysStoppedAnimation<Color>(warnaTosca),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Menyiapkan ruang belajarmu...',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 30),
                        const Text('Landscape sponsors', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 10),
                        Image.asset(
                          'assets/images/logo_sponsor.png',
                          height: 35,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('[Logo Sponsor Area]', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}