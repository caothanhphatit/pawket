import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../pets/application/pet_providers.dart';
import '../../invitations/application/invitation_providers.dart';
import '../../invitations/data/invitation_dto.dart';
import '../application/membership_providers.dart';
import '../data/member_dto.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final Set<String> _busyMemberIds = {};
  final Set<String> _revokingInvitationIds = {};

  @override
  Widget build(BuildContext context) {
    final petId = widget.petId;
    final pet = ref
        .watch(petsProvider)
        .where((pet) => pet.id == petId)
        .firstOrNull;
    final members = ref.watch(petMembersProvider(petId));
    final account = ref.watch(membershipCurrentAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family & friends')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _MembersError(
              onRetry: () => ref.invalidate(petMembersProvider(petId)),
            ),
            data: (items) {
              final currentUserId = account.when(
                data: (value) => value.id,
                error: (_, _) => null,
                loading: () => null,
              );
              final canManageMembers = items.any(
                (member) =>
                    member.userId == currentUserId && member.role == 'OWNER',
              );
              final pendingInvitations = canManageMembers
                  ? ref.watch(pendingInvitationsProvider(petId))
                  : null;
              return RefreshIndicator(
                onRefresh: () => ref.refresh(petMembersProvider(petId).future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Text(
                      pet == null
                          ? 'People in this profile'
                          : 'People in ${pet.name}\'s life',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Members can follow memories or help add new ones, depending on their role.',
                      style: TextStyle(
                        color: PawketColors.inkMuted,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (items.isEmpty)
                      _EmptyMembers(
                        onInvite: () => context.push('/pets/$petId/invite'),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < items.length;
                              index++
                            ) ...[
                              _MemberTile(
                                member: items[index],
                                canRemove:
                                    canManageMembers &&
                                    items[index].role != 'OWNER',
                                isBusy: _busyMemberIds.contains(
                                  items[index].userId,
                                ),
                                onRoleChanged: (role) =>
                                    _changeRole(items[index], role),
                                onRemove: () => _confirmRemove(items[index]),
                              ),
                              if (index != items.length - 1)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (canManageMembers) ...[
                      _PendingInvitations(
                        invitations: pendingInvitations!,
                        revokingIds: _revokingInvitationIds,
                        onRevoke: _confirmRevokeInvitation,
                        onRetry: () => ref.invalidate(
                          pendingInvitationsProvider(widget.petId),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.push('/pets/$petId/invite'),
                        icon: const Icon(Icons.link),
                        label: const Text('Create invite link'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(MemberDto member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.displayName}?'),
        content: const Text(
          'They will lose access to this pet profile and its shared memories.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PawketColors.danger),
            child: const Text('Remove member'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyMemberIds.add(member.userId));
    try {
      await ref
          .read(membershipRepositoryProvider)
          .removeMember(widget.petId, member.userId);
      ref.invalidate(petMembersProvider(widget.petId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove this member.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyMemberIds.remove(member.userId));
      }
    }
  }

  Future<void> _changeRole(MemberDto member, String role) async {
    if (member.role == role || _busyMemberIds.contains(member.userId)) return;
    setState(() => _busyMemberIds.add(member.userId));
    try {
      await ref
          .read(membershipRepositoryProvider)
          .updateMemberRole(widget.petId, member.userId, role);
      ref.invalidate(petMembersProvider(widget.petId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not change this member role.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyMemberIds.remove(member.userId));
    }
  }

  Future<void> _confirmRevokeInvitation(InvitationDto invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke invite link?'),
        content: const Text(
          'Anyone who has this link will no longer be able to join with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep link'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PawketColors.danger),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _revokingInvitationIds.add(invitation.id));
    try {
      await ref
          .read(invitationRepositoryProvider)
          .revokeInvitation(invitation.id);
      ref.invalidate(pendingInvitationsProvider(widget.petId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not revoke this invite.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _revokingInvitationIds.remove(invitation.id));
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.canRemove,
    required this.isBusy,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final MemberDto member;
  final bool canRemove;
  final bool isBusy;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final initial = member.displayName.trim().isEmpty
        ? '?'
        : member.displayName.trim().characters.first.toUpperCase();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: PawketColors.surfaceStrong,
        foregroundColor: PawketColors.ink,
        child: Text(initial),
      ),
      title: Text(
        member.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(_roleDescription(member.role)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleBadge(role: member.role),
          if (canRemove) ...[
            const SizedBox(width: 4),
            if (isBusy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Manage ${member.displayName}',
                onSelected: (value) {
                  if (value == 'REMOVE') {
                    onRemove();
                  } else {
                    onRoleChanged(value);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'CARETAKER',
                    enabled: member.role != 'CARETAKER',
                    child: const Text('Make caretaker'),
                  ),
                  PopupMenuItem(
                    value: 'FOLLOWER',
                    enabled: member.role != 'FOLLOWER',
                    child: const Text('Make follower'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'REMOVE',
                    child: Text(
                      'Remove member',
                      style: TextStyle(color: PawketColors.danger),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  static String _roleDescription(String role) => switch (role) {
    'OWNER' => 'Manages profile and sharing',
    'CARETAKER' => 'Can add memories',
    _ => 'Can follow shared memories',
  };
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'OWNER' => 'Owner',
      'CARETAKER' => 'Caretaker',
      _ => 'Follower',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: role == 'OWNER'
            ? PawketColors.surfaceStrong
            : PawketColors.canvas,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PendingInvitations extends StatelessWidget {
  const _PendingInvitations({
    required this.invitations,
    required this.revokingIds,
    required this.onRevoke,
    required this.onRetry,
  });

  final AsyncValue<List<InvitationDto>> invitations;
  final Set<String> revokingIds;
  final ValueChanged<InvitationDto> onRevoke;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PENDING INVITES', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        invitations.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.link_off_outlined),
              title: const Text('Could not load pending invites'),
              trailing: TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.link_outlined),
                  title: Text('No pending invite links'),
                  subtitle: Text(
                    'New links will appear here until used or revoked.',
                  ),
                ),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    ListTile(
                      leading: const Icon(Icons.link_outlined),
                      title: Text(_invitationRole(items[index].requestedRole)),
                      subtitle: Text(
                        'Expires ${_friendlyDate(items[index].expiresAt)}',
                      ),
                      trailing: revokingIds.contains(items[index].id)
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              tooltip: 'Revoke invite',
                              onPressed: () => onRevoke(items[index]),
                              icon: const Icon(Icons.link_off_outlined),
                            ),
                    ),
                    if (index != items.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static String _invitationRole(PetMemberRole role) => switch (role) {
    PetMemberRole.caretaker => 'Caretaker invite',
    PetMemberRole.follower => 'Follower invite',
    PetMemberRole.owner => 'Owner invite',
  };

  static String _friendlyDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers({required this.onInvite});
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.group_outlined,
              size: 42,
              color: PawketColors.leaf,
            ),
            const SizedBox(height: 12),
            Text(
              'This circle is just getting started',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite someone who helps care for your pet or wants to follow their story.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Invite someone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersError extends StatelessWidget {
  const _MembersError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              'Could not load members',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
