import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';
import 'package:pawket_mobile/features/feed/application/feed_providers.dart';
import 'package:pawket_mobile/core/network/api_exception.dart';
import 'package:pawket_mobile/features/media/data/media_dto.dart';
import 'package:pawket_mobile/features/pets/application/pet_providers.dart';
import 'package:pawket_mobile/features/posts/data/post_dto.dart';
import 'package:pawket_mobile/features/posts/domain/photo_filter.dart';
import 'package:pawket_mobile/features/posts/presentation/capture_draft.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({this.draft, super.key});

  final CaptureDraft? draft;

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  late final Set<String> selectedPetIds;
  final captionController = TextEditingController();
  bool isPublishing = false;
  double uploadProgress = 0;
  bool didInitializePetSelection = false;
  String visibility = 'PET_MEMBERS';

  @override
  void initState() {
    super.initState();
    final activeId = ref.read(activePetIdProvider);
    selectedPetIds = {?activeId};
    didInitializePetSelection = activeId != null;
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider);
    final activeId = ref.watch(activePetIdProvider);
    if (!didInitializePetSelection &&
        activeId != null &&
        pets.any((pet) => pet.id == activeId)) {
      selectedPetIds.add(activeId);
      didInitializePetSelection = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New memory')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _MediaPreview(
            media: widget.draft?.media,
            filter: widget.draft?.filter ?? PhotoFilter.original,
          ),
          const SizedBox(height: 24),
          Text(
            'Who is here? *',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pet in pets)
                FilterChip(
                  label: Text(pet.name),
                  selected: selectedPetIds.contains(pet.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedPetIds.add(pet.id);
                      } else {
                        selectedPetIds.remove(pet.id);
                      }
                    });
                  },
                ),
            ],
          ),
          if (pets.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Create a pet profile before publishing a memory.',
                style: TextStyle(color: PawketColors.inkMuted),
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: captionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Caption (optional)',
              hintText: 'What happened today?',
            ),
          ),
          const SizedBox(height: 20),
          Text('Audience', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'PET_MEMBERS',
                icon: Icon(Icons.people_outline),
                label: Text('Pet members'),
              ),
              ButtonSegment(
                value: 'PRIVATE',
                icon: Icon(Icons.lock_outline),
                label: Text('Only me'),
              ),
            ],
            selected: {visibility},
            onSelectionChanged: isPublishing
                ? null
                : (selection) {
                    setState(() => visibility = selection.single);
                  },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed:
                selectedPetIds.isEmpty || widget.draft == null || isPublishing
                ? null
                : _publish,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: PawketColors.brand,
            ),
            icon: isPublishing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_upward),
            label: Text(
              isPublishing
                  ? 'Publishing ${(uploadProgress * 100).round()}%'
                  : 'Publish memory',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    final draft = widget.draft;
    if (draft == null || selectedPetIds.isEmpty) return;
    final media = draft.media;
    setState(() {
      isPublishing = true;
      uploadProgress = 0;
    });

    try {
      final originalBytes = Uint8List.fromList(await media.readAsBytes());
      final bytes = await draft.filter.applyToBytes(originalBytes);
      final mimeType = draft.filter.changesImage
          ? 'image/png'
          : _mimeType(media.name);
      final originalFileName = media.name.trim().isEmpty
          ? 'capture-${DateTime.now().millisecondsSinceEpoch}.jpg'
          : media.name;
      final fileName = draft.filter.changesImage
          ? '${originalFileName.replaceFirst(RegExp(r'\.[^.]+$'), '')}.png'
          : originalFileName;
      final mediaRepository = ref.read(mediaRepositoryProvider);
      final intent = await mediaRepository.createUploadIntent(
        CreateUploadIntentRequest(
          fileName: fileName,
          mimeType: mimeType,
          byteSize: bytes.length,
          purpose: MediaPurpose.post,
        ),
        idempotencyKey: const Uuid().v4(),
      );
      await mediaRepository.upload(
        intent: intent,
        bytesOrStream: bytes,
        contentType: mimeType,
        contentLength: bytes.length,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => uploadProgress = sent / total);
        },
      );
      final completed = await mediaRepository.completeUpload(intent.mediaId);
      await ref
          .read(postRepositoryProvider)
          .createPost(
            CreatePostRequest(
              petIds: selectedPetIds.toList(growable: false),
              mediaIds: [completed.id],
              capturedAt: draft.capturedAt,
              caption: captionController.text,
              visibility: visibility,
            ),
            idempotencyKey: const Uuid().v4(),
          );
      for (final petId in selectedPetIds) {
        ref.invalidate(petFeedProvider(petId));
        ref.invalidate(petMemoriesProvider(petId));
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not publish memory: ${_errorText(error)}'),
        ),
      );
      setState(() {
        isPublishing = false;
        uploadProgress = 0;
      });
    }
  }

  String _mimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  String _errorText(Object error) {
    if (error is ValidationException && error.errors.isNotEmpty) {
      return '${error.message} ${error.errors.map((item) => '${item.field}: ${item.message}').join('; ')}';
    }
    if (error is ApiException) return error.message;
    return 'Please try again.';
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.media, required this.filter});

  final XFile? media;
  final PhotoFilter filter;

  @override
  Widget build(BuildContext context) {
    final selectedMedia = media;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: selectedMedia == null
            ? const ColoredBox(
                color: PawketColors.surfaceStrong,
                child: Center(
                  child: Icon(Icons.add_a_photo_outlined, size: 64),
                ),
              )
            : FutureBuilder<List<int>>(
                future: selectedMedia.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return filter.applyTo(
                    Image.memory(
                      Uint8List.fromList(snapshot.data!),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
