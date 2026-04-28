import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = ref.watch(currentUserProvider);
    final greeting = _greeting();
    final name = _firstName(user);

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
            _today(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$greeting, $name',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(child: _StatCard(value: '0', label: 'day streak', accent: c.accent)),
              const SizedBox(width: Spacing.md),
              Expanded(child: _StatCard(value: '0', label: 'cards due', accent: c.secondary)),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          AppCard(
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Create your first course',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Head to Library, tap +, and add Organic Chem (or whatever else).',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const AppSectionHeader(label: 'Recent'),
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Text(
                  'Your recent activity will appear here.',
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String _firstName(User? user) {
    final raw = user?.displayName?.trim();
    if (raw == null || raw.isEmpty) {
      return user?.email?.split('@').first ?? 'there';
    }
    return raw.split(' ').first;
  }

  static String _today() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.accent});

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: Radii.cardRadius,
        border: Border.all(color: accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.mono(
              context,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
