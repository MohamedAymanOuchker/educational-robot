# RoboCode Mobile App

A Flutter-based mobile application for programming and controlling educational robots using visual block-based coding. This app is part of the Educational Robot project, designed to make robotics and programming accessible to learners.

## Features

- 🎯 Visual Block-Based Programming Interface
- 🤖 Bluetooth connectivity with educational robots
- 📱 User-friendly interface with multiple screens:
  - Home Screen: Main navigation and project overview
  - Connect Screen: Robot connection management
  - Code Screen: Block-based programming interface
  - Run Screen: Program execution and robot control
  - Sensors Screen: Real-time sensor data monitoring

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

- Flutter SDK (2.17.0 or higher)
- Android Studio / Xcode
- A compatible educational robot

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repository/educational-robot.git
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

The app is structured into several key directories:

- `lib/screens/`: Main application screens
- `lib/services/`: Business logic and state management
- `lib/widgets/`: Reusable UI components
  - `block_editor/`: Custom widgets for the visual programming interface

## Contributing

Please read the CONTRIBUTING.md file in the root directory for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the terms found in the LICENSE file in the root directory.