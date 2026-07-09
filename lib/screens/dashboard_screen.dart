import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_pembelajaran_flutter/screens/detail_materi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/bookmark_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/main_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/daftar_cerita_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/notifikasi_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List listBuku = [];
  List listVideo = [];
  List listCerita = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  String namaUser = 'Tamu';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _muatDataLokal();
    _fetchMateriServer();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final nama = prefs.getString('user_name');
    setState(() {
      if (token != null) {
        isLoggedIn = true;
        namaUser = nama ?? 'Pengguna';
      } else {
        isLoggedIn = false;
        namaUser = 'Tamu';
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _muatDataLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cacheData = prefs.getString('cache_materi_dashboard');

    if (cacheData != null) {
      final Map<String, dynamic> responseData = json.decode(cacheData);
      final List semuaMateri = responseData['data'] ?? [];
      if (mounted) {
        setState(() {
          listBuku = semuaMateri.where((m) => m['tipe'] == 'pdf').toList();
          listVideo = semuaMateri
              .where((m) => m['tipe'] == 'video' || m['tipe'] == 'mp4')
              .toList();
          listCerita = semuaMateri.where((m) => m['tipe'] == 'cerita').toList();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMateriServer() async {
    if (listBuku.isEmpty && listVideo.isEmpty && listCerita.isEmpty) {
      if (mounted) setState(() => isLoading = true);
    }

    try {
      final response = await http.get(Uri.parse(endpointMateri));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_materi_dashboard', response.body);

        final Map<String, dynamic> responseData = json.decode(response.body);
        final List semuaMateri = responseData['data'] ?? [];
        if (mounted) {
          setState(() {
            listBuku = semuaMateri.where((m) => m['tipe'] == 'pdf').toList();
            listVideo = semuaMateri
                .where((m) => m['tipe'] == 'video' || m['tipe'] == 'mp4')
                .toList();
            listCerita = semuaMateri
                .where((m) => m['tipe'] == 'cerita')
                .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted && listBuku.isEmpty) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted && listBuku.isEmpty) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _fetchMateriServer,
        color: warnaTosca,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurvedHeader(),
              const SizedBox(height: 15),
              _buildSectionTitle('Trends (Buku Digital)', 'View all', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DaftarCeritaScreen(initialFilter: 'Ebook'),
                  ),
                );
              }),
              SizedBox(
                height: 230,
                child: isLoading
                    ? _buildLoadingCard()
                    : listBuku.isEmpty
                    ? _buildEmptyState('Belum ada buku tersedia')
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: listBuku.length,
                        itemBuilder: (context, index) =>
                            _buildBukuCard(listBuku[index]),
                      ),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle('Video Pembelajaran', 'View all', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DaftarCeritaScreen(initialFilter: 'Video'),
                  ),
                );
              }),
              SizedBox(
                height: 170,
                child: isLoading
                    ? _buildLoadingCard()
                    : listVideo.isEmpty
                    ? _buildEmptyState('Belum ada video tersedia')
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: listVideo.length,
                        itemBuilder: (context, index) =>
                            _buildVideoCard(listVideo[index]),
                      ),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle('Cerita Komunitas', 'View all', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DaftarCeritaScreen(
                      initialFilter: 'Cerita Pilihan',
                    ),
                  ),
                );
              }),
              SizedBox(
                height: 140,
                child: isLoading
                    ? _buildLoadingCard()
                    : listCerita.isEmpty
                    ? _buildEmptyState('Belum ada cerita')
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: listCerita.length,
                        itemBuilder: (context, index) =>
                            _buildCeritaCard(listCerita[index], index),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedHeader() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(25, 60, 25, 80),
          decoration: const BoxDecoration(
            color: warnaTosca,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.elliptical(200, 40),
              bottomRight: Radius.elliptical(200, 40),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Hi, $namaUser',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotifikasiScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              const Text(
                'Temukan Materi\nFavoritmu Di Sini!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Cari judul atau topik...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.mic_none_rounded, color: warnaTosca),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 3 Tombol Pintasan Overlap
        Positioned(
          bottom: -40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShortcutButton(
                icon: Icons.favorite_border_rounded,
                label: 'Favorit',
                color: Colors.orange,
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookmarkScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
              const SizedBox(width: 15),
              _buildShortcutButton(
                icon: Icons.menu_book_rounded,
                label: 'Daftar',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarCeritaScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 15),
              _buildShortcutButton(
                icon: isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                label: isLoggedIn ? 'Keluar' : 'Masuk',
                color: Colors.orange,
                onTap: () {
                  if (isLoggedIn) {
                    _logout(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBukuCard(dynamic materi) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMateriScreen(materi: materi),
        ),
      ),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 18, bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: materi['url_sampul'] != null
                    ? CachedNetworkImage(
                        imageUrl: materi['url_sampul'],
                        cacheKey: materi['id'].toString() + '_sampul',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[100]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.blue[50],
                        width: double.infinity,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: Colors.blueAccent,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materi['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'E-Book PDF',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
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

  Widget _buildVideoCard(dynamic materi) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMateriScreen(materi: materi),
        ),
      ),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 18, bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: materi['url_sampul'] != null
                        ? CachedNetworkImage(
                            imageUrl: materi['url_sampul'],
                            cacheKey: materi['id'].toString() + '_sampul',
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[100]),
                          )
                        : Container(
                            color: Colors.purple[50],
                            child: const Icon(
                              Icons.video_library_rounded,
                              size: 40,
                              color: Colors.purpleAccent,
                            ),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                materi['judul'] ?? 'Tanpa Judul',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCeritaCard(dynamic materi, int index) {
    final List<Color> pastelColors = [
      const Color(0xFFFFB7B2),
      const Color(0xFFFFDAC1),
      const Color(0xFFE2F0CB),
      const Color(0xFFB5EAD7),
      const Color(0xFFC7CEEA),
    ];
    final color = pastelColors[index % pastelColors.length];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMateriScreen(materi: materi),
        ),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.article_rounded,
                size: 20,
                color: Colors.black54,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  materi['judul'] ?? 'Cerita Pilihan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Cerita Komunitas',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(color: warnaTosca, strokeWidth: 3),
      ),
    );
  }
}
