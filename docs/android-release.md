# Android packaging and release

Development revision: 8 October 2026. These instructions prepare Android packages. Hardware acceptance, phone testing, CAD exports and research reconciliation remain separate requirements in [P2 status](p2-status.md). No store submission or production signing key has been created by this update.

## Identity and build variants

The owner selected `io.github.mohamedaymanouchker.robocode` as the release application ID. The display name is **RoboCode**. Confirm availability in the intended store before first publication; changing the ID later creates a different app.

| Variant | Android application ID | Display name | Signing |
| --- | --- | --- | --- |
| Debug | `io.github.mohamedaymanouchker.robocode.debug` | RoboCode (Test) | Local Android debug key |
| Profile | `io.github.mohamedaymanouchker.robocode.profile` | RoboCode (Profile) | Debug key; performance testing only |
| Release | `io.github.mohamedaymanouchker.robocode` | RoboCode | Owner's private key, or explicitly unsigned for build checks |

These are separate Android installations and separate local program libraries. The older `com.example.robocode` app's saved programs remain in that app. There is no automatic migration or program export; retain the old installation if its data is needed. Debug and profile builds cannot upgrade the release app.

The version comes from `mobile-app/pubspec.yaml` (`1.0.0+1` at this checkpoint). Increase the build number after `+` for each published update. Android minimum SDK is 24 and target/compile SDK is 36 with the pinned Flutter SDK.

## Toolchain

- Flutter 3.41.4 / Dart 3.11.1; dependency versions are recorded in `pubspec.lock`.
- Android Gradle Plugin 8.11.1, Kotlin Gradle Plugin 2.2.20 and Gradle 8.14. These match the defaults in this Flutter SDK. The Gradle distribution's SHA-256 is pinned in the wrapper properties.
- Java 17 for CI and Java/Kotlin bytecode targets; Android NDK `27.0.12077973`.
- Android platform 36 and build-tools 36.0.0 for artifact inspection.

AGP 8.11 supports API 36 and requires at least Gradle 8.13 / JDK 17. Kotlin 2.2.20 supports this AGP/Gradle combination. See the official [Android compatibility notes](https://developer.android.com/build/releases/agp-8-11-0-release-notes) and [Kotlin compatibility table](https://kotlinlang.org/docs/gradle-configure-project.html).

## Build a supervised-test APK

From `mobile-app`:

```text
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug --no-pub
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`. This is a test package. Installing it and testing permissions, discovery, reconnect, backgrounding, fresh/stale telemetry and robot STOP behavior are still required. Test with the matching firmware and [wiring](../hardware/wiring.md).

## Configure private signing

Follow Flutter's [Android signing instructions](https://docs.flutter.dev/deployment/android#sign-the-app). If this application already has a signing/upload key, reuse the appropriate key; do not replace an established signing identity.

For a new key, run Java's `keytool` interactively so passwords are entered locally. A Windows example is:

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\robocode-upload.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then copy `mobile-app/android/key.properties.example` to `mobile-app/android/key.properties` and fill in its four fields locally:

```properties
storeFile=C:/Users/your-name/robocode-upload.jks
storePassword=your-private-store-password
keyAlias=upload
keyPassword=your-private-key-password
```

Use forward slashes in Windows paths. Relative paths resolve from `mobile-app/android`. This is a Java properties file: escape a literal backslash as `\\` in passwords/values. Keep passwords out of commands, chat and logs. Back up the keystore and credentials securely. `key.properties`, `*.jks` and `*.keystore` are excluded from Git; the empty example file is safe to commit.

Normal release builds fail when signing fields are missing, the keystore file is absent, or the standard `androiddebugkey` alias is selected. Android's signing task checks the key/password itself. The build never falls back to the debug signing configuration.

For Play distribution, distinguish the upload key from the app signing key managed through Play App Signing. For direct APK distribution, retain the same app signing identity for future updates. Complete store declarations using the app's actual behavior; no submission has been performed.

## Compile an unsigned release for verification

CI checks release compilation and shrinking without production secrets. In PowerShell, from `mobile-app`:

```powershell
$env:ROBOCODE_UNSIGNED_RELEASE = 'true'
try {
    flutter build apk --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed' }
    flutter build appbundle --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Release bundle build failed' }
} finally {
    Remove-Item Env:ROBOCODE_UNSIGNED_RELEASE -ErrorAction SilentlyContinue
}
python tool/verify_android_artifacts.py --build-tools "$env:LOCALAPPDATA/Android/Sdk/build-tools/36.0.0"
```

Only the exact value `true` enables unsigned mode. This mode ignores `key.properties` and produces unsigned outputs at `build/app/outputs/flutter-apk/app-release.apk` and `build/app/outputs/bundle/release/app-release.aab`. Neither output is ready to install or publish. An unsigned build does not validate the owner's signing credentials.

The verification script checks actual APK IDs, labels, SDK levels, debuggable state, required BLE support, absent Wi-Fi permissions and signing states. It also checks release APK ZIP alignment and unsigned bundle integrity. This is not a runtime, native-library page-size, radio or hardware acceptance test. CI retains only the supervised-test debug APK; unsigned artifacts are not uploaded.

## Build for distribution after acceptance

Local validation on 8 October 2026: the updated debug APK, unsigned release APK and unsigned AAB built successfully. The artifact checks passed, and missing release signing configuration was rejected. The earlier app-scope checkpoint passed 75 Flutter tests with no analysis errors/warnings. No physical installation, signed release build or remote CI run was performed in this packaging update.

1. Finish physical phone/robot acceptance and preserve the results.
2. Configure and back up the owner's private key. Ensure `ROBOCODE_UNSIGNED_RELEASE` is unset.
3. Set the intended version/build number in `pubspec.yaml`.
4. Run `flutter build appbundle --release --no-pub` for Play, or `flutter build apk --release --no-pub` for direct APK testing/distribution.
5. Verify the APK with `apksigner verify --verbose --print-certs` or the AAB with `jarsigner -verify -verbose -certs`. Record the certificate fingerprint and compare it with the intended owner key.
6. Test the signed package and upgrade behavior on the intended phones before distribution. Keep an offline backup of the signing material, released package, matching firmware, version and test record.

Do not apply the unsigned-artifact verification script to a signed distribution build; it intentionally rejects a signed release artifact in the unsigned CI check.
