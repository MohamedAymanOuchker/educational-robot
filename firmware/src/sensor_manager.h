#ifndef SENSOR_MANAGER_H
#define SENSOR_MANAGER_H

#include "types.h"
#include "config.h"
#include <MPU6050.h>
#include <Wire.h>

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