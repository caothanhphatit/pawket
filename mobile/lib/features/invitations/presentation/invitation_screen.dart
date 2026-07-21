import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../pets/application/pet_providers.dart';
import '../application/invitation_providers.dart';
import '../data/invitation_dto.dart';

final invitationPreviewProvider = FutureProvider.autoDispose
    .family<InvitationDto, String>(
      (ref, token) =>
          ref.watch(invitationRepositoryProvider).previewInvitation(token),
    );

class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({required this.token, super.key});
  final String token;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  bool _accepting = false;
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(invitationPreviewProvider(widget.token));
    return Scaffold(
      appBar: AppBar(title: const Text('Pawket invitation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: preview.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => _InvalidInvite(
                onRetry: () =>
                    ref.invalidate(invitationPreviewProvider(widget.token)),
              ),
              data: _buildPreview,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(InvitationDto invitation) {
    if (_accepted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, color: PawketColors.leaf, size: 64),
          const SizedBox(height: 16),
          Text(
            'Welcome to ${invitation.petName}\'s circle',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Their profile and shared memories are now available in Pawket.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.go('/profile');
            },
            child: const Text('Open pet profile'),
          ),
        ],
      );
    }

    final isPending =
        invitation.status == 'PENDING' &&
        invitation.expiresAt.isAfter(DateTime.now().toUtc());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: PawketColors.surfaceStrong,
              child: Icon(Icons.pets, size: 34, color: PawketColors.brand),
            ),
            const SizedBox(height: 18),
            Text(
              '${invitation.inviterDisplayName ?? 'A Pawket member'} invited you',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Join ${invitation.petName}\'s lifetime profile as ${_roleLabel(invitation.requestedRole).toLowerCase()}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PawketColors.inkMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _PermissionSummary(role: invitation.requestedRole),
            const SizedBox(height: 24),
            if (isPending)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _accepting ? null : () => _accept(invitation),
                  child: Text(_accepting ? 'Joining…' : 'Accept invitation'),
                ),
              )
            else
              const Text(
                'This invitation is no longer available.',
                style: TextStyle(
                  color: PawketColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(InvitationDto invitation) async {
    setState(() => _accepting = true);
    try {
      await ref
          .read(invitationRepositoryProvider)
          .acceptInvitation(widget.token, idempotencyKey: const Uuid().v4());
      await ref.read(petsProvider.notifier).refresh();
      ref.read(activePetIdProvider.notifier).select(invitation.petId);
      if (mounted) setState(() => _accepted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not accept this invitation. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }
}

class _PermissionSummary extends StatelessWidget {
  const _PermissionSummary({required this.role});
  final PetMemberRole role;

  @override
  Widget build(BuildContext context) {
    final canPost = role == PetMemberRole.caretaker;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PawketColors.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const _PermissionRow(
            icon: Icons.photo_library_outlined,
            text: 'View memories shared with members',
          ),
          if (canPost) ...[
            const SizedBox(height: 10),
            const _PermissionRow(
              icon: Icons.add_a_photo_outlined,
              text: 'Add new photos and memories',
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: PawketColors.leaf),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class _InvalidInvite extends StatelessWidget {
  const _InvalidInvite({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.link_off, size: 54),
      const SizedBox(height: 14),
      Text(
        'This invite could not be opened',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'The link may be invalid, expired, or temporarily unavailable.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}

String _roleLabel(PetMemberRole role) => switch (role) {
  PetMemberRole.owner => 'Owner',
  PetMemberRole.caretaker => 'Caretaker',
  PetMemberRole.follower => 'Follower',
};
