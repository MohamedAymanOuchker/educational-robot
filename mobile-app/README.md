# RoboCode Mobile App

A Flutter-based mobile application for programming and controlling educational robots using visual block-based coding. This app is part of the Educational Robot project, designed to make robotics and programming accessible to learners.

The P1 revision requires the matching [firmware protocol](../docs/ble-protocol.md) and [28BYJ-48 / ULN2003 wiring](../hardware/wiring.md). Android is the current build target; iOS support and store releases are not validated.

## Features

- 🎯 Visual Block-Based Programming Interface
- 🤖 Bluetooth connectivity with educational robots
- 💾 Named local Save/Open with nested block and parameter restoration
- ✅ Five practice checks based on successful execution, separate from saving
- 📱 User-friendly interface with multiple screens:
  - Home Screen: Main navigation and project overview
  - Connect Screen: Bluetooth scan, connection and disconnection
  - Code Screen: Block-based programming interface
  - Sensors Screen: Automatically pushed readings with unavailable/stale states
- Run opens Robot Execution from Code; there is no placeholder Run tab

## Technical Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Key Dependencies**:
  - `flutter_blue_plus`: Bluetooth communication
  - `flutter_inappwebview`: Web-based components
  - `provider`: State management
  - `shared_preferences`: Local data storage
  - `google_fonts`: Typography
  - `lottie`: Animations

## Getting Started

### Prerequisites

- Flutter 3.41.4 / Dart 3.11.1 (the validation and CI toolchain)
- Android SDK and a compatible Java installation (CI uses Java 17)
- Android device with Bluetooth Low Energy and the matching updated ESP32 firmware

Android packaging uses Gradle 8.14, Android Gradle Plugin 8.11.1 and Kotlin 2.2.20. See the [Android release guide](../docs/android-release.md) for the selected application ID, separate test installation, private signing setup and unsigned CI build checks. Normal release builds require an owner-provided key; debug signing is never used as a release fallback.

### Installation

1. Open the cloned project's app directory:
   ```bash
   cd educational-robot/mobile-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Development

Run the regression checks and create an Android test package:

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

The tests cover protocol framing/completion, typed program execution and block editor behavior. Hardware connection, motor direction, stop latency and sensor behavior still require an actual robot. See [P1 status](../docs/p1-status.md) for validation results and open items.

Programs execute the edited block tree and wait for firmware completion records. Generated Dart is a preview only. If Distance uses fresh valid telemetry; its children are skipped when false. Auto Navigate runs for three seconds and stops. Leaving the execution screen or backgrounding the app cancels the run and requests STOP.

Use **Save** and **Open** in Code for a local library (up to 50 programs, 100 blocks each). Names are case-insensitive; replacement and clearing require confirmation. Unsaved edits survive tab switches, but must be saved before closing the app. No file export or cloud backup is implemented.

The connection UI supports **Bluetooth Low Energy only**. Scans filter for the robot service, report permission/adapter errors, stop after about ten seconds and cancel their native scan when the screen's subscription ends. The unused Wi-Fi UI, password form, service stubs, plugin and Wi-Fi permissions have been removed. Android permission behavior still needs physical-device testing.

The editor now reads a typed list of implemented blocks for each lesson. Home and Code use the same lesson names/descriptions; the [current curriculum](../docs/curriculum-guide.md) teaches explicit movement sequences, Wait, one-sided distance decisions and bounded Auto Navigate. Repeat/While, If/Else, speed controls, mapping, localization and iOS release support are not implemented.

Sensors automatically displays new telemetry. It clears missing/invalid fields and expired/disconnected readings instead of showing default values or carrying old readings into a new packet. Distance freshness includes the firmware's reported age. Battery is an estimate; IMU temperature and relative heading are not a room thermometer or compass. No monitoring Start/Stop buttons or movement controls appear in Sensors.

Practice checks are based on executed nonzero actions, conditional responses and successful final STOP. Save never awards progress. Old badge data retains lesson access without counting as verified execution; cached robot connection flags are ignored. See [P2 status](../docs/p2-status.md) for the storage format, migration, checks and remaining work.

The app is structured into several key directories:

- `lib/screens/`: Main application screens
- `lib/services/`: Business logic and state management
- `lib/widgets/`: Reusable UI components
  - `block_editor/`: Custom widgets for the visual programming interface

## Contributing

Please read the CONTRIBUTING.md file in the root directory for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the terms found in the LICENSE file in the root directory.
