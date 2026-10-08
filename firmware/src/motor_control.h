#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include "types.h"
#include "config.h"

class MotorControl {
private:
  int currentSpeed;
  // Gate, generation and coil writes share one critical section across cores.
  mutable portMUX_TYPE motionMux = portMUX_INITIALIZER_UNLOCKED;
  bool stopRequested;
  uint32_t generation;
  int leftPhase;
  int rightPhase;
  const float wheelCircumference;
  int distanceToSteps(int distanceCM);
  int angleToSteps(float degrees);
  bool stepPair(int leftDirection, int rightDirection);
  MotionResult runSteps(int steps, int leftDirection, int rightDirection, bool checkFront);
  void releaseCoilsUnlocked();

public:
  MotorControl();
  MotionResult moveForward(int distanceCM);
  MotionResult moveBackward(int distanceCM);
  MotionResult rotateLeft(float degrees);
  MotionResult rotateRight(float degrees);
  MotionResult rotateRobot(float degrees);
  MotionResult moveForwardSteps(int steps);
  MotionResult moveBackwardSteps(int steps);
  void stopMoving();
  void emergencyStop();
  void requestStop();
  bool arm(uint32_t expectedGeneration);
  uint32_t getGeneration() const;
  bool isStopPending() const;
  void setSpeed(int speed);
  int getSpeed() const;
  bool checkObstacle();
  void releaseCoils();
  void begin();
};

extern MotorControl motorController;
#endif
