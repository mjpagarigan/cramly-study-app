import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authControllerProvider).signOut();
    } on FirebaseAuthException catch (error) {
      _showSignOutError(error.message);
    } catch (_) {
      _showSignOutError(null);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showSignOutError(String? detail) {
    if (!mounted) return;
    final message = detail?.trim().isNotEmpty == true
        ? detail!.trim()
        : 'We could not sign you out. Check your connection and try again.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = ref.watch(currentUserProvider);
    final mode = ref.watch(themeControllerProvider);
    final displayName = user?.displayName?.trim();
    final email = user?.email?.trim();
    final primaryLabel = displayName?.isNotEmpty == true
        ? displayName!
        : _emailName(email) ?? 'Cramly student';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.page,
          Spacing.lg,
          Spacing.page,
          Spacing.xxxl,
        ),
        children: [
          const AppPageHeader(
            eyebrow: 'Your account',
            title: 'Profile',
            showTrace: true,
          ),
          const SizedBox(height: 22),
          AppCard(
            child: Row(
              children: [
                _ProfileAvatar(
                  photoUrl: user?.photoURL,
                  initials: _initials(displayName, email),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: c.foreground),
                      ),
                      if (email?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: c.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          const _SectionTitle(
            title: 'Appearance',
            note: 'Saved on this device',
          ),
          _SettingsGroup(
            children: [
              _ThemeRow(
                label: 'Light',
                selected: mode == ThemeMode.light,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .set(ThemeMode.light),
              ),
              _ThemeRow(
                label: 'Dark',
                selected: mode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .set(ThemeMode.dark),
              ),
              _ThemeRow(
                label: 'System',
                selected: mode == ThemeMode.system,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .set(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: 27),
          const _SectionTitle(title: 'Account'),
          const _SettingsGroup(
            children: [
              _PlannedRow(label: 'Edit account'),
              _PlannedRow(label: 'Apple sign-in'),
            ],
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Sign out',
            variant: AppButtonVariant.destructive,
            fullWidth: true,
            busy: _signingOut,
            onPressed: _signingOut ? null : _signOut,
          ),
        ],
      ),
    );
  }

  static String? _emailName(String? email) {
    if (email == null || email.isEmpty) return null;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  static String _initials(String? name, String? email) {
    final source = name?.trim().isNotEmpty == true
        ? name!.trim()
        : (_emailName(email) ?? '');
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'[\s._-]+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.initials});

  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = ColoredBox(
      color: c.surfaceSoft,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.primary,
          ),
        ),
      ),
    );
    final url = photoUrl?.trim();

    return Semantics(
      image: true,
      label: 'Profile photo',
      child: ExcludeSemantics(
        child: ClipOval(
          child: SizedBox.square(
            dimension: 52,
            child: url?.isNotEmpty == true
                ? Image.network(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : fallback,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: c.foreground,
                ),
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(width: Spacing.md),
            Text(
              note!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.surfaceRadius,
        border: Border.all(color: c.border),
      ),
      child: ClipRRect(
        borderRadius: Radii.surfaceRadius,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) Divider(color: c.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label appearance',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          focusColor: c.poppySubtle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: c.foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c.primary : c.border,
                        width: selected ? 5 : 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannedRow extends StatelessWidget {
  const _PlannedRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '$label, planned and unavailable',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: c.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const AppBadge(label: 'Planned', color: AppBadgeColor.planned),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
