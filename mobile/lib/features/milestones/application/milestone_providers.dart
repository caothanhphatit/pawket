import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../data/milestone_dto.dart';
import '../data/milestone_repository.dart';

final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  return RemoteMilestoneRepository(ref.watch(apiClientProvider));
});

final petMilestonesProvider = FutureProvider.autoDispose
    .family<List<MilestoneDto>, String>(
      (ref, petId) =>
          ref.watch(milestoneRepositoryProvider).listMilestones(petId),
    );
