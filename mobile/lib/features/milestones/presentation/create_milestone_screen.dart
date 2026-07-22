import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/pawket_theme.dart';
import '../application/milestone_providers.dart';
import '../data/milestone_dto.dart';

class CreateMilestoneScreen extends ConsumerStatefulWidget {
  const CreateMilestoneScreen({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<CreateMilestoneScreen> createState() =>
      _CreateMilestoneScreenState();
}

class _CreateMilestoneScreenState extends ConsumerState<CreateMilestoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  MilestoneType _type = MilestoneType.birthday;
  DateTime _occurredOn = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add milestone')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text(
              'Mark a chapter',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep important dates beside the everyday memories.',
              style: TextStyle(color: PawketColors.inkMuted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<MilestoneType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Milestone type'),
              items: const [
                DropdownMenuItem(
                  value: MilestoneType.birthday,
                  child: Text('Birthday'),
                ),
                DropdownMenuItem(
                  value: MilestoneType.homeDay,
                  child: Text('Home day'),
                ),
                DropdownMenuItem(
                  value: MilestoneType.firstTrip,
                  child: Text('First trip'),
                ),
                DropdownMenuItem(
                  value: MilestoneType.custom,
                  child: Text('Something else'),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _type = value!),
            ),
            if (_type == MilestoneType.custom) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                enabled: !_submitting,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Milestone title *',
                  counterText: '',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Give this milestone a title.'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: PawketColors.outline),
              ),
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(_friendlyDate(_occurredOn)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _submitting ? null : _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              enabled: !_submitting,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_outlined),
              label: Text(_submitting ? 'Saving…' : 'Save milestone'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredOn,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _occurredOn = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(milestoneRepositoryProvider)
          .createMilestone(
            widget.petId,
            CreateMilestoneRequest(
              type: _type,
              occurredOn: _occurredOn,
              customTitle: _titleController.text,
              note: _noteController.text,
            ),
          );
      ref.invalidate(petMilestonesProvider(widget.petId));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this milestone.')),
        );
        setState(() => _submitting = false);
      }
    }
  }
}

String _friendlyDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
