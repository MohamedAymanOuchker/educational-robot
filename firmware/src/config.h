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
// 28BYJ-48 motors through ULN2003 IN1..IN4 (rewire the old STEP/DIR layout).
#define LEFT_IN1_PIN        26
#define LEFT_IN2_PIN        27
#define LEFT_IN3_PIN        25
#define LEFT_IN4_PIN        33
#define RIGHT_IN1_PIN       14
#define RIGHT_IN2_PIN       13
#define RIGHT_IN3_PIN       32
#define RIGHT_IN4_PIN       23
#define SDA_PIN             21
#define SCL_PIN             22

// Motor Configuration: selected 5 V, nominal 1:64 28BYJ-48 + ULN2003.
// Voltage is set by hardware, not firmware. See hardware/power-system.md.
#define STEPS_PER_REV       4096    // nominal half-steps; calibrate the actual gearbox
#define WHEEL_DIAMETER      65      // mm
#define ROBOT_WIDTH         150     // mm
#define HALF_STEP_INTERVAL_US 2000  // conservative 500 half-steps/s
#define DEFAULT_SPEED       HALF_STEP_INTERVAL_US
#define LEFT_MOTOR_INVERT   false   // verify forward direction with wheels raised
#define RIGHT_MOTOR_INVERT  true    // mirrored mounting; verify on hardware

// Command limits (reject out-of-range values, never clamp).
#define MAX_MOVE_DISTANCE_CM    500     // reject runaway forward/backward moves
#define MAX_TURN_ANGLE          360     // degrees

// P1 uses open-loop half-step counting. Runtime CLOOP_ON is explicitly rejected
// until IMU turn-direction, calibration and convergence are validated on hardware.

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
#define SENSOR_UPDATE_RATE  60      // ultrasonic trigger period, milliseconds
#define TELEMETRY_UPDATE_RATE 250   // independent of safety sampling
#define DISTANCE_MAX_AGE_MS  250     // older samples cannot authorize forward motion
#define IMU_UPDATE_RATE     10      // milliseconds
#define MOTOR_TASK_DELAY    10      // milliseconds

// Safety Limits
#define ULTRASONIC_TIMEOUT  30000   // microseconds

// Battery Monitoring
// NOTE: Wire the battery through a resistor divider into an ADC1 pin.
// ADC2 pins cannot be used while BLE/Wi-Fi is active. GPIO 34-39 are
// input-only and ideal for analog sensing. Selected pack: Tenergy 31003,
// protected 2S Li-ion, 2200mAh, /3 divider (hardware/power-system.md).
// These endpoints only scale telemetry; they do not provide a low-voltage cutoff.
#define BATTERY_PIN             35      // ADC1_CH7 (input-only, BLE-safe)
#define BATTERY_DIVIDER_RATIO   3.0     // (R1 + R2) / R2 of the divider
#define BATTERY_MAX_VOLTAGE     8.4     // fully charged (2S = 4.2V/cell)
#define BATTERY_MIN_VOLTAGE     6.0     // specified pack endpoint; recharge earlier

#endif // CONFIG_H
