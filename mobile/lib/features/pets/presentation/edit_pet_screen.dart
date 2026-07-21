import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../app/theme/pawket_theme.dart';
import '../../../core/network/api_exception.dart';
import '../application/pet_providers.dart';
import '../data/pet_dto.dart';

class EditPetScreen extends ConsumerStatefulWidget {
  const EditPetScreen({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends ConsumerState<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _breedController = TextEditingController();
  final _genderController = TextEditingController();
  final _adoptionDateController = TextEditingController();
  final _bioController = TextEditingController();

  PetDto? _initialPet;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _breedController.dispose();
    _genderController.dispose();
    _adoptionDateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(petDetailsProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _submitting || _initialPet == null ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          onRetry: () => ref.invalidate(petDetailsProvider(widget.petId)),
        ),
        data: (pet) {
          if (pet == null) {
            return _LoadError(
              onRetry: () => ref.invalidate(petDetailsProvider(widget.petId)),
            );
          }
          _initialize(pet);
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Field notes', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          const Text(
            'Keep the small details that make this profile feel like home.',
            style: TextStyle(color: PawketColors.inkMuted, height: 1.4),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 20),
            _ErrorBanner(message: _submitError!),
          ],
          const SizedBox(height: 24),
          const _SectionLabel('IDENTITY'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameController,
            enabled: !_submitting,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Name *',
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Tell us your pet\'s name.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _breedController,
            enabled: !_submitting,
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Breed',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _genderController,
            enabled: !_submitting,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'Gender',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('DATES'),
          const SizedBox(height: 10),
          _DateField(
            controller: _birthDateController,
            label: 'Birth date',
            enabled: !_submitting,
            validator: _validateBirthDate,
            onPick: () => _pickDate(_birthDateController),
          ),
          const SizedBox(height: 14),
          _DateField(
            controller: _adoptionDateController,
            label: 'Home date',
            enabled: !_submitting,
            validator: _validateAdoptionDate,
            onPick: () => _pickDate(_adoptionDateController),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('STORY'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bioController,
            enabled: !_submitting,
            minLines: 4,
            maxLines: 7,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'A note about them',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: PawketColors.brand,
            ),
            child: _submitting
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save field notes'),
          ),
        ],
      ),
    );
  }

  void _initialize(PetDto pet) {
    if (_initialPet != null) return;
    _initialPet = pet;
    _nameController.text = pet.name;
    _birthDateController.text = _dateOnly(pet.birthDate);
    _breedController.text = pet.breed ?? '';
    _genderController.text = pet.gender ?? '';
    _adoptionDateController.text = _dateOnly(pet.adoptionDate);
    _bioController.text = pet.bio ?? '';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final parsed = _parseDate(controller.text);
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null) return;
    controller.text = _dateOnly(selected);
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final date = _parseDate(value);
    if (date == null) return 'Use YYYY-MM-DD.';
    if (date.isAfter(_today())) return 'Birth date cannot be in the future.';
    return null;
  }

  String? _validateAdoptionDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final date = _parseDate(value);
    if (date == null) return 'Use YYYY-MM-DD.';
    if (date.isAfter(_today())) return 'Home date cannot be in the future.';
    final birthDate = _parseDate(_birthDateController.text);
    if (birthDate != null && date.isBefore(birthDate)) {
      return 'Home date cannot be before birth date.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _initialPet == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final updated = await ref
          .read(petRepositoryProvider)
          .updatePet(
            widget.petId,
            UpdatePetRequest(
              name: _nameController.text,
              birthDate: _parseDate(_birthDateController.text),
              estimatedBirth: _initialPet!.estimatedBirth,
              breed: _breedController.text,
              gender: _genderController.text,
              adoptionDate: _parseDate(_adoptionDateController.text),
              bio: _bioController.text,
              version: _initialPet!.version,
            ),
          );
      ref.read(petsProvider.notifier).replace(updated.toDomain());
      ref.invalidate(petDetailsProvider(widget.petId));
      await ref.read(petsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = error is ApiException
            ? error.message
            : 'Could not save this profile. Please try again.';
      });
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.validator,
    required this.onPick,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        suffixIcon: IconButton(
          onPressed: enabled ? onPick : null,
          tooltip: 'Choose $label',
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
      validator: validator,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: PawketColors.inkMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PawketColors.danger.withValues(alpha: .08),
        border: Border.all(color: PawketColors.danger),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: PawketColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: PawketColors.inkMuted,
            ),
            const SizedBox(height: 12),
            const Text('Could not load this pet profile.'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

DateTime? _parseDate(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) return null;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null || _dateOnly(parsed) != normalized) return null;
  return parsed;
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _dateOnly(DateTime? value) {
  if (value == null) return '';
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
}
