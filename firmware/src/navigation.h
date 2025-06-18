#include "navigation.h"
#include "motor_control.h"
#include "sensor_manager.h"
#include <Arduino.h>
#include <cmath>

// Global instance
Navigation navigator;

Navigation::Navigation() 
  : isAutonomousMode(false),
    pathIndex(0),
    lastNavigationUpdate(0),
    lastBestAngle(0),
    stuckCounter(0) {
  
  // Initialize path memory
  clearPathMemory();
}

void Navigation::begin() {
  clearPathMemory();
  isAutonomousMode = false;
  stuckCounter = 0;
  Serial.println("Navigation system initialized");
}

void Navigation::enableAutonomousMode() {
  isAutonomousMode = true;
  clearPathMemory();
  stuckCounter = 0;
  lastNavigationUpdate = millis();
  Serial.println("Autonomous navigation enabled");
}

void Navigation::disableAutonomousMode() {
  isAutonomousMode = false;
  motorController.stopMoving();
  Serial.println("Autonomous navigation disabled");
}

bool Navigation::isAutonomous() const {
  return isAutonomousMode;
}

void Navigation::executeAutonomousStep() {
  if (!isAutonomousMode) return;
  
  // Rate limiting - update every 500ms
  if (millis() - lastNavigationUpdate < 500) {
    return;
  }
  lastNavigationUpdate = millis();
  
  float currentDistance = sensorManager.getCurrentDistance();
  
  // Emergency reverse if too close
  if (currentDistance < CRITICAL_DISTANCE) {
    Serial.println("Emergency maneuver: Too close to obstacle");
    emergencyManeuver();
    return;
  }
  
  // Continue forward if path is clear
  if (currentDistance > MIN_OBSTACLE_DIST * 2) {
    motorController.moveForward(10); // Small forward step
    stuckCounter = 0; // Reset stuck counter
    return;
  }
  
  // Obstacle detected - find new path
  if (currentDistance < MIN_OBSTACLE_DIST) {
    float bestAngle = findBestPath();
    
    if (bestAngle != -999) {
      Serial.printf("Turning to best angle: %.1f degrees\n", bestAngle);
      motorController.rotateRobot(bestAngle);
      lastBestAngle = bestAngle;
      stuckCounter = 0;
    } else {
      // No good path found
      stuckCounter++;
      if (stuckCounter > 3) {
        avoidStuckSituation();
      }
    }
  }
}

float Navigation::findBestPath() {
  float bestScore = 0;
  float bestAngle = -999; // Invalid angle indicates no good path
  
  Serial.println("Scanning for best path...");
  
  // Scan from left to right
  for (int angle = SCAN_ANGLE_START; angle <= SCAN_ANGLE_END; angle += SCAN_ANGLE_STEP) {
    // Turn to scan angle
    motorController.rotateRobot(angle);
    delay(100); // Stabilization time
    
    // Take multiple readings for accuracy
    float totalDistance = 0;
    int validReadings = 0;
    
    for (int i = 0; i < 3; i++) {
      float distance = sensorManager.readDistanceCM();
      if (distance < MAX_DISTANCE) {
        totalDistance += distance;
        validReadings++;
      }
      delay(50);
    }
    
    if (validReadings == 0) continue;
    
    float avgDistance = totalDistance / validReadings;
    float score = calculateScore(avgDistance, angle);
    
    Serial.printf("Angle: %d°, Distance: %.1f cm, Score: %.2f\n", 
                  angle, avgDistance, score);
    
    if (score > bestScore) {
      bestScore = score;
      bestAngle = angle;
    }
    
    // Update path memory
    updatePathMemory(avgDistance, angle);
  }
  
  // Return to original position
  motorController.rotateRobot(SCAN_ANGLE_START * -1); // Return to center
  
  Serial.printf("Best path: %.1f° (score: %.2f)\n", bestAngle, bestScore);
  return bestAngle;
}

float Navigation::calculateScore(float distance, float angle) {
  // Base score from distance
  float score = distance;
  
  // Prefer straight ahead (angle close to 0)
  float anglePenalty = abs(angle) / 90.0; // Normalize to 0-1
  score *= (1.0 - anglePenalty * 0.5); // 50% penalty for extreme angles
  
  // Avoid recently visited paths
  if (hasRecentPath(angle, 20.0)) {
    score *= 0.3; // Heavy penalty for recent paths
  }
  
  // Minimum distance threshold
  if (distance < MIN_OBSTACLE_DIST) {
    score = 0; // Unusable path
  }
  
  return score;
}

bool Navigation::hasRecentPath(float angle, float tolerance) {
  for (int i = 0; i < PATH_MEMORY_SIZE; i++) {
    if (pathMemory[i].timestamp > 0) { // Valid entry
      float angleDiff = abs(pathMemory[i].angle - angle);
      if (angleDiff < tolerance) {
        // Check if it's recent (within last 30 seconds)
        if (millis() - pathMemory[i].timestamp < 30000) {
          return true;
        }
      }
    }
  }
  return false;
}

