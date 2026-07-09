import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;
  final String judul;

  const VideoPlayerScreen({
    super.key,
    required this.filePath,
    required this.judul,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Memuat video dari penyimpanan lokal HP (hasil unduhan)
      _videoPlayerController = VideoPlayerController.file(
        File(widget.filePath),
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true, // Otomatis main saat layar dibuka
        looping: false,
        aspectRatio: _videoPlayerController
            .value
            .aspectRatio, // Sesuaikan dengan rasio asli video
        materialProgressColors: ChewieProgressColors(
          playedColor: warnaTosca,
          handleColor: warnaTosca,
          backgroundColor: Colors.grey.withOpacity(0.5),
          bufferedColor: Colors.white,
        ),
        placeholder: const Center(
          child: CircularProgressIndicator(color: warnaTosca),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Gagal memuat video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      // Update UI setelah video siap
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _isError = true);
        print("Error initializing video: $e");
      }
    }
  }

  @override
  void dispose() {
    // WAJIB DIBERSIHKAN agar tidak terjadi kebocoran memori (memory leak)
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background gelap ala bioskop
      appBar: AppBar(
        title: Text(
          widget.judul,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: _isError
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white54,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Maaf, format video tidak didukung atau file rusak.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: warnaTosca),
                    SizedBox(height: 15),
                    Text(
                      'Menyiapkan pemutar video...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
