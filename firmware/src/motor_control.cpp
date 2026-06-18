#include "motor_control.h"
#include "sensor_manager.h"
#include <Arduino.h>
#include <cmath>
#include <Preferences.h>

// NVS namespace + key for the persisted motor speed
static const char* MOTOR_NAMESPACE = "motorcfg";
static const char* SPEED_KEY = "speed";

// Global instance
MotorControl motorController;

MotorControl::MotorControl()
  : currentSpeed(DEFAULT_SPEED),
    stopRequested(false),
    closedLoopEnabled(CLOSED_LOOP_TURN_DEFAULT),
    wheelCircumference(PI * WHEEL_DIAMETER) {
}

void MotorControl::begin() {
  // Initialize motor pins
  pinMode(LEFT_STEP_PIN, OUTPUT);
  pinMode(LEFT_DIR_PIN, OUTPUT);
  pinMode(RIGHT_STEP_PIN, OUTPUT);
  pinMode(RIGHT_DIR_PIN, OUTPUT);
  pinMode(LEFT_ENABLE_PIN, OUTPUT);
  pinMode(RIGHT_ENABLE_PIN, OUTPUT);
  
  // Enable motors by default
  enableMotors();

  // Restore a previously saved speed (falls back to DEFAULT_SPEED)
  Preferences prefs;
  if (prefs.begin(MOTOR_NAMESPACE, true)) {
    int savedSpeed = prefs.getInt(SPEED_KEY, DEFAULT_SPEED);
    prefs.end();
    if (savedSpeed >= 200 && savedSpeed <= 1000) {
      currentSpeed = savedSpeed;
      Serial.printf("Restored motor speed: %d us\n", currentSpeed);
    }
  }

  Serial.println("Motor control initialized");
}

void MotorControl::enableMotors() {
  digitalWrite(LEFT_ENABLE_PIN, LOW);   // LOW = enabled for most drivers
  digitalWrite(RIGHT_ENABLE_PIN, LOW);
}

void MotorControl::disableMotors() {
  digitalWrite(LEFT_ENABLE_PIN, HIGH);  // HIGH = disabled
  digitalWrite(RIGHT_ENABLE_PIN, HIGH);
}

int MotorControl::distanceToSteps(int distanceCM) {
  return (distanceCM * 10.0 / wheelCircumference) * STEPS_PER_REV;
}

int MotorControl::angleToSteps(float degrees) {
  float arc = (ROBOT_WIDTH * PI * abs(degrees)) / 360.0;
  return (arc / wheelCircumference) * STEPS_PER_REV;
}

void MotorControl::moveForward(int distanceCM) {
  int steps = distanceToSteps(distanceCM);
  moveForwardSteps(steps);
}

