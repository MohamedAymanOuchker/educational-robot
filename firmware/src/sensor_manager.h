#ifndef SENSOR_MANAGER_H
#define SENSOR_MANAGER_H

#include <Arduino.h>
#include "types.h"
#include "config.h"
#include <MPU6050.h>
#include <Wire.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

class SensorManager {
private:
  MPU6050 imu;
  float yaw;
  unsigned long lastIMUUpdate;
  float currentDistance;
  SensorData sensorData;
  
  // IMU calibration values
  int16_t axOffset, ayOffset, azOffset;
  int16_t gxOffset, gyOffset, gzOffset;

  // Serializes HC-SR04 access: readDistanceCM() runs on both the sensor task
  // (core 0) and the motor/navigation task (core 1) during autonomy.
  SemaphoreHandle_t ultrasonicMutex;

public:
  SensorManager();
  
  // Initialization
  void begin();
  bool initializeIMU();
  void calibrateIMU();
  
  // Distance sensor functions
  float readDistanceCM();
  float getCurrentDistance() const;
  bool isObstacleDetected() const;
  
  // IMU functions
  void updateIMU();
  void updateYaw();
  float getYaw() const;
  float getTemperature();
  void resetYaw();

  // Battery monitoring
  float readBatteryVoltage();
  float readBatteryPercent();
  
  // Data management
  void updateSensorData();
  SensorData getSensorData() const;
  String getSensorDataJSON();
  
  // Calibration and testing
  void printSensorStatus();
  bool testAllSensors();
  
  // Advanced functions
  float getFilteredDistance(int samples = 3);
  bool isMoving();
};

// Global sensor manager instance
extern SensorManager sensorManager;

#endif // SENSOR_MANAGER_H