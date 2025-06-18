#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include "types.h"
#include "config.h"

class MotorControl {
private:
  int currentSpeed;
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