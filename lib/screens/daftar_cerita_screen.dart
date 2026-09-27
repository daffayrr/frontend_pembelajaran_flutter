import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_pembelajaran_flutter/screens/detail_materi_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class DaftarCeritaScreen extends StatefulWidget {
  final String initialFilter;
  const DaftarCeritaScreen({super.key, this.initialFilter = 'Semua'});

  @override
  State<DaftarCeritaScreen> createState() => _DaftarCeritaScreenState();
}

class _DaftarCeritaScreenState extends State<DaftarCeritaScreen> {
  List semuaMateri = [];
  List materiTampil = [];
  bool isLoading = true;
  String filterAktif = 'Semua';
  String searchQuery = '';
  final List<String> listFilter = ['Semua', 'Ebook', 'Video', 'Cerita Pilihan'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filterAktif = widget.initialFilter;
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
        _terapkanFilter();
      });
    });
    _muatDataLokal();
    _fetchMateriServer();
  }

  Future<void> _muatDataLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cacheData = prefs.getString('cache_materi_jelajah');

    if (cacheData != null) {
      final Map<String, dynamic> responseData = json.decode(cacheData);
      if (mounted) {
        setState(() {
          semuaMateri = responseData['data'] ?? [];
          _terapkanFilter();
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
        await prefs.setString('cache_materi_jelajah', response.body);

        final Map<String, dynamic> responseData = json.decode(response.body);
        if (mounted) {
          setState(() {
            semuaMateri = responseData['data'] ?? [];
            _terapkanFilter();
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

  void _terapkanFilter() {
    setState(() {
      List tempList = List.from(semuaMateri);

      if (filterAktif == 'Ebook')
        tempList = tempList.where((m) => m['tipe'] == 'pdf').toList();
      else if (filterAktif == 'Video')
        tempList = tempList
            .where((m) => m['tipe'] == 'video' || m['tipe'] == 'mp4')
            .toList();
      else if (filterAktif == 'Cerita Pilihan')
        tempList = tempList.where((m) => m['tipe'] == 'cerita').toList();

      if (searchQuery.isNotEmpty) {
        tempList = tempList.where((m) {
          final judul = m['judul']?.toString().toLowerCase() ?? '';
          return judul.contains(searchQuery);
        }).toList();
      }
      materiTampil = tempList;
    });
  }

  void _ubahFilter(String filterBaru) {
    setState(() => filterAktif = filterBaru);
    _terapkanFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Jelajahi Dongeng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari dongeng favoritmu...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: listFilter.length,
              itemBuilder: (context, index) {
                final filter = listFilter[index];
                final isSelected = filterAktif == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _ubahFilter(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? warnaTosca : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: warnaTosca),
                  )
                : materiTampil.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchMateriServer,
                    color: warnaTosca,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 100,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: materiTampil.length,
                      itemBuilder: (context, index) =>
                          _buildGridCard(materiTampil[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(dynamic materi) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            'Materi tidak ditemukan.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
