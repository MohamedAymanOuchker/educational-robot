#include "sensor_manager.h"
#include <Arduino.h>
#include <ArduinoJson.h>

// Global instance
SensorManager sensorManager;

SensorManager::SensorManager() 
  : yaw(0.0), 
    lastIMUUpdate(0), 
    currentDistance(MAX_DISTANCE),
    axOffset(0), ayOffset(0), azOffset(0),
    gxOffset(0), gyOffset(0), gzOffset(0) {
}

void SensorManager::begin() {
  // Initialize ultrasonic sensor pins
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  
  // Initialize I2C for IMU
  Wire.begin(SDA_PIN, SCL_PIN);
  
  // Initialize IMU
  if (!initializeIMU()) {
    Serial.println("Warning: IMU initialization failed");
  }
  
  // Initial sensor reading
  updateSensorData();
  
  Serial.println("Sensor manager initialized");
}

bool SensorManager::initializeIMU() {
  imu.initialize();
  
  if (!imu.testConnection()) {
    Serial.println("IMU connection failed");
    return false;
  }
  
  Serial.println("IMU connected successfully");
  
  // Optional: Calibrate IMU
  // calibrateIMU();
  
  return true;
}

void SensorManager::calibrateIMU() {
  Serial.println("Calibrating IMU... Keep robot still for 10 seconds");
  
  long axSum = 0, aySum = 0, azSum = 0;
  long gxSum = 0, gySum = 0, gzSum = 0;
  const int samples = 1000;
  
  for (int i = 0; i < samples; i++) {
    int16_t ax, ay, az, gx, gy, gz;
    imu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
    
    axSum += ax; aySum += ay; azSum += az;
    gxSum += gx; gySum += gy; gzSum += gz;
    
    delay(3);
  }
  
  axOffset = axSum / samples;
  ayOffset = aySum / samples;
  azOffset = azSum / samples;
  gxOffset = gxSum / samples;
  gyOffset = gySum / samples;
  gzOffset = gzSum / samples;
  
  Serial.println("IMU calibration complete");
}

float SensorManager::readDistanceCM() {
  // Send trigger pulse
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  // Read echo pulse with timeout
  long duration = pulseIn(ECHO_PIN, HIGH, ULTRASONIC_TIMEOUT);
  
  if (duration == 0) {
    // Timeout - return maximum distance
    return MAX_DISTANCE;
  }
  
  // Convert to centimeters
  float distance = duration * 0.034 / 2;
  
  // Validate reading
  if (distance < 2.0 || distance > 400.0) {
    return MAX_DISTANCE;
  }
  
  currentDistance = distance;
  return distance;
}

float SensorManager::getCurrentDistance() const {
  return currentDistance;
}

bool SensorManager::isObstacleDetected() const {
  return currentDistance < MIN_OBSTACLE_DIST;
}

void SensorManager::updateYaw() {
  unsigned long now = millis();
  
  if (now - lastIMUUpdate < IMU_UPDATE_RATE) {
    return; // Update rate limiting
  }
  
  int16_t gx, gy, gz;
  imu.getRotation(&gx, &gy, &gz);
  
  // Apply calibration offset
  gz -= gzOffset;
  
  float dt = (now - lastIMUUpdate) / 1000.0;
  lastIMUUpdate = now;
  
  // Simple gyroscope integration
  yaw += (gz / 131.0) * dt; // 131.0 LSB/°/s for ±250°/s range
  
  // Normalize yaw to 0-360 degrees
  if (yaw > 360.0) yaw -= 360.0;
  if (yaw < 0.0) yaw += 360.0;
}

void SensorManager::updateIMU() {
  updateYaw();
}

float SensorManager::getYaw() const {
  return yaw;
}

void SensorManager::resetYaw() {
  yaw = 0.0;
  Serial.println("Yaw reset to 0");
}

float SensorManager::getTemperature() {
  int16_t rawTemp = imu.getTemperature();
  return rawTemp / 340.0 + 36.53; // MPU6050 temperature formula
}

void SensorManager::updateSensorData() {
  sensorData.distance = readDistanceCM();
  updateIMU();
  sensorData.heading = yaw;
  sensorData.temperature = getTemperature();
  sensorData.batteryLevel = 100.0; // TODO: Implement actual battery monitoring
  sensorData.timestamp = millis();
}

SensorData SensorManager::getSensorData() const {
  return sensorData;
}

String SensorManager::getSensorDataJSON() {
  StaticJsonDocument<200> doc;
  
  doc["distance"] = sensorData.distance;
  doc["battery"] = sensorData.batteryLevel;
  doc["temperature"] = sensorData.temperature;
  doc["heading"] = sensorData.heading;
  doc["timestamp"] = sensorData.timestamp;
  
  String output;
  serializeJson(doc, output);
  return output;
}

float SensorManager::getFilteredDistance(int samples) {
  float total = 0;
  int validReadings = 0;
  
  for (int i = 0; i < samples; i++) {
    float reading = readDistanceCM();
    if (reading < MAX_DISTANCE) {
      total += reading;
      validReadings++;
    }
    delay(20); // Small delay between readings
  }
  
  if (validReadings == 0) {
    return MAX_DISTANCE;
  }
  
  return total / validReadings;
}

bool SensorManager::isMoving() {
  int16_t ax, ay, az;
  imu.getAcceleration(&ax, &ay, &az);
  
  // Simple motion detection based on acceleration variance
  static int16_t lastAx = 0, lastAy = 0, lastAz = 0;
  static bool firstReading = true;
  
  if (firstReading) {
    lastAx = ax; lastAy = ay; lastAz = az;
    firstReading = false;
    return false;
  }
  
  int16_t deltaX = abs(ax - lastAx);
  int16_t deltaY = abs(ay - lastAy);
  int16_t deltaZ = abs(az - lastAz);
  
  lastAx = ax; lastAy = ay; lastAz = az;
  
  // Threshold for motion detection
  return (deltaX + deltaY + deltaZ) > 500;
}

void SensorManager::printSensorStatus() {
  Serial.println("=== Sensor Status ===");
  Serial.printf("Distance: %.2f cm\n", currentDistance);
  Serial.printf("Heading: %.2f degrees\n", yaw);
  Serial.printf("Temperature: %.2f C\n", getTemperature());
  Serial.printf("Obstacle detected: %s\n", isObstacleDetected() ? "YES" : "NO");
  Serial.printf("Robot moving: %s\n", isMoving() ? "YES" : "NO");
  Serial.println("====================");
}

bool SensorManager::testAllSensors() {
  bool allPassed = true;
  
  Serial.println("Testing all sensors...");
  
  // Test ultrasonic sensor
  float distance = readDistanceCM();
  if (distance >= MAX_DISTANCE) {
    Serial.println("Ultrasonic sensor test FAILED");
    allPassed = false;
  } else {
    Serial.printf("Ultrasonic sensor test PASSED (%.2f cm)\n", distance);
  }
  
  // Test IMU
  if (!imu.testConnection()) {
    Serial.println("IMU test FAILED");
    allPassed = false;
  } else {
    Serial.println("IMU test PASSED");
  }
  
  return allPassed;
}