import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../app/theme/pawket_theme.dart';
import '../../feed/application/feed_providers.dart';
import '../../media/data/media_dto.dart';
import '../../pets/application/pet_providers.dart';
import '../../posts/data/post_dto.dart';
import '../../posts/domain/photo_filter.dart';

class ImportMemoriesScreen extends ConsumerStatefulWidget {
  const ImportMemoriesScreen({super.key});

  @override
  ConsumerState<ImportMemoriesScreen> createState() =>
      _ImportMemoriesScreenState();
}

class _ImportMemoriesScreenState extends ConsumerState<ImportMemoriesScreen> {
  final picker = ImagePicker();
  final photos = <XFile>[];
  DateTime capturedOn = DateTime.now();
  bool importing = false;
  int completed = 0;

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(activePetProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add old memories')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Text(
            pet == null ? 'Choose a pet first' : 'Add to ${pet.name}\'s story',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'This import lives in Profile, so the camera stays focused on taking today’s photo.',
            style: TextStyle(color: PawketColors.inkMuted),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: importing ? null : _pickPhotos,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(photos.isEmpty ? 'Choose photos' : 'Choose more'),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _ImportThumbnail(
                  photo: photos[index],
                  onRemove: importing
                      ? null
                      : () => setState(() => photos.removeAt(index)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              enabled: !importing,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Captured on'),
              subtitle: const Text('Applied to this batch'),
              trailing: Text(
                _date(capturedOn),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: pet == null || photos.isEmpty || importing
                ? null
                : () => _import(pet.id),
            icon: importing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.archive_outlined),
            label: Text(
              importing
                  ? 'Adding ${completed + 1}/${photos.length}'
                  : 'Add ${photos.length} ${photos.length == 1 ? 'memory' : 'memories'}',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final selected = await picker.pickMultiImage(
      limit: 10 - photos.length,
      imageQuality: 100,
    );
    if (!mounted || selected.isEmpty) return;
    setState(() => photos.addAll(selected.take(10 - photos.length)));
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: capturedOn,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => capturedOn = selected);
  }

  Future<void> _import(String petId) async {
    setState(() {
      importing = true;
      completed = 0;
    });
    try {
      for (var index = 0; index < photos.length; index++) {
        final photo = photos[index];
        final prepared = await PawketPhotoFilter.prepareForUpload(
          await photo.readAsBytes(),
        );
        final mediaRepository = ref.read(mediaRepositoryProvider);
        final intent = await mediaRepository.createUploadIntent(
          CreateUploadIntentRequest(
            fileName: 'import-${const Uuid().v4()}.jpg',
            mimeType: 'image/jpeg',
            byteSize: prepared.bytes.length,
            purpose: MediaPurpose.post,
            width: prepared.width,
            height: prepared.height,
          ),
          idempotencyKey: const Uuid().v4(),
        );
        await mediaRepository.upload(
          intent: intent,
          bytesOrStream: prepared.bytes,
          contentType: 'image/jpeg',
          contentLength: prepared.bytes.length,
        );
        final completedMedia = await mediaRepository.completeUpload(
          intent.mediaId,
        );
        await ref
            .read(postRepositoryProvider)
            .createPost(
              CreatePostRequest(
                petIds: [petId],
                mediaIds: [completedMedia.id],
                capturedAt: capturedOn.add(
                  Duration(microseconds: photos.length - index),
                ),
              ),
              idempotencyKey: const Uuid().v4(),
            );
        if (mounted) setState(() => completed = index + 1);
      }
      ref.invalidate(petFeedProvider(petId));
      ref.invalidate(petMemoriesProvider(petId));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        if (completed > 0) photos.removeRange(0, completed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$completed photos were added. Try the remaining ${photos.length} again.',
            ),
          ),
        );
        setState(() => importing = false);
      }
    }
  }
}

class _ImportThumbnail extends StatelessWidget {
  const _ImportThumbnail({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FutureBuilder<Uint8List>(
                future: photo.readAsBytes(),
                builder: (_, snapshot) => snapshot.hasData
                    ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                    : const ColoredBox(color: PawketColors.surfaceStrong),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              right: 3,
              top: 3,
              child: IconButton.filled(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 15),
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

String _date(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year}';
}
