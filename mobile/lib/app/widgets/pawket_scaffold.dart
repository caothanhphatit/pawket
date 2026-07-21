import 'package:flutter/material.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';

import '../routing/pawket_navigation.dart';

class PawketScaffold extends StatelessWidget {
  const PawketScaffold({
    required this.currentIndex,
    required this.body,
    this.centerIcon = Icons.photo_camera_outlined,
    this.centerLabel = 'Camera',
    this.centerTooltip = 'Open camera',
    this.onCenterPressed,
    this.scaffoldBackgroundColor,
    super.key,
  });

  final int currentIndex;
  final Widget body;
  final IconData centerIcon;
  final String centerLabel;
  final String centerTooltip;
  final VoidCallback? onCenterPressed;
  final Color? scaffoldBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: scaffoldBackgroundColor,
      body: SafeArea(child: body),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BottomAppBar(
                height: 68,
                padding: EdgeInsets.zero,
                color: PawketColors.surface,
                elevation: 8,
                shadowColor: Colors.black26,
                child: _navigationItems(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationItems(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NavigationItem(
            label: 'Feed',
            icon: Icons.dynamic_feed_outlined,
            selectedIcon: Icons.dynamic_feed,
            selected: currentIndex == 0,
            onPressed: () => PawketNavigation.go(context, '/feed'),
          ),
        ),
        Expanded(
          child: _CenterNavigationItem(
            label: centerLabel,
            tooltip: centerTooltip,
            icon: centerIcon,
            onPressed:
                onCenterPressed ??
                () => PawketNavigation.go(context, '/camera'),
          ),
        ),
        Expanded(
          child: _NavigationItem(
            label: 'Profile',
            icon: Icons.pets_outlined,
            selectedIcon: Icons.pets,
            selected: currentIndex == 1,
            onPressed: () => PawketNavigation.go(context, '/profile'),
          ),
        ),
      ],
    );
  }
}

class _CenterNavigationItem extends StatelessWidget {
  const _CenterNavigationItem({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: PawketColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: PawketColors.brand,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PawketColors.brand : PawketColors.ink;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
