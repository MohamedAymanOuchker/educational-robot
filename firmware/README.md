# E-Bug Robot Firmware

ESP32-based firmware for the educational robot platform with advanced autonomy and BLE control.

## 🛠️ Development Setup

### Prerequisites
- [PlatformIO](https://platformio.org/) or Arduino IDE
- ESP32 development board
- Required components:
  - MPU6050 IMU
  - HC-SR04 ultrasonic sensor
  - 2x stepper motors (28BYJ-48) with drivers
  - Jumper wires

### Pin Configuration
| Component | Pin | Description |
|-----------|-----|-------------|
| HC-SR04 | TRIG_PIN (5) | Ultrasonic trigger |
| HC-SR04 | ECHO_PIN (18) | Ultrasonic echo |
| Left Motor | STEP_PIN (26) | Step control |
| Left Motor | DIR_PIN (27) | Direction control |
| Right Motor | STEP_PIN (14) | Step control |
| Right Motor | DIR_PIN (12) | Direction control |
| Motors | EN_PIN_L (25), EN_PIN_R (13) | Enable pins |
| MPU6050 | SDA (21), SCL (22) | I2C bus |

## 📁 Project Structure

```
firmware/
├── arduino_main.ino     # Legacy Arduino sketch
├── platformio.ini       # PlatformIO config
└── src/
    ├── main.cpp        # Main program entry
    ├── config.h        # Configuration & pins
    ├── types.h         # Data structures
    ├── ble_communication.*  # BLE handling
    ├── motor_control.*      # Motor functions
    ├── navigation.*         # Path planning
    └── sensor_manager.*     # Sensor interface
```

## ⚙️ Building & Uploading

Using PlatformIO:
```bash
# Build project
pio run

# Upload to ESP32
pio run --target upload

# Monitor serial output
pio device monitor
```

Using Arduino IDE:
1. Open arduino_main.ino
2. Select "ESP32 Dev Module" board
3. Set upload speed to 921600
4. Click Upload

## 🌟 Features

- **BLE Communication**
  - Custom service UUID: `12345678-1234-1234-1234-123456789abc`
  - Command characteristic for control
  - Sensor characteristic for telemetry

- **Motor Control**
  - Precise stepper motor control
  - Forward/backward movement
  - Left/right rotation
  - Emergency stop functionality

- **Autonomous Navigation**
  - Enhanced E-Bug algorithm
  - Obstacle avoidance
  - Path memory system
  - Dead-end detection

- **Sensor Integration**
  - Distance measurement
  - Orientation tracking
  - Real-time telemetry
  - Filtered readings

## 🤖 Command Protocol

Commands are sent via BLE in the format: `<TYPE><VALUE>`

| Type | Description | Example |
|------|-------------|---------|
| F | Forward (cm) | `F20` |
| B | Backward (cm) | `B15` |
| L | Left turn (degrees) | `L90` |
| R | Right turn (degrees) | `R45` |
| S | Stop | `STOP` |
| A | Auto mode | `AUTO_NAV` |

## 📊 Telemetry Data

JSON format:
```json
{
  "distance": 45.2,    // cm
  "battery": 95.0,     // percentage
  "temperature": 25.3, // celsius
  "heading": 182.5     // degrees
}
```

## 🔧 Configuration

Key parameters in config.h:
```cpp
#define MIN_OBSTACLE_DIST   25  // cm
#define CRITICAL_DISTANCE   15  // cm
#define STEPS_PER_REV      200
#define WHEEL_DIAMETER     65   // mm
#define ROBOT_WIDTH       150   // mm
```

## 🐛 Debugging

1. Enable debug output in platformio.ini:
```ini
build_flags = 
    -DCORE_DEBUG_LEVEL=3
```

2. Monitor serial output at 115200 baud
3. Check status messages and sensor readings

## 📝 Contributing

1. Fork the repository
2. Create feature branch
3. Follow coding standards
4. Test thoroughly
5. Submit pull request

## 📄 License

MIT License - See LICENSE for details.

## 👥 Authors

- Mohamed Ayman OUCHKER - Main development

For questions: ayman.ouchker@outlook.com