# hadoor

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to run

This project is a Flutter app. Use `flutter run` for development.

## Build iOS IPA from Windows using GitHub Actions

If you don't have a Mac locally, you can use the included GitHub Actions workflow to build an unsigned iOS `.ipa` artifact. The workflow will run on `macos-latest` and produce an `.ipa` under the `build/ios/ipa` output. To use it:

1. Push your code to `main` or trigger the workflow from the Actions tab ("Build iOS IPA").
2. Download the artifact named `ios-ipa` from the workflow run.

Installing on an iPhone from Windows:

- Recommended: use Sideloadly (https://sideloadly.io). Sideloadly can sign and install the downloaded `.ipa` using your Apple ID. If you use a free Apple ID the app must be re-signed every 7 days. If you have a paid Apple Developer account, consider using an Ad‑Hoc profile and 3uTools for installation.

Notes:
- The workflow builds the `.ipa` with `--no-codesign`. If you need an Ad‑Hoc or App Store signed `.ipa`, you must provide code signing credentials and modify the workflow accordingly or use a CI provider's signing features.

## Build Web Application

A GitHub Actions workflow automatically builds the Flutter web version on every push to `main`. The web app is automatically deployed to GitHub Pages.

### Access the Web App:
- Your web app will be available at: `https://Murtadamalak.github.io/hadoor/`

### Build Web Locally (Optional):
```bash
flutter config --enable-web
flutter pub get
flutter build web --release
# Output will be in build/web/
```

### Web Features:
- Same Flutter codebase for iOS, Android, and Web
- Responsive design works on desktop and mobile browsers
- No additional setup required — automatic deployment via GitHub Actions
