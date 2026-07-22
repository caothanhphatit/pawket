import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../data/invitation_repository.dart';
import '../data/invitation_dto.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return RemoteInvitationRepository(ref.watch(apiClientProvider));
});

final pendingInvitationsProvider = FutureProvider.autoDispose
    .family<List<InvitationDto>, String>(
      (ref, petId) =>
          ref.watch(invitationRepositoryProvider).listPendingInvitations(petId),
    );
