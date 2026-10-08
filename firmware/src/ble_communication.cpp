#include "ble_communication.h"
#include "command_protocol.h"
#include "motor_control.h"
#include "navigation.h"
#include <ArduinoJson.h>
#include <freertos/task.h>

BLECommunication bleManager;

BLECommunication::BLECommunication()
  : pServer(nullptr), pCommandChar(nullptr), pSensorChar(nullptr), pService(nullptr),
    deviceConnected(false), oldDeviceConnected(false), commandQueue(nullptr),
    commandMutex(nullptr), transmitMutex(nullptr), serverCallbacks(nullptr), commandCallbacks(nullptr) {}

BLECommunication::~BLECommunication() {
  if (commandQueue) vQueueDelete(commandQueue);
  if (commandMutex) vSemaphoreDelete(commandMutex);
  if (transmitMutex) vSemaphoreDelete(transmitMutex);
  delete serverCallbacks;
  delete commandCallbacks;
}

void BLECommunication::begin() {
  commandQueue = xQueueCreate(COMMAND_QUEUE_SIZE, sizeof(Command));
  commandMutex = xSemaphoreCreateMutex();
  transmitMutex = xSemaphoreCreateMutex();
  if (!commandQueue || !commandMutex || !transmitMutex) {
    motorController.requestStop();
    Serial.println("BLE initialization failed: insufficient memory");
    return;
  }
  BLEDevice::init(BLE_DEVICE_NAME);
  initializeService();
  startAdvertising();
}

