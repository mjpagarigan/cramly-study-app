import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

/// Shown while Firebase Auth restores the persisted user from disk.
/// Once `authStateProvider` has its first value, the router redirects to
/// `/home` (signed in) or `/login` (signed out).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cramly',
              style: GoogleFonts.dmSans(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: c.accent,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: c.accent,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
