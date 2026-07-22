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
import 'package:pawket_mobile/features/pets/presentation/widgets/pet_avatar.dart';
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
  final captionController = TextEditingController();
  bool isPublishing = false;
  double uploadProgress = 0;
  String visibility = 'PET_MEMBERS';
  String? publishError;
  PreparedPhoto? _preparedPhoto;
  String? _completedMediaId;
  final _uploadIdempotencyKey = const Uuid().v4();
  final _postIdempotencyKey = const Uuid().v4();

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePet = ref.watch(activePetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New memory')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _MediaPreview(media: widget.draft?.media),
          const SizedBox(height: 24),
          if (activePet != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: PawketColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PawketColors.outline),
              ),
              child: Row(
                children: [
                  PetAvatar(pet: activePet),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SAVING TO',
                          style: TextStyle(
                            color: PawketColors.inkMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          activePet.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Tooltip(
                    message: 'Change the current pet from Profile',
                    child: Icon(Icons.lock_outline, size: 19),
                  ),
                ],
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
          if (publishError != null) ...[
            const SizedBox(height: 16),
            _PublishError(message: publishError!),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: activePet == null || widget.draft == null || isPublishing
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
                  : publishError == null
                  ? 'Publish memory'
                  : 'Retry publish',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    final draft = widget.draft;
    final activePet = ref.read(activePetProvider);
    if (draft == null || activePet == null) return;
    final media = draft.media;
    setState(() {
      isPublishing = true;
      uploadProgress = 0;
      publishError = null;
    });

    try {
      final prepared = _preparedPhoto ??=
          await PawketPhotoFilter.prepareForUpload(await media.readAsBytes());
      const mimeType = 'image/jpeg';
      final originalFileName = media.name.trim().isEmpty
          ? 'capture-${DateTime.now().millisecondsSinceEpoch}.jpg'
          : media.name;
      final fileName =
          '${originalFileName.replaceFirst(RegExp(r'\.[^.]+$'), '')}.jpg';
      var mediaId = _completedMediaId;
      if (mediaId == null) {
        final mediaRepository = ref.read(mediaRepositoryProvider);
        final intent = await mediaRepository.createUploadIntent(
          CreateUploadIntentRequest(
            fileName: fileName,
            mimeType: mimeType,
            byteSize: prepared.bytes.length,
            purpose: MediaPurpose.post,
            width: prepared.width,
            height: prepared.height,
          ),
          idempotencyKey: _uploadIdempotencyKey,
        );
        await mediaRepository.upload(
          intent: intent,
          bytesOrStream: prepared.bytes,
          contentType: mimeType,
          contentLength: prepared.bytes.length,
          onProgress: (sent, total) {
            if (!mounted || total <= 0) return;
            setState(() => uploadProgress = sent / total);
          },
        );
        final completed = await mediaRepository.completeUpload(intent.mediaId);
        mediaId = completed.id;
        _completedMediaId = mediaId;
      }
      await ref
          .read(postRepositoryProvider)
          .createPost(
            CreatePostRequest(
              petIds: [activePet.id],
              mediaIds: [mediaId],
              capturedAt: draft.capturedAt,
              caption: captionController.text,
              visibility: visibility,
            ),
            idempotencyKey: _postIdempotencyKey,
          );
      ref.invalidate(petFeedProvider(activePet.id));
      ref.invalidate(petMemoriesProvider(activePet.id));
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
        publishError = _errorText(error);
      });
    }
  }

  String _errorText(Object error) {
    if (error is ValidationException && error.errors.isNotEmpty) {
      return '${error.message} ${error.errors.map((item) => '${item.field}: ${item.message}').join('; ')}';
    }
    if (error is PhotoPreparationException) return error.message;
    if (error is ApiException) return error.message;
    return 'Please try again.';
  }
}

class _PublishError extends StatelessWidget {
  const _PublishError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PawketColors.danger.withValues(alpha: .08),
        border: Border.all(color: PawketColors.danger),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: PawketColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$message Your photo and form are still here. Tap Retry publish.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.media});

  final XFile? media;

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
                  return PawketPhotoFilter.applyTo(
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