void BLECommunication::initializeService() {
  pServer = BLEDevice::createServer();
  serverCallbacks = new MyServerCallbacks(this);
  pServer->setCallbacks(serverCallbacks);
  pService = pServer->createService(SERVICE_UUID);
  pCommandChar = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  commandCallbacks = new CommandCharCallbacks(this);
  pCommandChar->setCallbacks(commandCallbacks);
  pSensorChar = pService->createCharacteristic(SENSOR_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pSensorChar->addDescriptor(new BLE2902());
  pService->start();
}

void BLECommunication::startAdvertising() {
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
}

bool BLECommunication::isConnected() const { return deviceConnected.load(); }

void BLECommunication::handleConnection() {
  if (!isConnected() && oldDeviceConnected) {
    if (pServer) pServer->startAdvertising();
    oldDeviceConnected = false;
  }
  if (isConnected() && !oldDeviceConnected) oldDeviceConnected = true;
}

void BLECommunication::disconnect() {
  stopAll("disconnected");
  if (deviceConnected.exchange(false) && pServer) pServer->disconnect(pServer->getConnId());
}

void BLECommunication::processCommand(const char* data, size_t length) {
  Command command;
  if (!parseRobotCommand(data, length, command)) {
    sendCommandResult(command.id, "error", "invalid command or parameter");
    return;
  }
  // STOP and AUTO_OFF bypass a full queue and immediately deenergize coils.
  if (command.type == 'S' || (command.type == 'A' && command.value == 0)) {
    stopAll("stopped");
    sendCommandResult(command.id, "done");
    return;
  }
  if (command.type == 'C' || (command.type == 'K' && command.value == 1)) {
    sendCommandResult(command.id, "error", "command unavailable in this release");
    return;
  }
  addCommand(command);
}

void BLECommunication::addCommand(const Command& incoming) {
  if (!commandQueue || !commandMutex) {
    sendCommandResult(incoming.id, "error", "command queue unavailable");
    return;
  }
  Command command = incoming;
  xSemaphoreTake(commandMutex, portMAX_DELAY);
  command.generation = motorController.getGeneration();
  const bool queued = xQueueSend(commandQueue, &command, 0) == pdTRUE;
  xSemaphoreGive(commandMutex);
  if (!queued) sendCommandResult(command.id, "error", "command queue full");
}

bool BLECommunication::hasCommand() { return commandQueue && uxQueueMessagesWaiting(commandQueue) > 0; }

Command BLECommunication::getNextCommand() {
  Command command{'?', 0};
  if (!commandQueue || !commandMutex) return command;
  xSemaphoreTake(commandMutex, portMAX_DELAY);
  xQueueReceive(commandQueue, &command, 0);
  xSemaphoreGive(commandMutex);
  return command;
}

void BLECommunication::stopAll(const char* reason) {
  // Queue admission and generation capture cannot straddle a STOP barrier.
  if (commandMutex) xSemaphoreTake(commandMutex, portMAX_DELAY);
  motorController.requestStop();
  navigator.disableAutonomousMode();
  Command cancelled[COMMAND_QUEUE_SIZE];
  size_t count = 0;
  if (commandQueue) {
    while (count < COMMAND_QUEUE_SIZE && xQueueReceive(commandQueue, &cancelled[count], 0) == pdTRUE) ++count;
  }
  if (commandMutex) xSemaphoreGive(commandMutex);
  for (size_t i = 0; i < count; ++i) sendCommandResult(cancelled[i].id, "cancelled", reason);
}

void BLECommunication::broadcastSensorData(const String& jsonData) {
  if (!isConnected() || !pSensorChar || !transmitMutex) return;
  // Notifications may be only 20 payload bytes at the default ATT MTU. Keep
  // each complete NDJSON record serialized across telemetry and command tasks.
  xSemaphoreTake(transmitMutex, portMAX_DELAY);
  const String record = jsonData + "\n";
  for (size_t offset = 0; offset < record.length() && isConnected(); offset += 20) {
    size_t count = record.length() - offset;
    if (count > 20) count = 20;
    pSensorChar->setValue(reinterpret_cast<uint8_t*>(const_cast<char*>(record.c_str() + offset)), count);
    pSensorChar->notify();
    vTaskDelay(1); // allow BLE stack to drain the notification buffer
  }
  xSemaphoreGive(transmitMutex);
}

void BLECommunication::sendTelemetry(const SensorData& data) {
  StaticJsonDocument<384> doc;
  doc["type"] = "telemetry";
  if (data.distanceValid) doc["distance"] = data.distance;
  else doc["distance"] = nullptr;
  doc["distance_valid"] = data.distanceValid;
  doc["distance_age_ms"] = data.distanceAgeMs;
  doc["battery"] = data.batteryLevel;
  doc["temperature"] = data.temperature;
  doc["heading"] = data.heading;
  doc["timestamp"] = data.timestamp;
  String output;
  serializeJson(doc, output);
  broadcastSensorData(output);
}

void BLECommunication::sendCommandResult(uint16_t id, const char* status, const char* message) {
  StaticJsonDocument<256> doc;
  doc["type"] = "command";
  doc["id"] = id;
  doc["status"] = status;
  if (message) doc["message"] = message;
  String output;
  serializeJson(doc, output);
  broadcastSensorData(output);
}

void BLECommunication::sendStatus(const String& status) {
  StaticJsonDocument<256> doc;
  doc["type"] = "status";
  doc["status"] = status;
  doc["timestamp"] = millis();
  String output;
  serializeJson(doc, output);
  broadcastSensorData(output);
}

void BLECommunication::sendFault(const char* message) {
  StaticJsonDocument<256> doc;
  doc["type"] = "fault";
  doc["message"] = message;
  String output;
  serializeJson(doc, output);
  broadcastSensorData(output);
}

void BLECommunication::clearCommandQueue() { stopAll("queue cleared"); }
int BLECommunication::getQueueSize() { return commandQueue ? uxQueueMessagesWaiting(commandQueue) : 0; }
void BLECommunication::printConnectionStatus() {
  Serial.printf("BLE connected=%d queue=%d\n", isConnected(), getQueueSize());
}
String BLECommunication::getDeviceAddress() { return BLEDevice::getAddress().toString().c_str(); }

void MyServerCallbacks::onConnect(BLEServer*) { bleComm->deviceConnected.store(true); }
void MyServerCallbacks::onDisconnect(BLEServer*) {
  bleComm->deviceConnected.store(false);
  bleComm->stopAll("disconnected");
}
void CommandCharCallbacks::onWrite(BLECharacteristic* characteristic) {
  const std::string value = characteristic->getValue();
  bleComm->processCommand(value.data(), value.size());
}
