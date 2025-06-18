#ifndef BLE_COMMUNICATION_H
#define BLE_COMMUNICATION_H

#include "types.h"
#include "config.h"
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <freertos/queue.h>

// Forward declarations for callback classes
class MyServerCallbacks;
class CommandCharCallbacks;

class BLECommunication {
private:
  BLEServer* pServer;
  BLECharacteristic* pCommandChar;
  BLECharacteristic* pSensorChar;
  BLEService* pService;
  
  bool deviceConnected;
  bool oldDeviceConnected;
  
  // Command processing
  QueueHandle_t commandQueue;
  
  // Callback instances
  MyServerCallbacks* serverCallbacks;
  CommandCharCallbacks* commandCallbacks;
  
  // Helper functions
  Command parseCommand(const String& cmd);
  void processCommand(const String& cmd);

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
  
  // Data transmission
  void broadcastSensorData(const String& jsonData);
  void sendTelemetry(const SensorData& data);
  void sendStatus(const String& status);
  
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