import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String judul;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.judul,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  bool _isReady = false; // Penanda untuk menyembunyikan/menampilkan PDF

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();

    // 1. Tunda render PDF sampai animasi masuk layar selesai (350 milidetik)
    // Ini mencegah lag saat pengguna baru mengeklik "Lanjut Baca"
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  // 2. Fungsi Anti-Freeze untuk keluar layar
  void _keluarAman() {
    if (_isReady) {
      // Sembunyikan PDF secara instan, ganti dengan layar loading
      setState(() => _isReady = false);
    }

    // Beri jeda 50 milidetik agar UI berubah bersih, baru lakukan Pop (Kembali)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. WillPopScope digunakan untuk menangkap aksi "Gesture Swipe Back" dari HP
    return WillPopScope(
      onWillPop: () async {
        _keluarAman(); // Jalankan fungsi keluar aman kita
        return false; // Batalkan aksi back bawaan HP agar tidak error
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text(
            widget.judul,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: warnaTosca,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _keluarAman, // Gunakan juga untuk tombol panah di AppBar
          ),
        ),
        body: !_isReady
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: warnaTosca),
                    SizedBox(height: 15),
                    Text(
                      'Membuka dokumen...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SfPdfViewer.file(
                File(widget.filePath),
                controller: _pdfViewerController,
                pageLayoutMode: PdfPageLayoutMode.single,
                scrollDirection: PdfScrollDirection.horizontal,
                enableDoubleTapZooming: true,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                enableDocumentLinkAnnotation: false,
                enableTextSelection: false,
                interactionMode: PdfInteractionMode.pan,
              ),
      ),
    );
  }
}
