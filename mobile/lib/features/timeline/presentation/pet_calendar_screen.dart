import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../feed/application/feed_providers.dart';
import '../../pets/application/pet_providers.dart';
import '../../posts/data/post_dto.dart';

class PetCalendarScreen extends ConsumerStatefulWidget {
  const PetCalendarScreen({super.key});

  @override
  ConsumerState<PetCalendarScreen> createState() => _PetCalendarScreenState();
}

class _PetCalendarScreenState extends ConsumerState<PetCalendarScreen> {
  late DateTime visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(activePetProvider);
    final memories = pet == null
        ? null
        : ref.watch(petMemoriesProvider(pet.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pet == null ? 'Memory calendar' : '${pet.name}\'s calendar',
        ),
      ),
      body: pet == null
          ? const Center(child: Text('Choose a pet from Profile.'))
          : memories!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(petMemoriesProvider(pet.id)),
                  child: const Text('Try again'),
                ),
              ),
              data: (page) => _CalendarBody(
                month: visibleMonth,
                posts: page.items,
                onPrevious: () => _moveMonth(-1),
                onNext: _canMoveNext ? () => _moveMonth(1) : null,
                onOpenDay: _openDay,
              ),
            ),
    );
  }

  bool get _canMoveNext {
    final now = DateTime.now();
    return visibleMonth.isBefore(DateTime(now.year, now.month));
  }

  void _moveMonth(int offset) {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + offset);
    });
  }

  Future<void> _openDay(DateTime day, List<PostDto> posts) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullDate(day),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: posts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemBuilder: (_, index) {
                    final post = posts[index];
                    final media = post.media.firstOrNull;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.push('/posts/${post.id}', extra: post);
                      },
                      child: media == null
                          ? const ColoredBox(
                              color: PawketColors.surfaceStrong,
                              child: Icon(Icons.pets),
                            )
                          : Image.network(
                              (media.thumbnailUrl ?? media.url).toString(),
                              fit: BoxFit.cover,
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.month,
    required this.posts,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenDay,
  });

  final DateTime month;
  final List<PostDto> posts;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final void Function(DateTime day, List<PostDto> posts) onOpenDay;

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<PostDto>>{};
    for (final post in posts) {
      final local = post.capturedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => []).add(post);
    }
    final monthDays = byDay.keys
        .where((day) => day.year == month.year && day.month == month.month)
        .length;
    final first = DateTime(month.year, month.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final days = List.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _monthName(month),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '$monthDays ${monthDays == 1 ? 'day' : 'days'} remembered',
                    style: const TextStyle(color: PawketColors.inkMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: PawketColors.inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final dayPosts = byDay[day] ?? const <PostDto>[];
            final inMonth = day.month == month.month;
            final remembered = dayPosts.isNotEmpty;
            return InkWell(
              onTap: remembered ? () => onOpenDay(day, dayPosts) : null,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  color: remembered
                      ? PawketColors.brand
                      : inMonth
                      ? PawketColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: inMonth && !remembered
                      ? Border.all(color: PawketColors.outline)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: remembered
                          ? Colors.white
                          : inMonth
                          ? PawketColors.ink
                          : PawketColors.outline,
                      fontWeight: remembered
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

String _monthName(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

String _fullDate(DateTime value) {
  return '${value.day} ${_monthName(value)}';
}
