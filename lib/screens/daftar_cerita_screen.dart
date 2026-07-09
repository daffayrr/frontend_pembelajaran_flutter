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
  bool isGridMode = true;
  final List<String> listFilter = ['Semua', 'Ebook', 'Video', 'Cerita Pilihan'];
  late String filterAktif;

  @override
  void initState() {
    super.initState();
    filterAktif = widget.initialFilter;
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
      if (filterAktif == 'Semua') {
        materiTampil = List.from(semuaMateri);
      } else if (filterAktif == 'Ebook') {
        materiTampil = semuaMateri.where((m) => m['tipe'] == 'pdf').toList();
      } else if (filterAktif == 'Video') {
        materiTampil = semuaMateri
            .where((m) => m['tipe'] == 'video' || m['tipe'] == 'mp4')
            .toList();
      } else if (filterAktif == 'Cerita Pilihan') {
        materiTampil = semuaMateri.where((m) => m['tipe'] == 'cerita').toList();
      }
    });
  }

  void _ubahFilter(String filterBaru) {
    setState(() => filterAktif = filterBaru);
    _terapkanFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Jelajahi Materi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isGridMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: warnaTosca,
            ),
            onPressed: () => setState(() => isGridMode = !isGridMode),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 10, top: 5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: listFilter.length,
              itemBuilder: (context, index) {
                final filter = listFilter[index];
                final isSelected = filterAktif == filter;
                return GestureDetector(
                  onTap: () => _ubahFilter(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? warnaTosca : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: warnaTosca.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
                    child: isGridMode
                        ? GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 100,
                              top: 10,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: materiTampil.length,
                            itemBuilder: (context, index) =>
                                _buildGridCard(materiTampil[index]),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 100,
                              top: 10,
                            ),
                            itemCount: materiTampil.length,
                            itemBuilder: (context, index) =>
                                _buildListCard(materiTampil[index]),
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
    IconData cardIcon = isPdf
        ? Icons.menu_book_rounded
        : (isCerita ? Icons.article_rounded : Icons.play_circle_fill_rounded);
    Color iconColor = isPdf
        ? Colors.blue[300]!
        : (isCerita ? Colors.orange[300]! : Colors.purple[300]!);
    Color bgColor = isPdf
        ? Colors.blue[50]!
        : (isCerita ? Colors.orange[50]! : Colors.purple[50]!);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMateriScreen(materi: materi),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: materi['url_sampul'] != null
                    ? CachedNetworkImage(
                        imageUrl: materi['url_sampul'],
                        cacheKey:
                            materi['id'].toString() +
                            '_sampul', // 🚀 FIX: Mengunci Cache
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
                        color: bgColor,
                        width: double.infinity,
                        child: Icon(cardIcon, size: 50, color: iconColor),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPdf
                        ? 'E-Book PDF'
                        : (isCerita ? 'Cerita Pilihan' : 'Video'),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
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

  Widget _buildListCard(dynamic materi) {
    final isPdf = materi['tipe'] == 'pdf';
    final isCerita = materi['tipe'] == 'cerita';
    IconData cardIcon = isPdf
        ? Icons.menu_book_rounded
        : (isCerita ? Icons.article_rounded : Icons.play_circle_fill_rounded);
    Color iconColor = isPdf
        ? Colors.blue[300]!
        : (isCerita ? Colors.orange[300]! : Colors.purple[300]!);
    Color bgColor = isPdf
        ? Colors.blue[50]!
        : (isCerita ? Colors.orange[50]! : Colors.purple[50]!);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMateriScreen(materi: materi),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 100,
                height: 110,
                child: materi['url_sampul'] != null
                    ? CachedNetworkImage(
                        imageUrl: materi['url_sampul'],
                        cacheKey:
                            materi['id'].toString() +
                            '_sampul', // 🚀 FIX: Mengunci Cache
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
                        color: bgColor,
                        child: Icon(cardIcon, size: 40, color: iconColor),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      materi['judul'] ?? 'Tanpa Judul',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPdf
                            ? 'E-Book PDF'
                            : (isCerita ? 'Cerita Pilihan' : 'Video'),
                        style: TextStyle(
                          color: iconColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
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
          Icon(
            filterAktif == 'Cerita Pilihan'
                ? Icons.auto_awesome_rounded
                : Icons.search_off_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          Text(
            filterAktif == 'Cerita Pilihan'
                ? 'Cerita pilihan belum tersedia.'
                : 'Materi tidak ditemukan.',
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
