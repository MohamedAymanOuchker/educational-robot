#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>

// Command structure for BLE communication
struct Command {
  char type;    // F,B,L,R,S,A,C,K (Forward,Backward,Left,Right,Stop,Auto,Calibrate,closed-loop)
  int value;    // Parameter value (distance in cm, angle in degrees)
  uint16_t id; // 0 is reserved for unnumbered manual commands
  uint32_t generation; // STOP invalidates all earlier queued/dequeued work
  Command(char kind = '?', int parameter = 0, uint16_t requestId = 0, uint32_t epoch = 0)
    : type(kind), value(parameter), id(requestId), generation(epoch) {}
};

enum class MotionResult { Done, Cancelled, Blocked, SensorInvalid, Timeout };

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
  bool distanceValid;
  unsigned long distanceTimestamp; // last successful range sample
  unsigned long distanceAgeMs;
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
