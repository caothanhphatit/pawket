import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../account/data/account_repository.dart';
import '../data/member_dto.dart';
import '../data/membership_repository.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return RemoteMembershipRepository(ref.watch(apiClientProvider));
});

final membershipCurrentAccountProvider = FutureProvider.autoDispose<AccountDto>(
  (ref) => RemoteAccountRepository(ref.watch(apiClientProvider)).getCurrent(),
);

final petMembersProvider = FutureProvider.autoDispose
    .family<List<MemberDto>, String>(
      (ref, petId) =>
          ref.watch(membershipRepositoryProvider).listMembers(petId),
    );
