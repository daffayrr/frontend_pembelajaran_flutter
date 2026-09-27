import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';
import 'package:frontend_pembelajaran_flutter/screens/detail_materi_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<dynamic> listBookmark = [];
  bool isLoading = true;
  String? userId;
  String filterAktif = 'Semua';
  final List<String> listFilter = ['Semua', 'Ebook', 'Video', 'Cerita Pilihan'];

  @override
  void initState() {
    super.initState();
    _loadBookmarksAPI();
  }

  Future<void> _loadBookmarksAPI() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final response = await http.get(Uri.parse('$endpointFavorit/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            listBookmark = data['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _konfirmasiHapus(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Favorit?'),
        content: const Text(
          'Apakah kamu yakin ingin menghapus dongeng ini dari koleksi favoritmu?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hapusBookmarkAPI(index);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusBookmarkAPI(int index) async {
    final itemToRemove = _getFilteredList()[index];
    final realIndex = listBookmark.indexWhere(
      (element) => element['id'] == itemToRemove['id'],
    );

    if (realIndex != -1) {
      setState(() => listBookmark.removeAt(realIndex));
      try {
        final response = await http.delete(
          Uri.parse('$endpointFavorit/$userId/${itemToRemove['id']}'),
        );
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Materi dihapus dari favorit'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          _loadBookmarksAPI();
        }
      } catch (e) {
        _loadBookmarksAPI();
      }
    }
  }

  List<dynamic> _getFilteredList() {
    List<dynamic> tempList = List.from(listBookmark);
    if (filterAktif == 'Ebook') {
      tempList = tempList.where((m) => m['tipe'] == 'pdf').toList();
    } else if (filterAktif == 'Video') {
      tempList = tempList
          .where((m) => m['tipe'] == 'video' || m['tipe'] == 'mp4')
          .toList();
    } else if (filterAktif == 'Cerita Pilihan') {
      tempList = tempList.where((m) => m['tipe'] == 'cerita').toList();
    }
    return tempList;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Koleksi Favorit',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Dongeng yang sudah kamu simpan',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.black87),
                onPressed: () {},
              ),

              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 50,
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
                    onTap: () {
                      setState(() => filterAktif = filter);
                    },
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
          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: warnaTosca),
                  )
                : filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 100,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildListItem(filteredList[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(dynamic materi, int index) {
    final isPdf = materi['tipe'] == 'pdf';
    final isCerita = materi['tipe'] == 'cerita';
    String kategoriLabel = isPdf ? 'Ebook' : (isCerita ? 'Fabel' : 'Video');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMateriScreen(materi: materi),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            // Kiri: Gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    materi['url_sampul'] != null
                        ? CachedNetworkImage(
                            imageUrl: materi['url_sampul'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: warnaTosca.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          kategoriLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tengah: Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materi['judul'] ?? 'Tanpa Judul',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kategoriLabel == 'Fabel'
                        ? 'Fabel Nusantara'
                        : 'Materi Belajar',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        materi['rating_rata_rata'] != null
                            ? materi['rating_rata_rata'].toString()
                            : '0.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.grey[400],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '5 mnt',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Kanan: Aksi (Delete)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[400]),
              onPressed: () => _konfirmasiHapus(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: warnaTosca.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: warnaTosca.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: warnaTosca,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum ada dongeng favorit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai jelajahi dan simpan dongeng yang kamu suka!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke tab sebelumnya/dashboard
                },
                icon: const Icon(
                  Icons.explore_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Jelajahi Dongeng',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnaTosca,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
