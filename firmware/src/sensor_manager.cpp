#include "sensor_manager.h"
#include <Arduino.h>
#include <ArduinoJson.h>
#include <Preferences.h>

// NVS namespace for persisted IMU calibration
static const char* CALIB_NAMESPACE = "imucal";

// Global instance
SensorManager sensorManager;

SensorManager::SensorManager() 
  : yaw(0.0),
    lastIMUUpdate(0),
    currentDistance(MAX_DISTANCE),
    axOffset(0), ayOffset(0), azOffset(0),
    gxOffset(0), gyOffset(0), gzOffset(0),
    ultrasonicMutex(nullptr),
    imuMutex(nullptr),
    recalibrateRequested(false) {
}

void SensorManager::begin() {
  // Initialize ultrasonic sensor pins
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // Guard for cross-core ultrasonic access (created before the first read)
  ultrasonicMutex = xSemaphoreCreateMutex();
  if (ultrasonicMutex == nullptr) {
    Serial.println("Warning: failed to create ultrasonic mutex");
  }

  // Guard for cross-core IMU access (sensor task vs closed-loop turn)
  imuMutex = xSemaphoreCreateMutex();
  if (imuMutex == nullptr) {
    Serial.println("Warning: failed to create IMU mutex");
  }

  // Seed a sane temperature so the first distance calc has a valid value
  sensorData.temperature = 20.0;

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

  // Prefer a stored calibration so we skip the ~3s boot calibration. Only
  // the very first boot (or a CALIBRATE command) runs the full routine.
  if (loadCalibration()) {
    Serial.println("Loaded IMU calibration from NVS (skipping boot calibration)");
  } else {
    Serial.println("No stored IMU calibration found; calibrating now");
    calibrateIMU();
  }

  return true;
}

void SensorManager::calibrateIMU() {
  Serial.println("Calibrating IMU... Keep robot still for ~3 seconds");

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

  // Persist so subsequent boots can skip this routine
  saveCalibration();
}

bool SensorManager::loadCalibration() {
  Preferences prefs;
  // Read-only open fails if the namespace was never written
  if (!prefs.begin(CALIB_NAMESPACE, true)) {
    return false;
  }

  bool valid = prefs.getBool("valid", false);
  if (valid) {
    axOffset = prefs.getShort("ax", 0);
    ayOffset = prefs.getShort("ay", 0);
    azOffset = prefs.getShort("az", 0);
    gxOffset = prefs.getShort("gx", 0);
    gyOffset = prefs.getShort("gy", 0);
    gzOffset = prefs.getShort("gz", 0);
  }

  prefs.end();
  return valid;
}

void SensorManager::saveCalibration() {
  Preferences prefs;
  if (!prefs.begin(CALIB_NAMESPACE, false)) {
    Serial.println("Warning: could not open NVS to save calibration");
    return;
  }

  prefs.putShort("ax", axOffset);
  prefs.putShort("ay", ayOffset);
  prefs.putShort("az", azOffset);
  prefs.putShort("gx", gxOffset);
  prefs.putShort("gy", gyOffset);
  prefs.putShort("gz", gzOffset);
  prefs.putBool("valid", true);

  prefs.end();
  Serial.println("IMU calibration saved to NVS");
}

void SensorManager::requestRecalibration() {
  recalibrateRequested = true;
}

void SensorManager::serviceRecalibration() {
  if (recalibrateRequested) {
    recalibrateRequested = false;
    // Runs in the sensor task so IMU/I2C access stays single-core
    calibrateIMU();
  }
}

float SensorManager::readDistanceCM() {
  // Serialize access: concurrent trigger/echo cycles from two cores would
  // corrupt each other's reading. Held only here (leaf), so no nesting.
  if (ultrasonicMutex != nullptr) {
    xSemaphoreTake(ultrasonicMutex, portMAX_DELAY);
  }

  // Send trigger pulse
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Read echo pulse with timeout
  long duration = pulseIn(ECHO_PIN, HIGH, ULTRASONIC_TIMEOUT);

  float result = MAX_DISTANCE;
  if (duration != 0) {
    // Temperature-compensated speed of sound: 331.3 + 0.606*T m/s, expressed
    // as cm/us (/10000). sensorData.temperature is the cached MPU die temp
    // (an approximation of ambient) refreshed by the sensor task, so we avoid
    // a cross-core I2C read here.
    float speedCmPerUs = (331.3 + 0.606 * sensorData.temperature) / 10000.0;
    float distance = duration * speedCmPerUs / 2.0;

    // Validate reading; only a valid sample updates the cached distance
    if (distance >= 2.0 && distance <= 400.0) {
      currentDistance = distance;
      result = distance;
    }
  }

  if (ultrasonicMutex != nullptr) {
    xSemaphoreGive(ultrasonicMutex);
  }
  return result;
}

float SensorManager::getCurrentDistance() const {
  return currentDistance;
}

bool SensorManager::isObstacleDetected() const {
  return currentDistance < MIN_OBSTACLE_DIST;
}

void SensorManager::integrateYaw() {
  // Caller must hold imuMutex (touches the IMU over I2C).
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

void SensorManager::updateYaw() {
  if (imuMutex != nullptr) xSemaphoreTake(imuMutex, portMAX_DELAY);
  integrateYaw();
  if (imuMutex != nullptr) xSemaphoreGive(imuMutex);
}

float SensorManager::sampleYaw() {
  // Thread-safe fresh yaw read for closed-loop turns on the motor task.
  if (imuMutex != nullptr) xSemaphoreTake(imuMutex, portMAX_DELAY);
  integrateYaw();
  float result = yaw;
  if (imuMutex != nullptr) xSemaphoreGive(imuMutex);
  return result;
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
  // Guarded: shares the IMU/I2C bus with sampleYaw() on the motor task
  if (imuMutex != nullptr) xSemaphoreTake(imuMutex, portMAX_DELAY);
  int16_t rawTemp = imu.getTemperature();
  if (imuMutex != nullptr) xSemaphoreGive(imuMutex);
  return rawTemp / 340.0 + 36.53; // MPU6050 temperature formula
}

float SensorManager::readBatteryVoltage() {
  // analogReadMilliVolts() applies the ESP32's factory ADC calibration,
  // which is far more accurate than a raw analogRead() conversion.
  uint32_t pinMilliVolts = analogReadMilliVolts(BATTERY_PIN);
  return (pinMilliVolts / 1000.0) * BATTERY_DIVIDER_RATIO;
}

float SensorManager::readBatteryPercent() {
  float voltage = readBatteryVoltage();
  float percent = (voltage - BATTERY_MIN_VOLTAGE) /
                  (BATTERY_MAX_VOLTAGE - BATTERY_MIN_VOLTAGE) * 100.0;

  // Clamp to a valid 0-100 range
  if (percent > 100.0) percent = 100.0;
  if (percent < 0.0) percent = 0.0;
  return percent;
}

void SensorManager::updateSensorData() {
  // Refresh temperature first so readDistanceCM() uses a current value
  sensorData.temperature = getTemperature();
  sensorData.distance = readDistanceCM();
  updateIMU();
  sensorData.heading = yaw;
  sensorData.batteryLevel = readBatteryPercent();
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