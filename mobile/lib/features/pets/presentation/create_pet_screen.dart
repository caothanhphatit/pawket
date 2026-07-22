import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';
import 'package:pawket_mobile/features/feed/application/feed_providers.dart';
import 'package:pawket_mobile/features/media/data/media_dto.dart';
import 'package:pawket_mobile/features/pets/application/pet_providers.dart';
import 'package:pawket_mobile/features/pets/data/pet_dto.dart';
import 'package:pawket_mobile/features/pets/domain/pet.dart';
import 'package:pawket_mobile/features/posts/data/post_dto.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  const CreatePetScreen({this.mandatory = false, super.key});

  final bool mandatory;

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  static const maxPhotos = 5;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final imagePicker = ImagePicker();
  final selectedPhotos = <XFile>[];
  PetSpecies species = PetSpecies.dog;
  bool isSubmitting = false;
  String? submissionStatus;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.mandatory,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.mandatory,
          title: Text(widget.mandatory ? 'Your first pet' : 'Create a pet'),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (widget.mandatory) ...[
                Text(
                  'Before the first photo, give them a home in Pawket.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Name and species are enough. Photos are optional and can be added later.',
                  style: TextStyle(color: PawketColors.inkMuted, fontSize: 16),
                ),
                const SizedBox(height: 28),
              ],
              _PhotoPicker(
                photos: selectedPhotos,
                enabled: !isSubmitting,
                onPick: _pickPhotos,
                onRemove: (index) {
                  setState(() => selectedPhotos.removeAt(index));
                },
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Tell us your pet\'s name.'
                    : null,
              ),
              const SizedBox(height: 18),
              Text('Species *', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SegmentedButton<PetSpecies>(
                segments: const [
                  ButtonSegment(
                    value: PetSpecies.dog,
                    icon: Icon(Icons.pets),
                    label: Text('Dog'),
                  ),
                  ButtonSegment(
                    value: PetSpecies.cat,
                    icon: Icon(Icons.cruelty_free_outlined),
                    label: Text('Cat'),
                  ),
                ],
                selected: {species},
                onSelectionChanged: (selection) {
                  setState(() => species = selection.single);
                },
              ),
              const SizedBox(height: 20),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.edit_note_outlined,
                    size: 20,
                    color: PawketColors.inkMuted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Birthday, breed, home date and bio can be added later from Profile.',
                      style: TextStyle(color: PawketColors.inkMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: PawketColors.brand,
                ),
                child: isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(submissionStatus ?? 'Creating...'),
                          ),
                        ],
                      )
                    : const Text('Create profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    try {
      final photos = await imagePicker.pickMultiImage(
        imageQuality: 90,
        limit: maxPhotos - selectedPhotos.length,
      );
      if (!mounted || photos.isEmpty) return;
      setState(() {
        selectedPhotos.addAll(photos.take(maxPhotos - selectedPhotos.length));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open photo library: $error')),
      );
    }
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    if (widget.mandatory) {
      ref.read(petOnboardingCompletionProvider.notifier).setCompleting(true);
    }
    setState(() {
      isSubmitting = true;
      submissionStatus = 'Creating profile...';
    });
    try {
      final pet = await ref
          .read(petsProvider.notifier)
          .add(name: nameController.text.trim(), species: species);
      if (!mounted) return;
      ref.read(activePetIdProvider.notifier).select(pet.id);

      var failedPhotos = 0;
      final starterCapturedAt = DateTime.now();
      for (var index = 0; index < selectedPhotos.length; index++) {
        setState(() {
          submissionStatus =
              'Adding photo ${index + 1}/${selectedPhotos.length}';
        });
        try {
          final mediaId = await _createMemory(
            pet.id,
            selectedPhotos[index],
            starterCapturedAt.subtract(Duration(milliseconds: index)),
          );
          if (index == 0) {
            final updated = await ref
                .read(petRepositoryProvider)
                .updatePet(pet.id, UpdatePetRequest(avatarMediaId: mediaId));
            ref.read(petsProvider.notifier).replace(updated.toDomain());
          }
        } catch (_) {
          failedPhotos++;
        }
      }
      ref.invalidate(petFeedProvider(pet.id));
      ref.invalidate(petMemoriesProvider(pet.id));

      if (failedPhotos > 0) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile created'),
            content: Text(
              failedPhotos == selectedPhotos.length
                  ? 'Your pet profile is ready, but the photos could not be added. You can add memories later from the camera.'
                  : '${selectedPhotos.length - failedPhotos} of ${selectedPhotos.length} photos were added. $failedPhotos could not be uploaded; you can add them later from the camera.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View profile'),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      if (widget.mandatory) {
        ref.read(petOnboardingCompletionProvider.notifier).setCompleting(false);
      } else {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;
      if (widget.mandatory) {
        ref.read(petOnboardingCompletionProvider.notifier).setCompleting(false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create profile: $error')),
      );
      setState(() {
        isSubmitting = false;
        submissionStatus = null;
      });
    }
  }

  Future<String> _createMemory(
    String petId,
    XFile photo,
    DateTime capturedAt,
  ) async {
    final bytes = await photo.readAsBytes();
    final mimeType = _mimeType(photo.name);
    final mediaRepository = ref.read(mediaRepositoryProvider);
    final intent = await mediaRepository.createUploadIntent(
      CreateUploadIntentRequest(
        fileName: photo.name,
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
    );
    final completed = await mediaRepository.completeUpload(intent.mediaId);
    await ref
        .read(postRepositoryProvider)
        .createPost(
          CreatePostRequest(
            petIds: [petId],
            mediaIds: [completed.id],
            capturedAt: capturedAt,
          ),
          idempotencyKey: const Uuid().v4(),
        );
    return completed.id;
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
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final List<XFile> photos;
  final bool enabled;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: InkWell(
          onTap: enabled ? onPick : null,
          borderRadius: BorderRadius.circular(48),
          child: const CircleAvatar(
            radius: 48,
            backgroundColor: PawketColors.surfaceStrong,
            foregroundColor: PawketColors.ink,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined),
                SizedBox(height: 4),
                Text('Optional'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Profile photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text('${photos.length}/${_CreatePetScreenState.maxPhotos}'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount:
                photos.length +
                (photos.length < _CreatePetScreenState.maxPhotos ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == photos.length) {
                return _AddPhotoButton(enabled: enabled, onTap: onPick);
              }
              return _PhotoPreview(
                photo: photos[index],
                enabled: enabled,
                onRemove: () => onRemove(index),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add up to 5. Each photo becomes a first memory.',
          style: TextStyle(color: PawketColors.inkMuted),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 72,
        decoration: BoxDecoration(
          color: PawketColors.surfaceStrong,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.photo,
    required this.enabled,
    required this.onRemove,
  });

  final XFile photo;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FutureBuilder<Uint8List>(
                future: photo.readAsBytes(),
                builder: (context, snapshot) => snapshot.hasData
                    ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                    : const ColoredBox(
                        color: PawketColors.surfaceStrong,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: IconButton.filled(
              onPressed: enabled ? onRemove : null,
              tooltip: 'Remove photo',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
