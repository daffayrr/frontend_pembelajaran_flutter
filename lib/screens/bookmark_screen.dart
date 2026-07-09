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
  bool isGridMode = false; // Default List
  String? userId;

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
        if (mounted)
          setState(() {
            listBookmark = data['data'];
            isLoading = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _hapusBookmarkAPI(int index) async {
    final deletedItem = listBookmark[index];
    setState(() => listBookmark.removeAt(index));
    try {
      final response = await http.delete(
        Uri.parse('$endpointFavorit/$userId/${deletedItem['id']}'),
      );
      if (response.statusCode == 200) {
        if (mounted)
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
      } else {
        _loadBookmarksAPI();
      }
    } catch (e) {
      _loadBookmarksAPI();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Materi Favorit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: warnaTosca))
          : (listBookmark.isEmpty || userId == null)
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadBookmarksAPI,
              color: warnaTosca,
              child: isGridMode
                  ? GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 120,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: listBookmark.length,
                      itemBuilder: (context, index) =>
                          _buildGridCard(listBookmark[index], index),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 120,
                      ),
                      itemCount: listBookmark.length,
                      itemBuilder: (context, index) =>
                          _buildListCard(listBookmark[index], index),
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
            Icons.bookmark_border_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          Text(
            userId == null
                ? 'Silakan login terlebih dahulu.'
                : 'Belum ada materi favorit.',
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

  // --- KARTU TAMPILAN LIST (DENGAN GESER HAPUS) ---
  Widget _buildListCard(dynamic materi, int index) {
    return Dismissible(
      key: Key(materi['id'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _hapusBookmarkAPI(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      child: _kartuKonten(materi, true),
    );
  }

  // --- KARTU TAMPILAN GRID (DENGAN TAHAN/LONG PRESS HAPUS) ---
  Widget _buildGridCard(dynamic materi, int index) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Favorit?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _hapusBookmarkAPI(index);
                },
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: _kartuKonten(materi, false),
    );
  }

  // --- WIDGET HELPER KONTEN KARTU ---
  Widget _kartuKonten(dynamic materi, bool isList) {
    final bool isPdf = materi['tipe'] == 'pdf';
    final bool isCerita = materi['tipe'] == 'cerita';
    Color iconColor = isPdf
        ? Colors.blue[300]!
        : (isCerita ? Colors.orange[300]! : Colors.purple[300]!);
    Color bgColor = isPdf
        ? Colors.blue[50]!
        : (isCerita ? Colors.orange[50]! : Colors.purple[50]!);
    IconData cardIcon = isPdf
        ? Icons.menu_book_rounded
        : (isCerita ? Icons.article_rounded : Icons.play_circle_fill_rounded);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMateriScreen(materi: materi),
          ),
        ).then((_) => _loadBookmarksAPI());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isList ? 15 : 0),
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
        child: isList
            ? Row(
                // TAMPILAN LIST
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: 110,
                      height: 120,
                      child: materi['url_sampul'] != null
                          ? CachedNetworkImage(
                              imageUrl: materi['url_sampul'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[100]),
                            )
                          : Container(
                              color: bgColor,
                              child: Icon(cardIcon, color: iconColor, size: 40),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            materi['judul'] ?? 'Tanpa Judul',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isPdf
                                ? 'E-Book PDF'
                                : (isCerita ? 'Cerita Pilihan' : 'Video'),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 18),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            : Column(
                // TAMPILAN GRID
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
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[100]),
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
}
