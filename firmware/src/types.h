#ifndef TYPES_H
#define TYPES_H

// Command structure for BLE communication
struct Command {
  char type;    // F, B, L, R, S (Forward, Backward, Left, Right, Stop)
  int value;    // Parameter value (distance in cm, angle in degrees)
};

// Robot state enumeration
enum RobotState {
  IDLE,
  MOVING_FORWARD,
  MOVING_BACKWARD,
  TURNING_LEFT,
  TURNING_RIGHT,
  SCANNING,
  AUTONOMOUS
};

// Sensor data structure
struct SensorData {
  float distance;       // cm
  float heading;        // degrees
  float temperature;    // celsius
  float batteryLevel;   // percentage
  unsigned long timestamp;
};

// Path memory entry
struct PathMemoryEntry {
  float distance;
  float angle;
  unsigned long timestamp;
};

// Motor parameters
struct MotorParams {
  int speed;            // microseconds delay
  bool enableLeft;
  bool enableRight;
};

#endif // TYPES_H