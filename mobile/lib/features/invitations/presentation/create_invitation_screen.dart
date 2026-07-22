import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../pets/application/pet_providers.dart';
import '../application/invitation_providers.dart';
import '../data/invitation_dto.dart';

class CreateInvitationScreen extends ConsumerStatefulWidget {
  const CreateInvitationScreen({required this.petId, super.key});
  final String petId;

  @override
  ConsumerState<CreateInvitationScreen> createState() =>
      _CreateInvitationScreenState();
}

class _CreateInvitationScreenState
    extends ConsumerState<CreateInvitationScreen> {
  PetMemberRole _role = PetMemberRole.caretaker;
  int _expiresInDays = 7;
  bool _isCreating = false;
  InvitationDto? _invitation;

  @override
  Widget build(BuildContext context) {
    final pet = ref
        .watch(petsProvider)
        .where((pet) => pet.id == widget.petId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite someone')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text(
                'Share ${pet?.name ?? 'this pet'}\'s story',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose what they can do. The link can only grant the role selected here.',
                style: TextStyle(color: PawketColors.inkMuted, fontSize: 16),
              ),
              const SizedBox(height: 28),
              Text('ROLE', style: _sectionLabelStyle),
              const SizedBox(height: 10),
              _RoleOption(
                title: 'Caretaker',
                description: 'Can add photos and memories for this pet.',
                icon: Icons.volunteer_activism_outlined,
                selected: _role == PetMemberRole.caretaker,
                onTap: () => setState(() => _role = PetMemberRole.caretaker),
              ),
              const SizedBox(height: 10),
              _RoleOption(
                title: 'Follower',
                description: 'Can view memories shared with pet members.',
                icon: Icons.favorite_border,
                selected: _role == PetMemberRole.follower,
                onTap: () => setState(() => _role = PetMemberRole.follower),
              ),
              const SizedBox(height: 24),
              Text('LINK EXPIRES', style: _sectionLabelStyle),
              const SizedBox(height: 10),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 day')),
                  ButtonSegment(value: 7, label: Text('7 days')),
                  ButtonSegment(value: 30, label: Text('30 days')),
                ],
                selected: {_expiresInDays},
                onSelectionChanged: (value) =>
                    setState(() => _expiresInDays = value.single),
              ),
              const SizedBox(height: 28),
              if (_invitation case final invitation?)
                _CreatedInvite(invitation: invitation)
              else
                FilledButton.icon(
                  onPressed: _isCreating ? null : _create,
                  icon: _isCreating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    _isCreating ? 'Creating link…' : 'Create invite link',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _isCreating = true);
    try {
      final invitation = await ref
          .read(invitationRepositoryProvider)
          .createInvitation(
            widget.petId,
            CreateInvitationRequest(
              requestedRole: _role,
              expiresInDays: _expiresInDays,
            ),
            idempotencyKey: const Uuid().v4(),
          );
      if (mounted) {
        ref.invalidate(pendingInvitationsProvider(widget.petId));
        setState(() => _invitation = invitation);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create the invite link. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

const _sectionLabelStyle = TextStyle(
  color: PawketColors.inkMuted,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.4,
);

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PawketColors.surfaceStrong : PawketColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? PawketColors.brand : PawketColors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? PawketColors.brand : PawketColors.ink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(color: PawketColors.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? PawketColors.brand : PawketColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatedInvite extends StatelessWidget {
  const _CreatedInvite({required this.invitation});
  final InvitationDto invitation;

  @override
  Widget build(BuildContext context) {
    final link =
        invitation.invitationUrl?.toString() ??
        'pawket.app/invite/${invitation.id}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: PawketColors.leaf, size: 38),
            const SizedBox(height: 10),
            Text(
              'Invite link is ready',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PawketColors.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(link, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy invite link'),
            ),
            const SizedBox(height: 8),
            Text(
              'Expires ${_friendlyDate(invitation.expiresAt)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: PawketColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
