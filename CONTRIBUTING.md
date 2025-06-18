# Contributing to Educational Robot

First off, thank you for considering contributing to this educational robotics project! 🎉

## 🎯 Project Mission

This project aims to democratize robotics education by providing an affordable, accessible platform for teaching programming to children aged 7-12. All contributions should align with this educational mission.

## 🤝 How to Contribute

### Reporting Bugs 🐛

Before creating bug reports, please check existing issues to avoid duplicates.

**Bug Report Template:**
```
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- Hardware version: [e.g., ESP32-WROOM-32]
- Firmware version: [e.g., v1.0.0]
- Mobile app version: [e.g., v1.0.0]
- Device: [e.g., Samsung Galaxy S20]
- OS: [e.g., Android 11]

**Additional context**
Add any other context about the problem here.
```

### Suggesting Enhancements 💡

Enhancement suggestions are welcome! Please provide:

- **Clear description** of the enhancement
- **Educational value** - How does this improve learning?
- **Implementation ideas** if you have them
- **Alternatives considered**

### Code Contributions 💻

#### Development Setup

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/your-username/educational-robot-esp32.git
   cd educational-robot-esp32
   ```

3. **Set up development environment:**

   **For Firmware:**
   ```bash
   # Install PlatformIO
   pip install platformio
   cd firmware/
   pio run
   ```

   **For Mobile App:**
   ```bash
   # Install Flutter
   cd mobile-app/
   flutter pub get
   flutter run
   ```

#### Coding Standards

**Firmware (C++):**
- Use 2 spaces for indentation
- Follow Arduino coding style
- Comment complex algorithms
- Keep functions under 50 lines when possible
- Use descriptive variable names

```cpp
// Good
void calculateMotorSteps(int distanceCM) {
  int steps = (distanceCM * 10.0 / wheelCircumference) * stepsPerRev;
  // Implementation...
}

// Avoid
void calc(int d) {
  int s = (d * 10.0 / wc) * spr;
  // Implementation...
}
```

**Mobile App (Dart/Flutter):**
- Use 2 spaces for indentation
- Follow Dart style guide
- Use meaningful widget names
- Implement proper error handling
- Add comments for complex UI logic

```dart
// Good
class ProgrammingBlockWidget extends StatelessWidget {
  final BlockModel block;
  final VoidCallback onTap;
  
  const ProgrammingBlockWidget({
    Key? key,
    required this.block,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Implementation...
  }
}
```

#### Commit Guidelines

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(firmware): add emergency stop functionality
fix(app): resolve BLE connection timeout issue
docs(hardware): update assembly guide with new images
```

#### Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following coding standards

3. **Test thoroughly:**
   - Hardware: Test on actual ESP32
   - Software: Test on different devices
   - Educational: Consider impact on learning

4. **Update documentation** if needed

5. **Create pull request** with:
   - Clear title and description
   - Link to related issues
   - Screenshots/videos if UI changes
   - Testing instructions

6. **Respond to feedback** from maintainers

## 🎓 Educational Contributions

### Curriculum Development

We need help creating educational materials:

- **Lesson plans** for different age groups
- **Activity worksheets** for hands-on learning
- **Assessment rubrics** for teachers
- **Video tutorials** for setup and usage

### Translation

Help make this accessible globally:

- **App interface** translation
- **Documentation** translation
- **Curriculum materials** localization

### User Testing

Help us improve the educational experience:

- **Test with children** in your community
- **Gather teacher feedback**
- **Document learning outcomes**
- **Report usability issues**

## 🏗️ Hardware Contributions

### CAD Improvements

- **Optimize designs** for easier printing
- **Create variations** for different printers
- **Improve assembly** process
- **Add customization** options

### Electronics

- **PCB design** for easier assembly
- **Component alternatives** for different regions
- **Power optimization** improvements
- **Sensor additions** or upgrades

## 📋 Contribution Areas

### High Priority
- [ ] iOS app development
- [ ] Arabic/French translation
- [ ] Teacher training materials
- [ ] Assembly video tutorials
- [ ] Classroom management guide

### Medium Priority
- [ ] Advanced programming blocks
- [ ] Multi-robot coordination
- [ ] Cloud synchronization
- [ ] Performance optimizations
- [ ] Additional sensors support

### Future Ideas
- [ ] AR/VR integration
- [ ] AI-powered personalization
- [ ] Multiplayer challenges
- [ ] Advanced robotics concepts
- [ ] Integration with school curricula

## 🎖️ Recognition

Contributors will be recognized in:
- README.md contributors section
- Project documentation
- Release notes
- Academic publications (with permission)

## 📞 Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Email**: ayman.ouchker@outlook.com for private concerns

## 📋 Code of Conduct

### Our Pledge

We are committed to making participation in this project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes:**
- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the project maintainers. All complaints will be reviewed and investigated promptly and fairly.

## 🙏 Thank You

Every contribution, no matter how small, helps make quality robotics education more accessible to children worldwide. Thank you for being part of this mission!

---

**Happy Contributing!** 🤖📚