void MotorControl::moveForwardSteps(int steps) {
  Serial.printf("Moving forward %d steps\n", steps);

  for (int i = 0; i < steps; i++) {
    // Abort if a stop was requested mid-move
    if (stopRequested) {
      Serial.println("Move interrupted by stop request");
      break;
    }

    // Safety check every 50 steps
    if (i % 50 == 0) {
      if (sensorManager.getCurrentDistance() < CRITICAL_DISTANCE) {
        Serial.println("Emergency stop: Obstacle detected!");
        break;
      }
    }

    digitalWrite(LEFT_DIR_PIN, HIGH);
    digitalWrite(RIGHT_DIR_PIN, HIGH);
    
    digitalWrite(LEFT_STEP_PIN, HIGH);
    digitalWrite(RIGHT_STEP_PIN, HIGH);
    delayMicroseconds(currentSpeed);
    
    digitalWrite(LEFT_STEP_PIN, LOW);
    digitalWrite(RIGHT_STEP_PIN, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void MotorControl::moveBackward(int distanceCM) {
  int steps = distanceToSteps(distanceCM);
  moveBackwardSteps(steps);
}

void MotorControl::moveBackwardSteps(int steps) {
  Serial.printf("Moving backward %d steps\n", steps);
  
  digitalWrite(LEFT_DIR_PIN, LOW);
  digitalWrite(RIGHT_DIR_PIN, LOW);

  for (int i = 0; i < steps; i++) {
    // Abort if a stop was requested mid-move
    if (stopRequested) {
      Serial.println("Move interrupted by stop request");
      break;
    }

    digitalWrite(LEFT_STEP_PIN, HIGH);
    digitalWrite(RIGHT_STEP_PIN, HIGH);
    delayMicroseconds(currentSpeed);

    digitalWrite(LEFT_STEP_PIN, LOW);
    digitalWrite(RIGHT_STEP_PIN, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void MotorControl::rotateLeft(float degrees) {
  rotateRobot(-degrees); // Negative for left
}

void MotorControl::rotateRight(float degrees) {
  rotateRobot(degrees); // Positive for right
}

void MotorControl::rotateRobot(float degrees) {
  if (closedLoopEnabled) {
    rotateRobotClosedLoop(degrees);
    return;
  }

  int steps = angleToSteps(degrees);

  Serial.printf("Rotating %.1f degrees (%d steps)\n", degrees, steps);

  // Set direction pins
  digitalWrite(LEFT_DIR_PIN, degrees > 0 ? HIGH : LOW);
  digitalWrite(RIGHT_DIR_PIN, degrees > 0 ? LOW : HIGH);

  for (int i = 0; i < steps; i++) {
    // Abort if a stop was requested mid-turn
    if (stopRequested) {
      Serial.println("Rotation interrupted by stop request");
      break;
    }

    digitalWrite(LEFT_STEP_PIN, HIGH);
    digitalWrite(RIGHT_STEP_PIN, HIGH);
    delayMicroseconds(currentSpeed);

    digitalWrite(LEFT_STEP_PIN, LOW);
    digitalWrite(RIGHT_STEP_PIN, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void MotorControl::rotateRobotClosedLoop(float degrees) {
  // EXPERIMENTAL / UNVALIDATED ON HARDWARE.
  // Bang-bang controller: step toward an IMU yaw target until within
  // TURN_TOLERANCE_DEG. Reads fresh yaw via the thread-safe sampleYaw().
  float start = sensorManager.sampleYaw();
  float target = start + degrees;
  while (target >= 360.0) target -= 360.0;
  while (target < 0.0) target += 360.0;

  Serial.printf("Closed-loop turn %.1f deg (target heading %.1f)\n", degrees, target);

  unsigned long startMs = millis();

  while (!stopRequested && (millis() - startMs < TURN_TIMEOUT_MS)) {
    float yaw = sensorManager.sampleYaw();

    // Shortest signed error in [-180, 180]
    float error = target - yaw;
    while (error > 180.0) error -= 360.0;
    while (error < -180.0) error += 360.0;

    if (fabs(error) <= TURN_TOLERANCE_DEG) {
      break; // converged
    }

    // NOTE: the mapping of error sign to motor direction depends on how the
    // gyro and motors are wired; verify/flip on hardware if it turns the
    // wrong way. error > 0 => increase heading => turn right (degrees > 0).
    digitalWrite(LEFT_DIR_PIN, error > 0 ? HIGH : LOW);
    digitalWrite(RIGHT_DIR_PIN, error > 0 ? LOW : HIGH);

    for (int s = 0; s < TURN_STEP_BATCH && !stopRequested; s++) {
      digitalWrite(LEFT_STEP_PIN, HIGH);
      digitalWrite(RIGHT_STEP_PIN, HIGH);
      delayMicroseconds(currentSpeed);
      digitalWrite(LEFT_STEP_PIN, LOW);
      digitalWrite(RIGHT_STEP_PIN, LOW);
      delayMicroseconds(currentSpeed);
    }
  }

  if (millis() - startMs >= TURN_TIMEOUT_MS) {
    Serial.println("Closed-loop turn timed out before converging");
  }
}

void MotorControl::requestStop() {
  stopRequested = true;
}

void MotorControl::clearStop() {
  stopRequested = false;
}

bool MotorControl::isStopPending() const {
  return stopRequested;
}

void MotorControl::stopMoving() {
  Serial.println("Stopping motors");

  // Briefly disable then re-enable for immediate stop
  disableMotors();
  delay(10);
  enableMotors();

  // Movement has stopped; re-arm for the next command
  clearStop();
}

void MotorControl::emergencyStop() {
  Serial.println("EMERGENCY STOP!");
  disableMotors();
  delay(100);
  enableMotors();
  clearStop();
}

void MotorControl::setSpeed(int speed) {
  if (speed >= 200 && speed <= 1000) { // Safe speed range
    currentSpeed = speed;
    Serial.printf("Motor speed set to %d microseconds\n", speed);

    // Persist so the speed survives a reboot
    Preferences prefs;
    if (prefs.begin(MOTOR_NAMESPACE, false)) {
      prefs.putInt(SPEED_KEY, speed);
      prefs.end();
    }
  } else {
    Serial.println("Invalid speed value. Must be between 200-1000 microseconds");
  }
}

void MotorControl::setClosedLoop(bool enabled) {
  closedLoopEnabled = enabled;
  Serial.printf("Closed-loop turning %s\n", enabled ? "ENABLED (experimental)" : "disabled");
}

bool MotorControl::isClosedLoop() const {
  return closedLoopEnabled;
}

int MotorControl::getSpeed() const {
  return currentSpeed;
}

bool MotorControl::checkObstacle() {
  return sensorManager.getCurrentDistance() < MIN_OBSTACLE_DIST;
}