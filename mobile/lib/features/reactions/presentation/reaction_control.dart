import 'package:flutter/material.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../posts/data/post_dto.dart';

typedef ReactionChanged = Future<ReactionSummaryDto> Function(String? reaction);

class ReactionControl extends StatefulWidget {
  const ReactionControl({
    required this.summary,
    required this.onChanged,
    this.onShowPeople,
    super.key,
  });

  final ReactionSummaryDto summary;
  final ReactionChanged onChanged;
  final VoidCallback? onShowPeople;

  @override
  State<ReactionControl> createState() => _ReactionControlState();
}

class _ReactionControlState extends State<ReactionControl> {
  late ReactionSummaryDto _summary;
  bool _updating = false;

  static const reactions = <(String, String)>[
    ('LOVE', '❤️'),
    ('PAW', '🐾'),
    ('LAUGH', '😄'),
    ('WOW', '🥹'),
  ];

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
  }

  @override
  void didUpdateWidget(covariant ReactionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary && !_updating) {
      _summary = widget.summary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (type, emoji) in reactions)
          _ReactionChip(
            emoji: emoji,
            count: _summary.counts[type] ?? 0,
            selected: _summary.currentUserReaction == type,
            enabled: !_updating,
            onTap: () => _select(type),
          ),
        if (widget.onShowPeople != null &&
            _summary.counts.values.fold<int>(0, (sum, value) => sum + value) >
                0)
          IconButton(
            tooltip: 'See who reacted',
            onPressed: widget.onShowPeople,
            icon: const Icon(Icons.people_outline, size: 20),
          ),
      ],
    );
  }

  Future<void> _select(String type) async {
    if (_updating) return;
    final previous = _summary;
    final removing = previous.currentUserReaction == type;
    setState(() {
      _updating = true;
      _summary = _optimistic(previous, removing ? null : type);
    });
    try {
      final saved = await widget.onChanged(removing ? null : type);
      if (mounted) setState(() => _summary = saved);
    } catch (_) {
      if (mounted) {
        setState(() => _summary = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update reaction.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  ReactionSummaryDto _optimistic(ReactionSummaryDto current, String? next) {
    final counts = Map<String, int>.of(current.counts);
    final old = current.currentUserReaction;
    if (old != null) counts[old] = ((counts[old] ?? 1) - 1).clamp(0, 1 << 31);
    if (next != null) counts[next] = (counts[next] ?? 0) + 1;
    return ReactionSummaryDto(counts: counts, currentUserReaction: next);
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String emoji;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$emoji reaction, $count',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? PawketColors.surfaceStrong : PawketColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? PawketColors.brand : PawketColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
