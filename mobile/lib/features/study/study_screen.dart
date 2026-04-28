import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: EmptyState(
        title: 'Study',
        subtitle:
            'Daily review queue and flashcard sessions land in Sprint 6.',
        icon: Icons.flash_on,
      ),
    );
  }
}
