# EGT Mobile — Build & Release Guide

Flutter app for Eagle Goods Trading Co. (B2B sourcing / export).
Flavors: **dev**, **staging**, **prod**.

> Status note (2026-09-25): this project was authored in an environment
> **without the Flutter SDK**, so it has not been compiled here. The
> commands below are what a machine *with* the SDK runs to verify it.

## 1. Install the SDK

1. Install Flutter (stable channel, Dart >= 3.4):
   https://docs.flutter.dev/get-started/install
2. Verify:
   ```sh
   flutter doctor
   ```
   Accept the Android licenses: `flutter doctor --android-licenses`.

## 2. Dependencies & static checks

```sh
cd apps/mobile
flutter pub get
flutter analyze            # must be clean
flutter test               # unit tests: parser, DTOs, wizard, error mapping
```

> Gradle wrapper: `android/gradlew`, `gradlew.bat`, and
> `gradle-wrapper.jar` are intentionally not vendored here. Before the first
> Android build, generate them with a local Gradle install
> (`gradle wrapper --gradle-version 8.7` inside `android/`), or copy the
> wrapper from any working Flutter project. Do not commit a wrapper jar
> built from an untrusted source.

Localization is hand-rolled (no codegen step): `lib/l10n/app_en.arb` is the
source of truth; `app_pa.arb` / `app_hi.arb` are untranslated stubs that fall
back to English per key. Do not ship Punjabi/Hindi UI without native review.

## 3. Run (per flavor)

```sh
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Flavor → API base URL is set in `lib/src/core/config/app_config.dart`
(`AppConfig.dev()/staging()/prod()`).

## 4. Android release

Prerequisites (all **needs-from-Sukh** until provided):

- [ ] Play Console developer account (first upload is manual).
- [ ] Release keystore (`.jks`) + `android/key.properties`
      (copy from `android/key.properties.example`; the real file is
      git-ignored and must never be committed).
- [ ] `android/app/google-services.json` from the Firebase console
      (FCM push; git-ignored, never commit).
- [ ] Server-side `/.well-known/assetlinks.json` on
      `eaglegoodstrading.com` + `/app/*` routes so App Links verify
      (intent filter is already in `AndroidManifest.xml` with `autoVerify`).

Build:

```sh
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
# output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

Upload the `.aab` to Play Console → internal testing track first.

## 5. iOS release

Prerequisites:

- [ ] Apple Developer account + distribution certificate/provisioning profile.
- [ ] `ios/Runner/GoogleService-Info.plist` from the Firebase console
      (git-ignored, never commit).
- [ ] Server-side `apple-app-site-association` for
      `eaglegoodstrading.com/app/*` (entitlement already declares
      `applinks:eaglegoodstrading.com`).
- [ ] `pod install` (runs automatically on first `flutter build ipa`).

Build:

```sh
flutter build ipa --flavor prod -t lib/main_prod.dart --release --export-method app-store
```

Open `ios/Runner.xcassets` at least once in Xcode to confirm the generated
`AppIcon.appiconset` renders from the 1024px master; regenerate full size
sets with `flutter_launcher_icons` before store submission if needed.

Xcode schemes provided: `dev`, `staging`, `prod`
(`ios/Runner.xcodeproj/xcshareddata/xcschemes/`), each bound to its
`*-dev / *-staging / *-prod` build configurations and entrypoint
(`lib/main_dev.dart` etc. via `FLUTTER_TARGET` in `ios/Flutter/*.xcconfig`).

## 6. Deep links

| Link | Destination |
|---|---|
| `egt://product/:id` | `/products/:id` |
| `egt://rfq/:id` | `/rfq/result/:id` |
| `egt://order/:id` | `/orders/:id` |
| `egt://shipment/:id` | `/shipments/:id` |
| `https://eaglegoodstrading.com/app/<path>` | `/<path>` (App/Universal Link) |

Custom-scheme links work after install. HTTPS links additionally require the
server files above.

## 7. Signing checklist (release day)

1. Keystore created (`keytool -genkeypair`) and backed up OFF the build
   machine (two copies, e.g. encrypted USB + vault).
2. `android/key.properties` filled on the build machine only.
3. `versionCode` bumped in `android/app/build.gradle`;
   `CFBundleVersion` comes from `--build-number`.
4. Release build → install on a real device → smoke test: login, RFQ
   wizard submit, quotation accept, order timeline, shipment tracking,
   document download, push notification.
5. Upload `.aab` (Play) / `.ipa` (App Store Connect); never claim
   publication without the store listing being live.

## 8. Known honest limitations

- Fonts: the theme references Archivo/DM Sans, but no Flutter-compatible
  TTF/OTF files are bundled (the website's WOFF2 files do not work in
  Flutter). The app falls back to system fonts until licensed font files
  are added under `assets/fonts/` and declared in `pubspec.yaml`.
- Push: `PushNotificationService` is structured but inert until
  `google-services.json` / `GoogleService-Info.plist` are provided and
  `registerDevice` is wired post-login.
- Launcher icons are generated placeholders (brand red + "EGT"); replace
  with final artwork before store submission.
