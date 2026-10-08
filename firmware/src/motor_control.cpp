#include "motor_control.h"
#include "sensor_manager.h"
#include <cmath>
#include <freertos/task.h>

MotorControl motorController;

namespace {
const int leftPins[] = {LEFT_IN1_PIN, LEFT_IN2_PIN, LEFT_IN3_PIN, LEFT_IN4_PIN};
const int rightPins[] = {RIGHT_IN1_PIN, RIGHT_IN2_PIN, RIGHT_IN3_PIN, RIGHT_IN4_PIN};
// Standard 28BYJ-48 half-step sequence, wired in ULN2003 IN1..IN4 order.
const uint8_t phases[8][4] = {
  {1,0,0,0}, {1,1,0,0}, {0,1,0,0}, {0,1,1,0},
  {0,0,1,0}, {0,0,1,1}, {0,0,0,1}, {1,0,0,1}
};
}

MotorControl::MotorControl() : currentSpeed(DEFAULT_SPEED), stopRequested(true),
  generation(0), leftPhase(0), rightPhase(0), wheelCircumference(PI * WHEEL_DIAMETER) {}

void MotorControl::begin() {
  for (int pin : leftPins) pinMode(pin, OUTPUT);
  for (int pin : rightPins) pinMode(pin, OUTPUT);
  releaseCoils(); // no holding current or movement until an explicit command
}

int MotorControl::distanceToSteps(int distanceCM) {
  return static_cast<int>(lround((distanceCM * 10.0 / wheelCircumference) * STEPS_PER_REV));
}

int MotorControl::angleToSteps(float degrees) {
  const float arc = (ROBOT_WIDTH * PI * fabs(degrees)) / 360.0;
  return static_cast<int>(lround((arc / wheelCircumference) * STEPS_PER_REV));
}

bool MotorControl::stepPair(int leftDirection, int rightDirection) {
  portENTER_CRITICAL(&motionMux);
  if (stopRequested) {
    portEXIT_CRITICAL(&motionMux);
    return false;
  }
  leftPhase = (leftPhase + (LEFT_MOTOR_INVERT ? -leftDirection : leftDirection) + 8) % 8;
  rightPhase = (rightPhase + (RIGHT_MOTOR_INVERT ? -rightDirection : rightDirection) + 8) % 8;
  for (int i = 0; i < 4; ++i) {
    digitalWrite(leftPins[i], phases[leftPhase][i]);
    digitalWrite(rightPins[i], phases[rightPhase][i]);
  }
  portEXIT_CRITICAL(&motionMux);
  return true;
}

MotionResult MotorControl::runSteps(int steps, int leftDirection, int rightDirection, bool checkFront) {
  MotionResult result = MotionResult::Done;
  for (int i = 0; i < steps; ++i) {
    if (isStopPending()) { result = MotionResult::Cancelled; break; }
    // Read a coherent snapshot on every half-step. Rear/side clearance needs supervision.
    if (checkFront) {
      const SensorData data = sensorManager.getSensorData();
      if (!data.distanceValid) { result = MotionResult::SensorInvalid; break; }
      if (data.distance < CRITICAL_DISTANCE) { result = MotionResult::Blocked; break; }
    }
    if (!stepPair(leftDirection, rightDirection)) { result = MotionResult::Cancelled; break; }
    // Yield on every step so long movements do not starve idle/watchdog tasks.
    const TickType_t ticks = pdMS_TO_TICKS((currentSpeed + 999) / 1000);
    vTaskDelay(ticks > 0 ? ticks : 1);
  }
  releaseCoils();
  if (isStopPending()) return MotionResult::Cancelled;
  return result;
}

MotionResult MotorControl::moveForward(int cm) { return moveForwardSteps(distanceToSteps(cm)); }
MotionResult MotorControl::moveBackward(int cm) { return moveBackwardSteps(distanceToSteps(cm)); }
MotionResult MotorControl::moveForwardSteps(int steps) { return runSteps(steps, 1, 1, true); }
MotionResult MotorControl::moveBackwardSteps(int steps) { return runSteps(steps, -1, -1, false); }
MotionResult MotorControl::rotateLeft(float degrees) { return rotateRobot(-degrees); }
MotionResult MotorControl::rotateRight(float degrees) { return rotateRobot(degrees); }
MotionResult MotorControl::rotateRobot(float degrees) {
  return runSteps(angleToSteps(degrees), degrees >= 0 ? 1 : -1, degrees >= 0 ? -1 : 1, false);
}

void MotorControl::releaseCoilsUnlocked() {
  for (int pin : leftPins) digitalWrite(pin, LOW);
  for (int pin : rightPins) digitalWrite(pin, LOW);
}
void MotorControl::releaseCoils() {
  portENTER_CRITICAL(&motionMux);
  releaseCoilsUnlocked();
  portEXIT_CRITICAL(&motionMux);
}
void MotorControl::requestStop() {
  portENTER_CRITICAL(&motionMux);
  stopRequested = true;
  ++generation;
  releaseCoilsUnlocked();
  portEXIT_CRITICAL(&motionMux);
}
bool MotorControl::arm(uint32_t expectedGeneration) {
  portENTER_CRITICAL(&motionMux);
  const bool allowed = expectedGeneration == generation;
  if (allowed) stopRequested = false;
  portEXIT_CRITICAL(&motionMux);
  return allowed;
}
uint32_t MotorControl::getGeneration() const {
  portENTER_CRITICAL(&motionMux);
  uint32_t result = generation;
  portEXIT_CRITICAL(&motionMux);
  return result;
}
bool MotorControl::isStopPending() const {
  portENTER_CRITICAL(&motionMux);
  bool result = stopRequested;
  portEXIT_CRITICAL(&motionMux);
  return result;
}
void MotorControl::stopMoving() { requestStop(); }
void MotorControl::emergencyStop() { requestStop(); }
void MotorControl::setSpeed(int intervalUs) {
  if (intervalUs >= 2000 && intervalUs <= 10000) currentSpeed = intervalUs;
}
int MotorControl::getSpeed() const { return currentSpeed; }
bool MotorControl::checkObstacle() {
  const SensorData data = sensorManager.getSensorData();
  return !data.distanceValid || data.distance < MIN_OBSTACLE_DIST;
}
