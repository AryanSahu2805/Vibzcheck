# vibzcheck

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local setup (quick)

1. Copy the example env and fill in secrets:

```bash
cp .env.example .env
# Edit .env and provide real values for SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET,
# CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.
```

2. Install packages and run the app:

```bash
flutter pub get
flutter run
```

Notes:
- The project loads runtime secrets from a `.env` file. Keep that file out of
	version control (a `.gitignore` entry has been added).
- If you still see a "Configuration Error" screen on startup, verify that the
	`.env` file exists at the project root and contains the required variables.
