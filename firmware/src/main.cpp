/**
 * E-Bug Educational Robot - Main Program
 * 
 * An affordable educational robotics platform for teaching programming
 * concepts to children aged 7-12 through hands-on interaction.
 * 
 * Features:
 * - ESP32-based hardware with stepper motors
 * - BLE communication with mobile app
 * - Progressive learning system
 * - Autonomous navigation with E-Bug algorithm
 * - Real-time sensor telemetry
 * 
 * Author: Mohamed Ayman OUCHKER
 * Institution: Euromed University of Fes
 * Project: End of Studies Project 2024-2025
 */

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

// Project modules
#include "config.h"
#include "types.h"
#include "motor_control.h"
#include "sensor_manager.h"
#include "ble_communication.h"
#include "navigation.h"

// Task handles
TaskHandle_t motorTaskHandle = NULL;
TaskHandle_t sensorTaskHandle = NULL;
TaskHandle_t communicationTaskHandle = NULL;

// Global state
RobotState currentState = IDLE;
unsigned long lastHeartbeat = 0;
bool systemInitialized = false;

// Function prototypes
void motorTask(void *parameter);
void sensorTask(void *parameter);
void communicationTask(void *parameter);
void executeCommand(const Command& cmd);
void printSystemStatus();
void handleSystemError(const String& error);
bool initializeSystem();

void setup() {
  Serial.begin(115200);
  delay(1000); // Wait for serial monitor
  
  Serial.println("========================================");
  Serial.println("E-Bug Educational Robot Starting...");
  Serial.println("Version: 1.0.0");
  Serial.println("========================================");
  
  // Initialize all subsystems
  if (!initializeSystem()) {
    Serial.println("FATAL: System initialization failed!");
    handleSystemError("System initialization failed");
    return;
  }
  
  // Create FreeRTOS tasks
  Serial.println("Creating system tasks...");
  
  // Motor control task (Core 1 - for real-time control)
  xTaskCreatePinnedToCore(
    motorTask,                    // Task function
    "MotorTask",                 // Task name
    MOTOR_TASK_STACK,            // Stack size
    NULL,                        // Parameters
    2,                           // Priority (high)
    &motorTaskHandle,            // Task handle
    1                            // Core 1
  );
  
  // Sensor management task (Core 0)
  xTaskCreatePinnedToCore(
    sensorTask,                  // Task function
    "SensorTask",               // Task name
    SENSOR_TASK_STACK,          // Stack size
    NULL,                       // Parameters
    1,                          // Priority (medium)
    &sensorTaskHandle,          // Task handle
    0                           // Core 0
  );
  
  // Communication task (Core 0)
  xTaskCreatePinnedToCore(
    communicationTask,           // Task function
    "CommTask",                 // Task name
    COMM_TASK_STACK,            // Stack size
    NULL,                       // Parameters
    1,                          // Priority (medium)
    &communicationTaskHandle,   // Task handle
    0                           // Core 0
  );
  
  systemInitialized = true;
  Serial.println("System initialization complete!");
  Serial.println("Robot ready for commands...");
  
  // Initial system status
  printSystemStatus();
}

void loop() {
  // Main loop handles connection management and heartbeat
  if (systemInitialized) {
    // Handle BLE connection state
    bleManager.handleConnection();
    
    // Heartbeat every 10 seconds
    if (millis() - lastHeartbeat > 10000) {
      lastHeartbeat = millis();
      Serial.printf("Heartbeat - Uptime: %lu ms, Free heap: %d bytes\n", 
                    millis(), ESP.getFreeHeap());
      
      if (bleManager.isConnected()) {
        bleManager.sendStatus("heartbeat");
      }
    }
  }
  
  delay(100); // Prevent watchdog reset
}

bool initializeSystem() {
  Serial.println("Initializing subsystems...");
  
  // Initialize motor control
  Serial.print("- Motor control... ");
  motorController.begin();
  Serial.println("OK");
  
  // Initialize sensor management
  Serial.print("- Sensor management... ");
  sensorManager.begin();
  if (!sensorManager.testAllSensors()) {
    Serial.println("WARNING: Some sensors failed tests");
  } else {
    Serial.println("OK");
  }
  
  // Initialize BLE communication
  Serial.print("- BLE communication... ");
  bleManager.begin();
  Serial.println("OK");
  
  // Initialize navigation
  Serial.print("- Navigation system... ");
  navigator.begin();
  Serial.println("OK");
  
  Serial.println("All subsystems initialized successfully");
  return true;
}