void Navigation::updatePathMemory(float distance, float angle) {
  pathMemory[pathIndex].distance = distance;
  pathMemory[pathIndex].angle = angle;
  pathMemory[pathIndex].timestamp = millis();
  
  pathIndex = (pathIndex + 1) % PATH_MEMORY_SIZE;
}

void Navigation::clearPathMemory() {
  for (int i = 0; i < PATH_MEMORY_SIZE; i++) {
    pathMemory[i].distance = 0;
    pathMemory[i].angle = 0;
    pathMemory[i].timestamp = 0;
  }
  pathIndex = 0;
  Serial.println("Path memory cleared");
}

void Navigation::emergencyManeuver() {
  Serial.println("Executing emergency maneuver");
  
  // Stop immediately
  motorController.stopMoving();
  delay(100);
  
  // Back up
  motorController.moveBackward(15);
  delay(200);
  
  // Turn around (180 degrees with some randomness)
  int turnAngle = 160 + random(-20, 20); // 140-180 degrees
  motorController.rotateRobot(turnAngle);
  
  stuckCounter = 0;
}

void Navigation::avoidStuckSituation() {
  Serial.println("Robot appears stuck, executing avoidance maneuver");
  
  // Random maneuver to break out of stuck situation
  int maneuver = random(0, 3);
  
  switch (maneuver) {
    case 0:
      // Sharp turn and move
      motorController.rotateRobot(90 + random(-30, 30));
      motorController.moveForward(20);
      break;
      
    case 1:
      // Back up and turn
      motorController.moveBackward(20);
      motorController.rotateRobot(135 + random(-45, 45));
      break;
      
    case 2:
      // Full 180 turn
      performUTurn();
      break;
  }
  
  clearPathMemory(); // Clear memory to avoid repeated patterns
  stuckCounter = 0;
}

void Navigation::performUTurn() {
  Serial.println("Performing U-turn");
  motorController.moveBackward(10);
  delay(200);
  motorController.rotateRobot(180);
}

bool Navigation::detectDeadEnd() {
  // Simple dead-end detection: scan left, center, right
  float leftDist, centerDist, rightDist;
  
  // Check left
  motorController.rotateRobot(-45);
  delay(100);
  leftDist = sensorManager.getFilteredDistance(2);
  
  // Check center
  motorController.rotateRobot(45);
  delay(100);
  centerDist = sensorManager.getFilteredDistance(2);
  
  // Check right
  motorController.rotateRobot(45);
  delay(100);
  rightDist = sensorManager.getFilteredDistance(2);
  
  // Return to center
  motorController.rotateRobot(-45);
  
  // Dead end if all directions are blocked
  bool deadEnd = (leftDist < MIN_OBSTACLE_DIST && 
                  centerDist < MIN_OBSTACLE_DIST && 
                  rightDist < MIN_OBSTACLE_DIST);
  
  if (deadEnd) {
    Serial.println("Dead end detected!");
  }
  
  return deadEnd;
}

void Navigation::scanEnvironment() {
  Serial.println("Performing environmental scan...");
  
  for (int angle = -90; angle <= 90; angle += 30) {
    motorController.rotateRobot(angle);
    delay(200);
    float distance = sensorManager.getFilteredDistance(2);
    Serial.printf("Angle %d°: %.1f cm\n", angle, distance);
  }
  
  // Return to forward position
  motorController.rotateRobot(-90);
}

void Navigation::printPathMemory() {
  Serial.println("=== Path Memory ===");
  for (int i = 0; i < PATH_MEMORY_SIZE; i++) {
    if (pathMemory[i].timestamp > 0) {
      Serial.printf("Entry %d: Angle=%.1f°, Distance=%.1f cm, Age=%lu ms\n",
                    i, pathMemory[i].angle, pathMemory[i].distance,
                    millis() - pathMemory[i].timestamp);
    }
  }
  Serial.println("==================");
}

void Navigation::printNavigationStats() {
  Serial.println("=== Navigation Stats ===");
  Serial.printf("Autonomous mode: %s\n", isAutonomousMode ? "ON" : "OFF");
  Serial.printf("Stuck counter: %d\n", stuckCounter);
  Serial.printf("Last best angle: %.1f°\n", lastBestAngle);
  Serial.printf("Path memory entries: %d\n", getPathMemorySize());
  Serial.println("========================");
}

int Navigation::getPathMemorySize() const {
  int count = 0;
  for (int i = 0; i < PATH_MEMORY_SIZE; i++) {
    if (pathMemory[i].timestamp > 0) {
      count++;
    }
  }
  return count;
}

void Navigation::resetNavigationStats() {
  stuckCounter = 0;
  lastBestAngle = 0;
  clearPathMemory();
  Serial.println("Navigation stats reset");
}