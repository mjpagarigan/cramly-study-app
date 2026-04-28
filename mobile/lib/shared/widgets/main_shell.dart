import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../features/courses/widgets/course_form_sheet.dart';

/// Wraps the bottom-nav branches. The FAB is visible on Home + Library and
/// opens a small menu offering "Upload file" or "New course" — matches the
/// design's `app.jsx` FAB-with-actions pattern.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabSpec(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _TabSpec(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Library',
    ),
    _TabSpec(icon: Icons.flash_on_outlined, activeIcon: Icons.flash_on, label: 'Study'),
    _TabSpec(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
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
    final showFab = navigationShell.currentIndex < 2;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => _showFabMenu(context),
              backgroundColor: c.accent,
              foregroundColor: c.textOnAccent,
              elevation: 0,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  _TabButton(
                    spec: _tabs[i],
                    selected: navigationShell.currentIndex == i,
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFabMenu(BuildContext context) async {
    final action = await showModalBottomSheet<_FabAction>(
      context: context,
      backgroundColor:
          Theme.of(context).bottomSheetTheme.backgroundColor,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuRow(
              icon: Icons.upload_file,
              label: 'Upload file',
              subtitle: 'PDF, DOCX, PPTX, image, audio, YouTube, web URL',
              color: c.accent,
              onTap: () => Navigator.of(context).pop(_FabAction.upload),
            ),
            Divider(height: 1, color: c.borderSubtle),
            _MenuRow(
              icon: Icons.school_outlined,
              label: 'New course',
              subtitle: 'A folder for documents, decks, and quizzes',
              color: c.secondary,
              onTap: () => Navigator.of(context).pop(_FabAction.newCourse),
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
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
    final color = selected ? c.accent : c.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? spec.activeIcon : spec.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