void motorTask(void *parameter) {
  Serial.println("Motor task started on Core 1");
  
  while (true) {
    // Process commands from BLE
    if (bleManager.hasCommand()) {
      Command cmd = bleManager.getNextCommand();
      executeCommand(cmd);
    }
    
    // Handle autonomous navigation
    if (navigator.isAutonomous()) {
      navigator.executeAutonomousStep();
    }
    
    // Task delay
    vTaskDelay(pdMS_TO_TICKS(MOTOR_TASK_DELAY));
  }
}

void sensorTask(void *parameter) {
  unsigned long lastRange = 0;
  while (true) {
    sensorManager.updateIMU();
    if (millis() - lastRange >= SENSOR_UPDATE_RATE) {
      lastRange = millis();
      sensorManager.updateSensorData();
    }
    vTaskDelay(pdMS_TO_TICKS(IMU_UPDATE_RATE));
  }
}

void communicationTask(void *parameter) {
  while (true) {
    // Notification transmission never delays the safety sensor sampling task.
    if (bleManager.isConnected()) bleManager.sendTelemetry(sensorManager.getSensorData());
    vTaskDelay(pdMS_TO_TICKS(TELEMETRY_UPDATE_RATE));
  }
}

void executeCommand(const Command& cmd) {
  if (cmd.type == '?') return; // empty queue is not a STOP command
  if (cmd.generation != motorController.getGeneration()) {
    bleManager.sendCommandResult(cmd.id, "cancelled", "superseded by stop");
    return;
  }
  if (cmd.type == 'K' && cmd.value == 0) {
    bleManager.sendCommandResult(cmd.id, "done"); // open-loop is always used in P1
    return;
  }
  const bool movement = cmd.type == 'F' || cmd.type == 'B' || cmd.type == 'L' || cmd.type == 'R';
  if (!movement && !(cmd.type == 'A' && cmd.value == 1)) {
    bleManager.sendCommandResult(cmd.id, "error", "unsupported queued command");
    return;
  }
  // The generation check and rearming are atomic with STOP and coil writes.
  if (!motorController.arm(cmd.generation)) {
    bleManager.sendCommandResult(cmd.id, "cancelled", "superseded by stop");
    return;
  }
  MotionResult result = MotionResult::Done;
  if (cmd.type == 'A') {
    if (!sensorManager.isDistanceValid()) result = MotionResult::SensorInvalid;
    else {
      currentState = AUTONOMOUS;
      navigator.enableAutonomousMode();
    }
  } else {
    navigator.disableAutonomousMode();
    switch (cmd.type) {
      case 'F': currentState = MOVING_FORWARD; result = motorController.moveForward(cmd.value); break;
      case 'B': currentState = MOVING_BACKWARD; result = motorController.moveBackward(cmd.value); break;
      case 'L': currentState = TURNING_LEFT; result = motorController.rotateLeft(cmd.value); break;
      case 'R': currentState = TURNING_RIGHT; result = motorController.rotateRight(cmd.value); break;
    }
    currentState = IDLE;
  }
  if (cmd.generation != motorController.getGeneration() || result == MotionResult::Cancelled) {
    bleManager.sendCommandResult(cmd.id, "cancelled", "stopped during command");
  } else if (result == MotionResult::Done) {
    bleManager.sendCommandResult(cmd.id, "done");
  } else {
    // Failed motion must not be followed by the remainder of a queued program.
    const char* reason = result == MotionResult::Blocked ? "obstacle detected" :
      result == MotionResult::SensorInvalid ? "distance unavailable or stale" : "motion timed out";
    bleManager.stopAll(reason);
    currentState = IDLE;
    bleManager.sendCommandResult(cmd.id, "error", reason);
  }
}

void printSystemStatus() {
  Serial.println("\n========== SYSTEM STATUS ==========");
  Serial.printf("Chip model: %s\n", ESP.getChipModel());
  Serial.printf("CPU frequency: %d MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());
  Serial.printf("Flash size: %d bytes\n", ESP.getFlashChipSize());
  Serial.printf("BLE address: %s\n", bleManager.getDeviceAddress().c_str());
  Serial.printf("Current state: %d\n", currentState);
  Serial.println("===================================\n");
  
  // Subsystem status
  sensorManager.printSensorStatus();
  navigator.printNavigationStats();
  bleManager.printConnectionStatus();
}

void handleSystemError(const String& error) {
  Serial.printf("SYSTEM ERROR: %s\n", error.c_str());
  
  // Stop all motors
  bleManager.stopAll("system error");
  
  // Disable autonomous mode
  navigator.disableAutonomousMode();
  
  // Send error status if connected
  if (bleManager.isConnected()) {
    bleManager.sendStatus("ERROR: " + error);
  }
  
  // Flash LED or other error indication could go here

  // In a real application, you might want to restart or enter safe mode
}