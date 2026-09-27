import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_pembelajaran_flutter/screens/main_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulasi loading atau pre-fetch data esensial
    await Future.delayed(const Duration(milliseconds: 2000));
    // Fetch data awal atau cek auth state bisa dilakukan di sini...
    // await _fetchData();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                  colors: [warnaTosca.withOpacity(0.15), Colors.transparent],
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
                  colors: [warnaTosca.withOpacity(0.15), Colors.transparent],
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
                    const SizedBox(), // Spacer atas
                    // Center (Logo & Title dengan Fade In)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icon/app_icon.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 140,
                                  color: warnaTosca,
                                ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Gumregah Dongeng',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bawah (Loading Indicator & Sponsor)
                    Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: warnaTosca,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat dunia dongeng...',
                          style: GoogleFonts.cinzel(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Image.asset(
                          'assets/images/logo_sponsor.png',
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                                '[Logo Sponsor Area]',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                        ),
                        const SizedBox(height: 10),
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
