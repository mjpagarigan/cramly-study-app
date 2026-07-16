# Cramly mobile

The Flutter client uses Riverpod, GoRouter, Firebase listeners and Storage uploads, with canonical writes sent through the existing FastAPI service. The Learning Trace visual system and all brand fonts are bundled locally for deterministic rendering.

## Requirements

- Flutter 3.44.6 (project Dart SDK constraint `^3.11.3`)
- The existing Android and iOS Firebase configuration files
- A reachable FastAPI base URL configured through the existing app environment

Run verification from this directory:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Live Google sign-in also requires the external Android SHA/OAuth setup and iOS plist URL-scheme setup. Email/password authentication and the mock-based tests do not depend on that console work.

Quizzes, podcasts, spaced repetition, daily queues, voice study, and analytics remain clearly disabled. Review is intentionally linear and write-free; it does not create sessions or update card statistics.

See [../docs/SETUP.md](../docs/SETUP.md) for the full repository setup flow.
