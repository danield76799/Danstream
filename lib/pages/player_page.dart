import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/catalog_provider.dart';
import '../models/models.dart';

class PlayerPage extends StatefulWidget {
  final String title;
  final String streamUrl;

  const PlayerPage({
    super.key,
    required this.title,
    required this.streamUrl,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;
  bool _showEpg = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.streamUrl),
      );
      await controller.initialize();
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        aspectRatio: controller.value.aspectRatio,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
      );
      if (mounted) {
        setState(() {
          _videoController = controller;
          _chewieController = chewie;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Stream kon niet worden afgespeeld: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    // Find channel by title to get EPG
    final channel = catalog.liveChannels.firstWhere(
      (c) => c.name == widget.title,
      orElse: () => Channel(id: '', name: '', groupTitle: '', streamUrl: ''),
    );
    final programs = catalog.epgData[channel.id] ?? [];
    final currentProgram = programs.firstWhere(
      (p) => p.isNowPlaying,
      orElse: () => Program(
        id: '',
        title: 'Geen programmainformatie',
        description: '',
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_showEpg ? Icons.info_outline : Icons.info),
            onPressed: () => setState(() => _showEpg = !_showEpg),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
              child: _loading
                  ? const CircularProgressIndicator()
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Chewie(controller: _chewieController!),
            ),
          ),
          if (_showEpg)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentProgram.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentProgram.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Tot ${currentProgram.end.hour}:${currentProgram.end.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
