import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/models.dart';

class LiveTvPage extends StatelessWidget {
  const LiveTvPage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final channels = catalog.liveChannels;
    final epg = catalog.epgData;

    if (channels.isEmpty) {
      return const Center(child: Text('Geen zenders gevonden.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final programs = epg[channel.id] ?? [];
        final currentProgram = programs.firstWhere(
          (p) => p.isNowPlaying,
          orElse: () => Program(
            id: '',
            title: 'Geen info',
            description: '',
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        return GestureDetector(
          onTap: () {
            final auth = context.read<AuthProvider>();
            final streamUrl = auth.credentials?.type == LoginType.xtream
                ? catalog.buildXtreamStreamUrl(
                    auth.credentials!,
                    streamId: channel.id,
                    type: 'live',
                  )
                : channel.streamUrl;

            if (streamUrl.isNotEmpty) {
              context.push('/player', extra: {
                'title': channel.name,
                'streamUrl': streamUrl,
              });
            }
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      channel.logo != null && channel.logo!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: channel.logo!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(),
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            channel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentProgram.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentProgram.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Icon(Icons.tv, color: Colors.grey, size: 48),
    );
  }
}
