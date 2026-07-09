import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/screens/main_screen.dart';

// Tambahkan 5 import ini di bagian atas file
import 'package:frontend_pembelajaran_flutter/screens/edit_profil_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/notifikasi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/keamanan_sandi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/bantuan_faq_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/tentang_aplikasi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/admin_materi_screen.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  bool isLoggedIn = false;
  String namaUser = 'Tamu';
  String roleUser = 'Pengunjung';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Cek apakah pengguna sudah login atau masih tamu
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final nama = prefs.getString('user_name');
    final role = prefs.getString('user_role');

    setState(() {
      if (token != null) {
        isLoggedIn = true;
        namaUser = nama ?? 'Pengguna';
        roleUser = role ?? 'Member';
      } else {
        isLoggedIn = false;
        namaUser = 'Tamu';
        roleUser = 'Pengunjung';
      }
    });
  }

  // Fungsi Logout dengan Dialog Konfirmasi
  Future<void> _logout(BuildContext context) async {
    // Jika di akun_screen, pastikan ada logika dialog konfirmasinya ya
    final prefs = await SharedPreferences.getInstance();

    // HANYA hapus sesi akun, biarkan bookmark tetap aman!
    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');

    if (context.mounted) {
      // Kembali ke MainScreen (bukan LoginScreen) agar masuk mode Tamu
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    }
  }

  // Fungsi peringatan jika tamu mencoba klik menu khusus member
  void _promptLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Silakan login terlebih dahulu untuk mengakses menu ini.',
        ),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu terang
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // --- HEADER PROFIL ---
            _buildProfileHeader(),

            const SizedBox(height: 25),

            // --- DAFTAR MENU ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuTile(
                    Icons.person_outline_rounded,
                    'Edit Profil',
                    isLoggedIn
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilScreen(),
                            ),
                          )
                        : _promptLogin,
                  ),
                  _buildMenuTile(
                    Icons.notifications_none_rounded,
                    'Notifikasi',
                    isLoggedIn
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotifikasiScreen(),
                            ),
                          )
                        : _promptLogin,
                  ),
                  _buildMenuTile(
                    Icons.security_rounded,
                    'Keamanan & Sandi',
                    isLoggedIn
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KeamananSandiScreen(),
                            ),
                          )
                        : _promptLogin,
                  ),

                  // --- TAMBAHKAN KODE INI UNTUK MENU ADMIN ---
                  if (roleUser.toLowerCase() == 'admin') ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withOpacity(0.5))),
                      child: _buildMenuTile(
                        Icons.admin_panel_settings_rounded,
                        'Kelola Materi (Panel Admin)',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMateriScreen())),
                      ),
                    ),
                  ],
                  // -------------------------------------------

                  const SizedBox(height: 10),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 10),

                  _buildMenuTile(
                    Icons.help_outline_rounded,
                    'Bantuan & FAQ',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BantuanFaqScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    Icons.info_outline_rounded,
                    'Tentang Aplikasi',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TentangAplikasiScreen(),
                        ),
                      );
                    },
                  ),

                  // --- TOMBOL LOGOUT / LOGIN ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoggedIn
                          ? () => _logout(context)
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLoggedIn
                            ? Colors.red[50]
                            : warnaTosca.withOpacity(0.1),
                        foregroundColor: isLoggedIn ? Colors.red : warnaTosca,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isLoggedIn
                                ? Colors.red.shade200
                                : warnaTosca.withOpacity(0.5),
                          ),
                        ),
                      ),
                      child: Text(
                        isLoggedIn ? 'KELUAR AKUN' : 'MASUK / DAFTAR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desain Header Atas
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 80, bottom: 40),
      decoration: const BoxDecoration(
        color: warnaTosca,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x400CE2CD),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: warnaTosca),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            namaUser,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleUser.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desain Kartu Menu
  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: warnaTosca.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: warnaTosca),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
