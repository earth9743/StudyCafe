# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**kagong_map** — A real-time information sharing platform for 'Kagong' (studying at cafes) culture, providing crowd levels and outlet availability. Built with Flutter targeting Android, iOS, and Web.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Lint and static analysis
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
flutter build web        # Build Web
```

## Architecture

Currently in early scaffold state — `lib/main.dart` is the only source file. As the app grows, structure should follow feature-based organization under `lib/`.

The app is a Flutter Material Design application. Platform-specific configuration lives in `android/` and `ios/` directories. Linting is configured via `analysis_options.yaml` using `package:flutter_lints/flutter.yaml`.