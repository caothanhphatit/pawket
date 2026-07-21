import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../data/invitation_repository.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return RemoteInvitationRepository(ref.watch(apiClientProvider));
});
