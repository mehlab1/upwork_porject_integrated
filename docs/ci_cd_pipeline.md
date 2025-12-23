# Frontend CI/CD Pipeline

This project now ships with an automated GitHub Actions pipeline tailored for the Flutter frontend. The workflow lives in `.github/workflows/frontend-ci.yml` and covers three stages: quality checks, build artifacts, and smoke tests.

## Triggers

- Every push to `main` or `develop`
- Pull requests targeting `main` or `develop`
- Manual runs via the **Run workflow** button in GitHub

## Jobs Overview

| Job | Purpose | Key Commands |
| --- | --- | --- |
| `quality_checks` | Ensures code health before building. | `flutter format --set-exit-if-changed .`, `flutter analyze`, `flutter test --reporter expanded` |
| `build_artifacts` | Generates distributable bundles. | `flutter build web --release`, `flutter build apk --release` |
| `smoke_tests` | Validates artifacts exist before distribution. | `test -f build/web/index.html`, `test -f build/app/outputs/flutter-apk/app-release.apk` |

## Artifacts

Two build artifacts are published for each successful run:

- `web-build`: the Flutter web bundle under `build/web`
- `android-apk`: the unsigned release APK at `build/app/outputs/flutter-apk/app-release.apk`

You can download these artifacts from the workflow run summary to share with testers or attach to releases.

## Local Parity

To mirror the pipeline locally, run:

```bash
flutter pub get
flutter format --set-exit-if-changed .
flutter analyze
flutter test --reporter expanded
flutter build web --release
flutter build apk --release
```

Ensure the Android SDK licenses are accepted locally if you plan to build APKs:

```bash
flutter doctor --android-licenses
```

## Extending the Pipeline

- Add additional build targets (iOS, Windows, macOS) by copying the build/upload pattern used here.
- Integrate deployment steps (e.g., Firebase Hosting, Play Store) by appending jobs that consume the published artifacts.
- Enable Slack/Teams notifications by wiring a fourth job that consumes the success/failure of the preceding stages.

