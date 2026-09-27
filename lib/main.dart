import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_pembelajaran_flutter/screens/splash_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final interTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);
    final cinzelTheme = GoogleFonts.cinzelTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gumregah Dongeng',
      theme: ThemeData(
        textTheme: interTheme.copyWith(
          displayLarge: cinzelTheme.displayLarge,
          displayMedium: cinzelTheme.displayMedium,
          displaySmall: cinzelTheme.displaySmall,
          headlineLarge: cinzelTheme.headlineLarge,
          headlineMedium: cinzelTheme.headlineMedium,
          headlineSmall: cinzelTheme.headlineSmall,
          titleLarge: cinzelTheme.titleLarge,
          titleMedium: cinzelTheme.titleMedium,
          titleSmall: cinzelTheme.titleSmall,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          titleTextStyle: GoogleFonts.cinzel(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: warnaTosca),
      ),
      home: const SplashScreen(),
    );
  }
}
