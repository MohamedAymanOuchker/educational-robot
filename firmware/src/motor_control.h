#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include "types.h"
#include "config.h"

class MotorControl {
private:
  int currentSpeed;
  // Set from the BLE task to abort an in-progress blocking move. volatile
  // because it is written and read from different FreeRTOS tasks/cores.
  volatile bool stopRequested;
  const float wheelCircumference;

  void stepMotor(int steps, int stepPin, int dirPin, bool direction);
  int distanceToSteps(int distanceCM);
  int angleToSteps(float degrees);

public:
  MotorControl();
  
  // Basic movement functions
  void moveForward(int distanceCM);
  void moveBackward(int distanceCM);
  void rotateLeft(float degrees);
  void rotateRight(float degrees);
  void rotateRobot(float degrees);
  
  // Advanced movement functions
  void moveForwardSteps(int steps);
  void moveBackwardSteps(int steps);
  
  // Control functions
  void stopMoving();
  void emergencyStop();
  void requestStop();        // ask an in-progress move to abort (non-blocking)
  void clearStop();          // re-arm motion for the next command
  bool isStopPending() const; // true while an abort is outstanding
  void setSpeed(int speed);
  int getSpeed() const;
  
  // Safety functions
  bool checkObstacle();
  void enableMotors();
  void disableMotors();
  
  // Initialization
  void begin();
};

// Global motor control instance
extern MotorControl motorController;

#endif // MOTOR_CONTROL_H