#include "motor_control.h"
#include "sensor_manager.h"
#include <Arduino.h>
#include <cmath>

// Global instance
MotorControl motorController;

MotorControl::MotorControl() 
  : currentSpeed(DEFAULT_SPEED), 
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

void MotorControl::stepMotor(int steps, int stepPin, int dirPin, bool direction) {
  digitalWrite(dirPin, direction);
  
  for (int i = 0; i < steps; i++) {
    // Safety check every 50 steps during forward movement
    if (i % 50 == 0 && stepPin == LEFT_STEP_PIN && direction == HIGH) {
      if (sensorManager.getCurrentDistance() < CRITICAL_DISTANCE) {
        Serial.println("Emergency stop: Obstacle detected!");
        break;
      }
    }
    
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(currentSpeed);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void MotorControl::moveForward(int distanceCM) {
  int steps = distanceToSteps(distanceCM);
  moveForwardSteps(steps);
}

void MotorControl::moveForwardSteps(int steps) {
  Serial.printf("Moving forward %d steps\n", steps);
  
  for (int i = 0; i < steps; i++) {
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
  int steps = angleToSteps(degrees);
  
  Serial.printf("Rotating %.1f degrees (%d steps)\n", degrees, steps);
  
  // Set direction pins
  digitalWrite(LEFT_DIR_PIN, degrees > 0 ? HIGH : LOW);
  digitalWrite(RIGHT_DIR_PIN, degrees > 0 ? LOW : HIGH);
  
  for (int i = 0; i < steps; i++) {
    digitalWrite(LEFT_STEP_PIN, HIGH);
    digitalWrite(RIGHT_STEP_PIN, HIGH);
    delayMicroseconds(currentSpeed);
    
    digitalWrite(LEFT_STEP_PIN, LOW);
    digitalWrite(RIGHT_STEP_PIN, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void MotorControl::stopMoving() {
  Serial.println("Stopping motors");
  
  // Briefly disable then re-enable for immediate stop
  disableMotors();
  delay(10);
  enableMotors();
}

void MotorControl::emergencyStop() {
  Serial.println("EMERGENCY STOP!");
  disableMotors();
  delay(100);
  enableMotors();
}

void MotorControl::setSpeed(int speed) {
  if (speed >= 200 && speed <= 1000) { // Safe speed range
    currentSpeed = speed;
    Serial.printf("Motor speed set to %d microseconds\n", speed);
  } else {
    Serial.println("Invalid speed value. Must be between 200-1000 microseconds");
  }
}

int MotorControl::getSpeed() const {
  return currentSpeed;
}

bool MotorControl::checkObstacle() {
  return sensorManager.getCurrentDistance() < MIN_OBSTACLE_DIST;
}