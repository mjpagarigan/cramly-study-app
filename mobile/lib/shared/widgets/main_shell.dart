import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../features/courses/widgets/course_form_sheet.dart';

/// Hosts the five stateful root branches.
///
/// Bottom navigation is intentionally limited to the five root destinations.
/// Nested course, document, deck, review, and summary routes keep their own
/// detail chrome without a persistent tab bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell, this.location});

  final StatefulNavigationShell navigationShell;
  final String? location;

  static const _rootLocations = {
    '/home',
    '/library',
    '/study',
    '/progress',
    '/profile',
  };

  static const _tabs = [
    _TabSpec(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _TabSpec(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Library',
    ),
    _TabSpec(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle,
      label: 'Study',
    ),
    _TabSpec(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Progress',
    ),
    _TabSpec(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = location;
    final atRoot = path == null || _rootLocations.contains(path);
    final showFab = path == null
        ? navigationShell.currentIndex < 2
        : path == '/home' || path == '/library';

    return Scaffold(
      backgroundColor: c.background,
      body: navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              tooltip: 'Add study material',
              onPressed: () => _showFabMenu(context),
              backgroundColor: c.primary,
              foregroundColor: c.textOnAccent,
              elevation: 6,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: atRoot
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _TabButton(
                            spec: _tabs[i],
                            selected: navigationShell.currentIndex == i,
                            onTap: () => navigationShell.goBranch(
                              i,
                              initialLocation:
                                  i == navigationShell.currentIndex,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _showFabMenu(BuildContext context) async {
    final action = await showModalBottomSheet<_FabAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const _FabMenuSheet(),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case _FabAction.upload:
        context.push('/upload');
      case _FabAction.newCourse:
        await showCourseFormSheet(context);
    }
  }
}

enum _FabAction { upload, newCourse }

class _FabMenuSheet extends StatelessWidget {
  const _FabMenuSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.page,
        Spacing.sm,
        Spacing.page,
        Spacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuRow(
            icon: Icons.upload_file_outlined,
            label: 'Upload material',
            subtitle: 'Files, audio, YouTube, or web',
            color: c.primary,
            onTap: () => Navigator.of(context).pop(_FabAction.upload),
          ),
          Divider(color: c.border),
          _MenuRow(
            icon: Icons.create_new_folder_outlined,
            label: 'Create a course',
            subtitle: 'Organize documents and decks',
            color: c.textSecondary,
            onTap: () => Navigator.of(context).pop(_FabAction.newCourse),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$label. $subtitle',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.controlRadius,
          focusColor: c.poppySubtle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 21, color: color),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(color: c.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: c.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          focusColor: c.poppySubtle,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? spec.activeIcon : spec.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  spec.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
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
