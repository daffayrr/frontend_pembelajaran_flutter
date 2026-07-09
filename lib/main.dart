import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_pembelajaran_flutter/screens/splash_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart'; 

void main() {
  // 🚀 TAMBAHKAN BARIS INI: 
  // Menyalakan mesin Flutter terlebih dahulu sebelum merender pengaturan yang lain
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gumergah Dongeng', // Saya sesuaikan juga dengan nama barumu
      
      // --- PENGATURAN TEMA & FONT GLOBAL ---
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black87, 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: warnaTosca),
      ),
      
      home: const SplashScreen(),
    ),
  );
}