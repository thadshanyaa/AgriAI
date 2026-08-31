# AgriAI source repository

This repository contains the Flutter application source, platform projects,
tests and runtime assets. The on-device TFLite model is a runtime asset and
must remain in the repository. Build outputs, installers, local credentials,
raw dataset archives and training checkpoints are not included.

## Configure a fresh checkout

1. Install Flutter compatible with `pubspec.yaml` and the Android SDK.
2. Run `flutter pub get` from the repository root.
3. Register the Android application in your Firebase project using the actual
   application ID configured in `android/app/build.gradle.kts` (or the Gradle
   build file present in this checkout).
4. Download your Firebase Android client configuration and place it at
   `android/app/google-services.json`. This file is intentionally Git-ignored;
   the existing local copy was not removed. A fresh clone needs its own copy.
5. Configure Firebase Authentication and Firestore for your project. Review
   `firestore.rules` and `firestore.indexes.json` before deploying them.
6. Connect an Android device or start an emulator, then run `flutter run`.

Do not commit service-account private keys, passwords, provider API secrets,
signing keys or `.env` files. Private repository visibility is not a substitute
for protecting credentials or enforcing Firebase security rules.

Training notebooks/scripts are stored separately from this application folder
and have not been added to this repository as part of the initial Git setup.
