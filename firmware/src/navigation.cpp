#include "navigation.h"
#include "motor_control.h"
#include "sensor_manager.h"
#include "ble_communication.h"
#include <Arduino.h>
#include <cmath>

// Global instance
Navigation navigator;

Navigation::Navigation() 
  : isAutonomousMode(false),
    lastNavigationUpdate(0),
    lastBestAngle(0),
    stuckCounter(0),
    pathIndex(0) {
  
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
  if (motorController.isStopPending()) return;
  isAutonomousMode = true;
  clearPathMemory();
  stuckCounter = 0;
  lastNavigationUpdate = millis();
  Serial.println("Autonomous navigation enabled");
}

void Navigation::disableAutonomousMode() {
  isAutonomousMode = false;
  Serial.println("Autonomous navigation disabled");
}

bool Navigation::isAutonomous() const {
  return isAutonomousMode.load() && !motorController.isStopPending();
}

void Navigation::failAutonomous(const char* reason) {
  // A user STOP is cancellation, not an autonomous sensor fault.
  if (!isAutonomous()) return;
  bleManager.stopAll(reason);
  bleManager.sendFault(reason);
}

void Navigation::executeAutonomousStep() {
  if (!isAutonomous()) return;
  
  // Rate limiting - update every 500ms
  if (millis() - lastNavigationUpdate < 500) {
    return;
  }
  lastNavigationUpdate = millis();
  
  const SensorData data = sensorManager.getSensorData();
  if (!data.distanceValid) {
    failAutonomous("autonomy stopped: distance unavailable or stale");
    return;
  }
  const float currentDistance = data.distance;
  
  // With no rear sensor, fail closed rather than blindly reversing.
  if (currentDistance < CRITICAL_DISTANCE) {
    Serial.println("Emergency maneuver: Too close to obstacle");
    failAutonomous("autonomy stopped: obstacle too close");
    return;
  }
  
  // Continue forward if path is clear
  if (currentDistance > MIN_OBSTACLE_DIST) {
    if (motorController.moveForward(1) != MotionResult::Done) {
      failAutonomous("autonomy forward motion failed");
    }
    stuckCounter = 0; // Reset stuck counter
    return;
  }
  
  // Obstacle detected - find new path
  if (currentDistance <= MIN_OBSTACLE_DIST) {
    float bestAngle = findBestPath();
    
    if (!isAutonomous()) return;
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

  // rotateRobot() turns RELATIVE to the current heading, so we track the
  // chassis heading (relative to center) and only ever turn by the delta.
  // This sweeps left-to-right across the arc instead of spinning in place.
  int currentHeading = 0;

  for (int angle = SCAN_ANGLE_START; angle <= SCAN_ANGLE_END; angle += SCAN_ANGLE_STEP) {
    // Bail out of the scan promptly if the user requested a stop
    if (motorController.isStopPending()) {
      Serial.println("Scan aborted by stop request");
      break;
    }

    // Turn by the difference between where we are and the target scan angle
    if (motorController.rotateRobot(angle - currentHeading) != MotionResult::Done) return -999;
    currentHeading = angle;
    delay(100); // Stabilization time

    // Take multiple readings for accuracy
    float totalDistance = 0;
    int validReadings = 0;

    for (int i = 0; i < 3; i++) {
      float distance = sensorManager.readDistanceCM();
      if (!std::isfinite(distance)) {
        failAutonomous("autonomy scan stopped: distance unavailable");
        return -999;
      }
      if (std::isfinite(distance)) {
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

    // Do not add candidate headings during scoring: that penalized adjacent
    // candidates in the same sweep and biased every clear scan to the left.
  }

  // Return to center by undoing the net rotation accumulated during the scan
  if (motorController.rotateRobot(-currentHeading) != MotionResult::Done) return -999;
  if (bestAngle != -999) updatePathMemory(bestScore, bestAngle);

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
  failAutonomous("autonomy stopped: obstacle too close");
}

void Navigation::avoidStuckSituation() {
  // No rear/side range sensor: ask for human intervention instead of blind recovery.
  failAutonomous("autonomy stopped: no clear path");
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
