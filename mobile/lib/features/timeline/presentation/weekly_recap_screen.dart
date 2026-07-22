import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../feed/application/feed_providers.dart';
import '../../pets/application/pet_providers.dart';
import '../../posts/data/post_dto.dart';

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  const WeeklyRecapScreen({super.key});

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen> {
  final recapKey = GlobalKey();
  bool sharing = false;

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(activePetProvider);
    final memories = pet == null
        ? null
        : ref.watch(petMemoriesProvider(pet.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly recap')),
      body: pet == null
          ? const Center(child: Text('Choose a pet from Profile.'))
          : memories!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Could not load this recap.')),
              data: (page) {
                final cutoff = DateTime.now().subtract(const Duration(days: 7));
                final posts = page.items
                    .where((post) => post.capturedAt.toLocal().isAfter(cutoff))
                    .take(6)
                    .toList(growable: false);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Text(
                      'Seven days with ${pet.name}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      posts.isEmpty
                          ? 'Capture a few moments to make the first recap.'
                          : '${posts.length} ${posts.length == 1 ? 'moment' : 'moments'} kept this week.',
                      style: const TextStyle(color: PawketColors.inkMuted),
                    ),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      key: recapKey,
                      child: _RecapCard(petName: pet.name, posts: posts),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: posts.isEmpty || sharing
                          ? null
                          : () => _share(pet.name),
                      icon: sharing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.ios_share_outlined),
                      label: Text(
                        sharing ? 'Preparing recap...' : 'Share recap',
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _share(String petName) async {
    setState(() => sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          recapKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Could not render recap.');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/pawket-weekly-recap.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      final box = context.findRenderObject()! as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          text: 'Seven days with $petName, kept in Pawket.',
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare the recap.')),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({required this.petName, required this.posts});

  final String petName;
  final List<PostDto> posts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: PawketColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAWKET WEEKLY',
            style: TextStyle(
              color: PawketColors.brand,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(petName, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          if (posts.isEmpty)
            const AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(
                color: PawketColors.surfaceStrong,
                child: Center(child: Icon(Icons.pets, size: 64)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemBuilder: (_, index) {
                final media = posts[index].media.firstOrNull;
                return media == null
                    ? const ColoredBox(
                        color: PawketColors.surfaceStrong,
                        child: Icon(Icons.pets),
                      )
                    : Image.network(
                        (media.thumbnailUrl ?? media.url).toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: PawketColors.surfaceStrong,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      );
              },
            ),
          const SizedBox(height: 14),
          Text(
            '${posts.length} ${posts.length == 1 ? 'moment' : 'moments'} · ${_weekLabel()}',
            style: const TextStyle(color: PawketColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

String _weekLabel() {
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 6));
  return '${start.day}/${start.month} – ${end.day}/${end.month}';
}
