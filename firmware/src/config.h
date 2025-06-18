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
#define COMMAND_QUEUE_SIZE  10

// Timing Constants
#define SENSOR_UPDATE_RATE  1000    // milliseconds
#define IMU_UPDATE_RATE     10      // milliseconds
#define MOTOR_TASK_DELAY    10      // milliseconds

// Safety Limits
#define MAX_DISTANCE        999.0   // cm
#define ULTRASONIC_TIMEOUT  30000   // microseconds

#endif // CONFIG_H