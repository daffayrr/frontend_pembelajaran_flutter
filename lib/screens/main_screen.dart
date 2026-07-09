import 'package:flutter/material.dart';
import 'package:frontend_pembelajaran_flutter/screens/daftar_cerita_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/screens/dashboard_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/akun_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/bookmark_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/buat_cerita_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _halaman = [
    const DashboardScreen(),
    const BookmarkScreen(),
    const BuatCeritaScreen(),
    const DaftarCeritaScreen(), // <--- Ganti di baris ini (Index ke-3)
    const AkunScreen(), // <--- Ganti di baris ini (Index ke-4)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _halaman[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: warnaTosca,
            unselectedItemColor: Colors.grey[400],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 28),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded, size: 28),
                label: 'Favorit',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle, size: 48),
                label: 'Buat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded, size: 28),
                label: 'Daftar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded, size: 28),
                label: 'Akun',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
