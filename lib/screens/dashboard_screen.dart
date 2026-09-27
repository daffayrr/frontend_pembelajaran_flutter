import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_pembelajaran_flutter/screens/detail_materi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/bookmark_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/daftar_cerita_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';
import 'package:frontend_pembelajaran_flutter/screens/akun_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/quiz_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List semuaMateri = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  String namaUser = 'Tamu';
  int totalPoin = 0; // State untuk skor
  String filterAktif = 'Semua';
  final List<String> listFilter = ['Semua', 'E-Book', 'Video', 'Fabel'];

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
    final String? userIdStr = prefs.getString('user_id');

    setState(() {
      if (token != null) {
        isLoggedIn = true;
        namaUser = nama ?? 'Pengguna';
        // if user logged in, fetch score
        if (userIdStr != null && userIdStr.isNotEmpty) {
          _fetchUserScore(userIdStr);
        }
      } else {
        isLoggedIn = false;
        namaUser = 'Tamu';
      }
    });
  }

  Future<void> _fetchUserScore(String userIdStr) async {
    try {
      final response = await http.get(
        Uri.parse('$endpointQuizScore/$userIdStr'),
        headers: {
          'Authorization': staticAuthToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double parsedScore =
            double.tryParse(data['total_skor']?.toString() ?? '0') ?? 0.0;
        if (mounted) {
          setState(() {
            totalPoin = parsedScore.round();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch skor dashboard: $e');
    }
  }

  Future<void> _muatDataLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cacheData = prefs.getString('cache_materi_dashboard');

    if (cacheData != null) {
      final Map<String, dynamic> responseData = json.decode(cacheData);
      if (mounted) {
        setState(() {
          semuaMateri = responseData['data'] ?? [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMateriServer() async {
    if (semuaMateri.isEmpty) {
      if (mounted) setState(() => isLoading = true);
    }
    try {
      final response = await http.get(Uri.parse(endpointMateri));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_materi_dashboard', response.body);
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (mounted) {
          setState(() {
            semuaMateri = responseData['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted && semuaMateri.isEmpty) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted && semuaMateri.isEmpty) setState(() => isLoading = false);
    }
  }

  List get materiTampil {
    if (filterAktif == 'Semua') return semuaMateri;
    if (filterAktif == 'E-Book')
      return semuaMateri.where((m) => m['tipe'] == 'pdf').toList();
    if (filterAktif == 'Video')
      return semuaMateri
          .where((m) => m['tipe'] == 'video' || m['tipe'] == 'mp4')
          .toList();
    if (filterAktif == 'Fabel')
      return semuaMateri.where((m) => m['tipe'] == 'cerita').toList();
    return semuaMateri;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _checkLoginStatus();
            await _fetchMateriServer();
          },
          color: warnaTosca,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                _buildHeader(),
                const SizedBox(height: 25),
                _buildHeroBanner(),
                const SizedBox(height: 25),
                _buildStatsCards(),
                const SizedBox(height: 30),
                _buildExploreSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AkunScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: warnaTosca,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    namaUser,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIconButton(
                icon: Icons.search_rounded,
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: MateriSearchDelegate(semuaMateri: semuaMateri),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildHeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[200]?.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  // Hero Banner
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008B8B), Color(0xFF00B4C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: warnaTosca.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🌟 Spesial Hari Ini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Petualangan Baru\nMenunggu!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: warnaTosca,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Placeholder for illustration
          Opacity(
            opacity: 0.8,
            child: Icon(
              Icons.menu_book_rounded,
              size: 90,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // Menu & Statistik Cards
  Widget _buildStatsCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            title: 'Total Skor',
            value: totalPoin.toString(),
            subValue: ' pts',
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizScreen()),
            ),
          ),
          const SizedBox(width: 14),
          _buildStatCard(
            title: 'Buku Dongeng',
            value: 'E-Book',
            subValue: '',
            icon: Icons.menu_book_rounded,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const DaftarCeritaScreen(initialFilter: 'Ebook'),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _buildStatCard(
            title: 'Video',
            value: 'Tonton',
            subValue: '',
            icon: Icons.play_circle_fill_rounded,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const DaftarCeritaScreen(initialFilter: 'Video'),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _buildStatCard(
            title: 'Favorit',
            value: 'Koleksi',
            subValue: '',
            icon: Icons.bookmark_rounded,
            color: Colors.redAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarkScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subValue.isNotEmpty)
                  Text(
                    subValue,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Jelajahi Dongeng Section
  Widget _buildExploreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jelajahi Dongeng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarCeritaScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua >',
                  style: TextStyle(
                    color: warnaTosca,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: listFilter.map((filter) {
              final isSelected = filterAktif == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => filterAktif = filter);
                  },
                  selectedColor: warnaTosca,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? warnaTosca : Colors.grey[300]!,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: warnaTosca),
                ),
              )
            : materiTampil.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Belum ada materi.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: materiTampil.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio:
                        0.70, // Updated ratio for full background image
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCinematicGridCard(materiTampil[index]);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildCinematicGridCard(dynamic materi) {
    final isPdf = materi['tipe'] == 'pdf';
    final isCerita = materi['tipe'] == 'cerita';
    String kategoriLabel = isPdf ? 'Ebook' : (isCerita ? 'Fabel' : 'Video');
    Color badgeColor = isPdf
        ? Colors.blue
        : (isCerita ? Colors.orange : Colors.purple);
    IconData cardIcon = isPdf
        ? Icons.menu_book_rounded
        : (isCerita ? Icons.article_rounded : Icons.play_circle_fill_rounded);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMateriScreen(materi: materi),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            materi['url_sampul'] != null
                ? CachedNetworkImage(
                    imageUrl: materi['url_sampul'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(cardIcon, size: 40, color: badgeColor),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(cardIcon, size: 40, color: badgeColor),
                  ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),
            // Badges
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(cardIcon, size: 10, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      kategoriLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  size: 16,
                  color: warnaTosca,
                ),
              ),
            ),
            // Bottom Texts
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materi['judul'] ?? 'Tanpa Judul',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            materi['rating_rata_rata'] != null
                                ? materi['rating_rata_rata'].toString()
                                : '0.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            '5 mnt',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// DELEGATE PENCARIAN (SEARCH)
// =======================================================
class MateriSearchDelegate extends SearchDelegate {
  final List semuaMateri;
  MateriSearchDelegate({required this.semuaMateri});

  @override
  String get searchFieldLabel => 'Cari judul materi...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildHasilPencarian();

  @override
  Widget buildSuggestions(BuildContext context) => _buildHasilPencarian();

  Widget _buildHasilPencarian() {
    final hasil = semuaMateri.where((m) {
      final judul = m['judul'].toString().toLowerCase();
      return judul.contains(query.toLowerCase());
    }).toList();

    if (hasil.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text(
              'Tidak ada materi ditemukan.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: hasil.length,
      itemBuilder: (context, index) {
        final materi = hasil[index];
        final bool isPdf = materi['tipe'] == 'pdf';
        final bool isCerita = materi['tipe'] == 'cerita';

        IconData icon = isPdf
            ? Icons.menu_book_rounded
            : (isCerita
                  ? Icons.article_rounded
                  : Icons.play_circle_fill_rounded);
        Color bgColor = isPdf
            ? Colors.blue[50]!
            : (isCerita ? Colors.orange[50]! : Colors.purple[50]!);
        Color iconColor = isPdf
            ? Colors.blue[300]!
            : (isCerita ? Colors.orange[300]! : Colors.purple[300]!);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: materi['url_sampul'] != null
                    ? CachedNetworkImage(
                        imageUrl: materi['url_sampul'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[100]),
                      )
                    : Container(
                        color: bgColor,
                        child: Icon(icon, color: iconColor),
                      ),
              ),
            ),
            title: Text(
              materi['judul'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isPdf
                  ? 'E-Book PDF'
                  : (isCerita ? 'Cerita Komunitas' : 'Video Pembelajaran'),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailMateriScreen(materi: materi),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
