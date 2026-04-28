import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: EmptyState(
        title: 'Progress',
        subtitle:
            'Heatmap, mastery, streaks, and readiness score land in Sprint 12.',
        icon: Icons.show_chart,
      ),
    );
  }
}
