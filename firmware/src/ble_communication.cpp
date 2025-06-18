#include "ble_communication.h"
#include <Arduino.h>
#include <ArduinoJson.h>

// Global instance
BLECommunication bleManager;

BLECommunication::BLECommunication() 
  : pServer(nullptr),
    pCommandChar(nullptr),
    pSensorChar(nullptr),
    pService(nullptr),
    deviceConnected(false),
    oldDeviceConnected(false),
    commandQueue(nullptr),
    serverCallbacks(nullptr),
    commandCallbacks(nullptr) {
}

BLECommunication::~BLECommunication() {
  if (commandQueue) {
    vQueueDelete(commandQueue);
  }
  delete serverCallbacks;
  delete commandCallbacks;
}

void BLECommunication::begin() {
  // Initialize BLE device
  BLEDevice::init(BLE_DEVICE_NAME);
  Serial.printf("BLE Device initialized: %s\n", BLE_DEVICE_NAME);
  
  // Create command queue
  commandQueue = xQueueCreate(COMMAND_QUEUE_SIZE, sizeof(Command));
  if (commandQueue == nullptr) {
    Serial.println("Failed to create command queue");
    return;
  }
  
  // Initialize BLE service
  initializeService();
  
  // Start advertising
  startAdvertising();
  
  Serial.println("BLE communication ready");
}

void BLECommunication::initializeService() {
  // Create BLE server
  pServer = BLEDevice::createServer();
  
  // Create and set callbacks
  serverCallbacks = new MyServerCallbacks(this);
  pServer->setCallbacks(serverCallbacks);
  
  // Create BLE service
  pService = pServer->createService(SERVICE_UUID);
  
  // Create command characteristic (write only)
  pCommandChar = pService->createCharacteristic(
    COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  
  commandCallbacks = new CommandCharCallbacks(this);
  pCommandChar->setCallbacks(commandCallbacks);
  
  // Create sensor characteristic (notify only)
  pSensorChar = pService->createCharacteristic(
    SENSOR_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  // Add descriptor for notifications
  pSensorChar->addDescriptor(new BLE2902());
  
  // Start the service
  pService->start();
  
  Serial.println("BLE service initialized");
}

void BLECommunication::startAdvertising() {
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  
  BLEDevice::startAdvertising();
  Serial.println("BLE advertising started");
}

bool BLECommunication::isConnected() const {
  return deviceConnected;
}

void BLECommunication::handleConnection() {
  // Handle disconnection
  if (!deviceConnected && oldDeviceConnected) {
    Serial.println("Device disconnected, restarting advertising");
    delay(500); // Give time for client to process
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  
  // Handle new connection
  if (deviceConnected && !oldDeviceConnected) {
    Serial.println("Device connected");
    oldDeviceConnected = deviceConnected;
  }
}

void BLECommunication::disconnect() {
  if (deviceConnected) {
    pServer->disconnect(pServer->getConnId());
    deviceConnected = false;
    Serial.println("BLE disconnected");
  }
}

Command BLECommunication::parseCommand(const String& cmd) {
  Command command = {'S', 0}; // Default stop command
  
  if (cmd.length() == 0) {
    return command;
  }
  
  String trimmed = cmd;
  trimmed.trim();
  
  if (trimmed.startsWith("F")) {
    command.type = 'F';
    command.value = trimmed.substring(1).toInt();
  }
  else if (trimmed.startsWith("B")) {
    command.type = 'B';
    command.value = trimmed.substring(1).toInt();
  }
  else if (trimmed.startsWith("L")) {
    command.type = 'L';
    command.value = trimmed.substring(1).toInt();
  }
  else if (trimmed.startsWith("R")) {
    command.type = 'R';
    command.value = trimmed.substring(1).toInt();
  }
  else if (trimmed == "STOP") {
    command.type = 'S';
    command.value = 0;
  }
  else if (trimmed == "AUTO_NAV") {
    command.type = 'A';
    command.value = 1;
  }
  else if (trimmed == "AUTO_OFF") {
    command.type = 'A';
    command.value = 0;
  }
  else {
    Serial.printf("Unknown command: %s\n", trimmed.c_str());
  }
  
  return command;
}

void BLECommunication::processCommand(const String& cmd) {
  Command command = parseCommand(cmd);
  
  if (xQueueSend(commandQueue, &command, 0) != pdTRUE) {
    Serial.println("Command queue full, dropping command");
  } else {
    Serial.printf("Command queued: %c%d\n", command.type, command.value);
  }
}

bool BLECommunication::hasCommand() {
  return uxQueueMessagesWaiting(commandQueue) > 0;
}

Command BLECommunication::getNextCommand() {
  Command command = {'S', 0}; // Default
  
  if (xQueueReceive(commandQueue, &command, 0) == pdTRUE) {
    return command;
  }
  
  return command;
}

void BLECommunication::addCommand(const Command& cmd) {
  if (xQueueSend(commandQueue, &cmd, 0) != pdTRUE) {
    Serial.println("Failed to add command to queue");
  }
}

void BLECommunication::broadcastSensorData(const String& jsonData) {
  if (deviceConnected && pSensorChar) {
    pSensorChar->setValue(jsonData.c_str());
    pSensorChar->notify();
  }
}

void BLECommunication::sendTelemetry(const SensorData& data) {
  if (!deviceConnected) return;
  
  StaticJsonDocument<200> doc;
  doc["distance"] = data.distance;
  doc["battery"] = data.batteryLevel;
  doc["temperature"] = data.temperature;
  doc["heading"] = data.heading;
  doc["timestamp"] = data.timestamp;
  
  String output;
  serializeJson(doc, output);
  
  broadcastSensorData(output);
}

void BLECommunication::sendStatus(const String& status) {
  if (!deviceConnected) return;
  
  StaticJsonDocument<100> doc;
  doc["status"] = status;
  doc["timestamp"] = millis();
  
  String output;
  serializeJson(doc, output);
  
  broadcastSensorData(output);
}

void BLECommunication::clearCommandQueue() {
  xQueueReset(commandQueue);
  Serial.println("Command queue cleared");
}

int BLECommunication::getQueueSize() {
  return uxQueueMessagesWaiting(commandQueue);
}

void BLECommunication::printConnectionStatus() {
  Serial.printf("BLE Status - Connected: %s, Queue size: %d\n", 
                deviceConnected ? "YES" : "NO", 
                getQueueSize());
}

String BLECommunication::getDeviceAddress() {
  return BLEDevice::getAddress().toString().c_str();
}

// Callback implementations
void MyServerCallbacks::onConnect(BLEServer* pServer) {
  bleComm->deviceConnected = true;
  Serial.println("Client connected");
}

void MyServerCallbacks::onDisconnect(BLEServer* pServer) {
  bleComm->deviceConnected = false;
  Serial.println("Client disconnected");
}

void CommandCharCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
  String value = pCharacteristic->getValue().c_str();
  
  if (value.length() > 0) {
    Serial.printf("Received command: %s\n", value.c_str());
    bleComm->processCommand(value);
  }
}