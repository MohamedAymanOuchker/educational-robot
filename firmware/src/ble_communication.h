#ifndef BLE_COMMUNICATION_H
#define BLE_COMMUNICATION_H

#include <Arduino.h>
#include "types.h"
#include "config.h"
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <freertos/queue.h>
#include <freertos/semphr.h>
#include <atomic>

// Forward declarations for callback classes
class MyServerCallbacks;
class CommandCharCallbacks;

class BLECommunication {
private:
  BLEServer* pServer;
  BLECharacteristic* pCommandChar;
  BLECharacteristic* pSensorChar;
  BLEService* pService;
  
  std::atomic<bool> deviceConnected;
  bool oldDeviceConnected;
  
  // Command processing
  QueueHandle_t commandQueue;
  SemaphoreHandle_t commandMutex;
  SemaphoreHandle_t transmitMutex;
  
  // Callback instances
  MyServerCallbacks* serverCallbacks;
  CommandCharCallbacks* commandCallbacks;
  
  // Helper functions
  void processCommand(const char* data, size_t length);

public:
  BLECommunication();
  ~BLECommunication();
  
  // Initialization
  void begin();
  void initializeService();
  void startAdvertising();
  
  // Connection management
  bool isConnected() const;
  void handleConnection();
  void disconnect();
  
  // Command handling
  bool hasCommand();
  Command getNextCommand();
  void addCommand(const Command& cmd);
  void stopAll(const char* reason = "stopped");
  
  // Data transmission
  void broadcastSensorData(const String& jsonData);
  void sendTelemetry(const SensorData& data);
  void sendStatus(const String& status);
  void sendCommandResult(uint16_t id, const char* status, const char* message = nullptr);
  void sendFault(const char* message);
  
  // Queue management
  void clearCommandQueue();
  int getQueueSize();
  
  // Utility functions
  void printConnectionStatus();
  String getDeviceAddress();
  
  // Friend classes for callbacks
  friend class MyServerCallbacks;
  friend class CommandCharCallbacks;
};

// Callback classes
class MyServerCallbacks : public BLEServerCallbacks {
private:
  BLECommunication* bleComm;
  
public:
  MyServerCallbacks(BLECommunication* comm) : bleComm(comm) {}
  
  void onConnect(BLEServer* pServer) override;
  void onDisconnect(BLEServer* pServer) override;
};

class CommandCharCallbacks : public BLECharacteristicCallbacks {
private:
  BLECommunication* bleComm;
  
public:
  CommandCharCallbacks(BLECommunication* comm) : bleComm(comm) {}
  
  void onWrite(BLECharacteristic* pCharacteristic) override;
};

// Global BLE communication instance
extern BLECommunication bleManager;

#endif // BLE_COMMUNICATION_H
