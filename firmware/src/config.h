#ifndef CONFIG_H
#define CONFIG_H

// BLE Configuration
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define COMMAND_CHAR_UUID   "12345678-1234-1234-1234-123456789abd"
#define SENSOR_CHAR_UUID    "12345678-1234-1234-1234-123456789abe"
#define BLE_DEVICE_NAME     "E-Bug ESP32"

// Pin Definitions
#define TRIG_PIN            5
#define ECHO_PIN            18
#define LEFT_STEP_PIN       26
#define LEFT_DIR_PIN        27
#define RIGHT_STEP_PIN      14
#define RIGHT_DIR_PIN       12
#define LEFT_ENABLE_PIN     25
#define RIGHT_ENABLE_PIN    13
#define SDA_PIN             21
#define SCL_PIN             22

// Motor Configuration
#define STEPS_PER_REV       200
#define WHEEL_DIAMETER      65      // mm
#define ROBOT_WIDTH         150     // mm
#define DEFAULT_SPEED       400     // microseconds

// Command Limits (clamp incoming BLE parameters to safe ranges)
#define MAX_MOVE_DISTANCE_CM    500     // reject runaway forward/backward moves
#define MAX_TURN_ANGLE          360     // degrees

// Navigation Constants
#define MIN_OBSTACLE_DIST   25      // cm
#define CRITICAL_DISTANCE   15      // cm
#define SCAN_ANGLE_START    -60     // degrees
#define SCAN_ANGLE_END      60      // degrees
#define SCAN_ANGLE_STEP     10      // degrees
#define PATH_MEMORY_SIZE    10

// Task Configuration
#define MOTOR_TASK_STACK    10000
#define SENSOR_TASK_STACK   10000
#define COMM_TASK_STACK     4096
#define COMMAND_QUEUE_SIZE  10

// Timing Constants
#define SENSOR_UPDATE_RATE  1000    // milliseconds
#define IMU_UPDATE_RATE     10      // milliseconds
#define MOTOR_TASK_DELAY    10      // milliseconds

// Safety Limits
#define MAX_DISTANCE        999.0   // cm
#define ULTRASONIC_TIMEOUT  30000   // microseconds

// Battery Monitoring
// NOTE: Wire the battery through a resistor divider into an ADC1 pin.
// ADC2 pins cannot be used while BLE/Wi-Fi is active. GPIO 34-39 are
// input-only and ideal for analog sensing. Adjust the divider ratio and
// the voltage range to match your pack (defaults: 2S Li-Po, /3 divider).
#define BATTERY_PIN             35      // ADC1_CH7 (input-only, BLE-safe)
#define BATTERY_DIVIDER_RATIO   3.0     // (R1 + R2) / R2 of the divider
#define BATTERY_MAX_VOLTAGE     8.4     // fully charged (2S = 4.2V/cell)
#define BATTERY_MIN_VOLTAGE     6.0     // empty (2S = 3.0V/cell)

#endif // CONFIG_H