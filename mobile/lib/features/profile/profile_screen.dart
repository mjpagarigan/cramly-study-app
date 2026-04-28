import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = ref.watch(currentUserProvider);
    final mode = ref.watch(themeControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.lg,
          Spacing.xl,
          Spacing.xxxl,
        ),
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.accentSubtle,
                    borderRadius: Radii.cardRadius,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(user?.displayName, user?.email),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName?.trim().isNotEmpty == true
                            ? user!.displayName!
                            : (user?.email ?? 'Signed in'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.email!,
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const AppSectionHeader(label: 'Appearance'),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Column(
              children: [
                _ThemeRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  selected: mode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .set(ThemeMode.dark),
                ),
                Divider(height: 1, color: c.borderSubtle),
                _ThemeRow(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  selected: mode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .set(ThemeMode.light),
                ),
                Divider(height: 1, color: c.borderSubtle),
                _ThemeRow(
                  icon: Icons.brightness_auto_outlined,
                  label: 'System',
                  selected: mode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .set(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          AppButton(
            label: 'Sign out',
            variant: AppButtonVariant.destructive,
            icon: Icons.logout,
            fullWidth: true,
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
    );
  }

  static String _initials(String? name, String? email) {
    final source = (name?.trim().isNotEmpty == true) ? name! : (email ?? '');
    if (source.isEmpty) return '?';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? c.accent : c.textSecondary),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: c.accent),
          ],
        ),
      ),
    );
  }
}
