// E-Bug Robot for ESP32 with BLE + Advanced Autonomy
// Combines BLE-controlled commands with smart scanning and path memory
// Components: ESP32, HC-SR04, 2x Stepper Motors (e.g., A4988), MPU6050 IMU

#include <Wire.h>
#include <MPU6050.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <ArduinoJson.h>

// BLE UUIDs
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define COMMAND_CHAR_UUID   "12345678-1234-1234-1234-123456789abd"
#define SENSOR_CHAR_UUID    "12345678-1234-1234-1234-123456789abe"

// Pin Definitions
const int trigPin = 5;
const int echoPin = 18;
const int leftStepPin = 26;
const int leftDirPin = 27;
const int rightStepPin = 14;
const int rightDirPin = 12;
const int leftEnablePin = 25;
const int rightEnablePin = 13;
const int SDA_PIN = 21;
const int SCL_PIN = 22;

// IMU and State Variables
MPU6050 imu;
float yaw = 0.0;
unsigned long lastIMUUpdate = 0;

// BLE Variables
BLEServer* pServer = NULL;
BLECharacteristic* pCommandChar = NULL;
BLECharacteristic* pSensorChar = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Motor and Navigation Variables
const int stepsPerRev = 200;
const int wheelDiameter = 65;
const float wheelCircumference = PI * wheelDiameter;
const float robotWidth = 150;
int currentSpeed = 400;
const int minObstacle = 25;
const int criticalDist = 15;

// Path Memory
const int pathMemSize = 10;
float pathMemory[pathMemSize][2];
int pathIndex = 0;

// BLE Command Queue
TaskHandle_t motorTaskHandle = NULL;
TaskHandle_t sensorTaskHandle = NULL;
QueueHandle_t commandQueue;
struct Command { char type; int value; };
bool isAutonomous = false;
float currentDistance = 0;

// BLE Callbacks
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) { deviceConnected = true; }
  void onDisconnect(BLEServer* pServer) { deviceConnected = false; }
};
class CommandCharCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pChar) {
    String val = pChar->getValue().c_str();
    if (val.length()) processCommand(val);
  }
};

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT); pinMode(echoPin, INPUT);
  pinMode(leftStepPin, OUTPUT); pinMode(leftDirPin, OUTPUT);
  pinMode(rightStepPin, OUTPUT); pinMode(rightDirPin, OUTPUT);
  pinMode(leftEnablePin, OUTPUT); pinMode(rightEnablePin, OUTPUT);
  digitalWrite(leftEnablePin, LOW); digitalWrite(rightEnablePin, LOW);
  Wire.begin(SDA_PIN, SCL_PIN);
  imu.initialize();
  initBLE();
  commandQueue = xQueueCreate(10, sizeof(Command));
  for (int i = 0; i < pathMemSize; i++) pathMemory[i][0] = pathMemory[i][1] = 0;
  xTaskCreatePinnedToCore(motorTask, "MotorTask", 10000, NULL, 1, &motorTaskHandle, 1);
  xTaskCreatePinnedToCore(sensorTask, "SensorTask", 10000, NULL, 1, &sensorTaskHandle, 0);
}

void initBLE() {
  BLEDevice::init("E-Bug ESP32");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCommandChar = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCommandChar->setCallbacks(new CommandCharCallbacks());
  pSensorChar = pService->createCharacteristic(SENSOR_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pSensorChar->addDescriptor(new BLE2902());
  pService->start(); BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  BLEDevice::startAdvertising();
}

void loop() {
  if (!deviceConnected && oldDeviceConnected) { delay(500); pServer->startAdvertising(); oldDeviceConnected = false; }
  if (deviceConnected && !oldDeviceConnected) oldDeviceConnected = true;
  delay(10);
}

void motorTask(void *param) {
  Command cmd;
  while (true) {
    if (xQueueReceive(commandQueue, &cmd, 0) == pdTRUE) executeCommand(cmd);
    if (isAutonomous && deviceConnected) autonomousNavigate();
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}

void sensorTask(void *param) {
  while (true) {
    updateYaw(); currentDistance = readDistanceCM();
    broadcastSensorData();
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

void processCommand(String cmd) {
  cmd.trim(); Command newCmd;
  if (cmd.startsWith("F")) { newCmd.type = 'F'; newCmd.value = cmd.substring(1).toInt(); }
  else if (cmd.startsWith("B")) { newCmd.type = 'B'; newCmd.value = cmd.substring(1).toInt(); }
  else if (cmd.startsWith("L")) { newCmd.type = 'L'; newCmd.value = cmd.substring(1).toInt(); }
  else if (cmd.startsWith("R")) { newCmd.type = 'R'; newCmd.value = cmd.substring(1).toInt(); }
  else if (cmd == "STOP") { newCmd.type = 'S'; newCmd.value = 0; isAutonomous = false; }
  else if (cmd == "AUTO_NAV") { isAutonomous = true; return; }
  xQueueSend(commandQueue, &newCmd, 0);
}

void executeCommand(Command cmd) {
  int steps = (cmd.value * 10.0 / wheelCircumference) * stepsPerRev;
  switch (cmd.type) {
    case 'F': moveForward(steps); break;
    case 'B': moveBackward(steps); break;
    case 'L': rotateRobot(-cmd.value); break;
    case 'R': rotateRobot(cmd.value); break;
    case 'S': stopMoving(); break;
  }
}

void moveForward(int steps) {
  for (int i = 0; i < steps; i++) {
    if (i % 50 == 0 && currentDistance < criticalDist) break;
    digitalWrite(leftDirPin, HIGH); digitalWrite(rightDirPin, HIGH);
    digitalWrite(leftStepPin, HIGH); digitalWrite(rightStepPin, HIGH);
    delayMicroseconds(currentSpeed);
    digitalWrite(leftStepPin, LOW); digitalWrite(rightStepPin, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void moveBackward(int steps) {
  digitalWrite(leftDirPin, LOW); digitalWrite(rightDirPin, LOW);
  for (int i = 0; i < steps; i++) {
    digitalWrite(leftStepPin, HIGH); digitalWrite(rightStepPin, HIGH);
    delayMicroseconds(currentSpeed);
    digitalWrite(leftStepPin, LOW); digitalWrite(rightStepPin, LOW);
    delayMicroseconds(currentSpeed);
  }
}

void rotateRobot(float degrees) {
  float arc = (robotWidth * PI * abs(degrees)) / 360.0;
  int steps = (arc / wheelCircumference) * stepsPerRev;
  digitalWrite(leftDirPin, degrees > 0 ? HIGH : LOW);
  digitalWrite(rightDirPin, degrees > 0 ? LOW : HIGH);
  for (int i = 0; i < steps; i++) {
    digitalWrite(leftStepPin, HIGH); digitalWrite(rightStepPin, HIGH);
    delayMicroseconds(currentSpeed);
    digitalWrite(leftStepPin, LOW); digitalWrite(rightStepPin, LOW);
    delayMicroseconds(currentSpeed);
    updateYaw();
  }
}

void autonomousNavigate() {
  if (currentDistance > minObstacle * 2) moveForward(20);
  else if (currentDistance < criticalDist) {
    stopMoving(); moveBackward(30); rotateRobot(180);
  } else {
    float bestAngle = findBestPath();
    if (bestAngle != -999) rotateRobot(bestAngle);
  }
}

float findBestPath() {
  float bestScore = 0, bestAngle = -999;
  for (int a = -60; a <= 60; a += 10) {
    rotateRobot(a);
    delay(100);
    float d = 0; for (int i = 0; i < 3; i++) { d += readDistanceCM(); delay(20); }
    float avg = d / 3.0;
    float score = avg * (1.0 - abs(a) / 90.0);
    if (score > bestScore) { bestScore = score; bestAngle = a; }
    updatePathMemory(avg, a);
  }
  rotateRobot(-60);
  return bestAngle;
}

void updatePathMemory(float d, float a) {
  pathMemory[pathIndex][0] = d; pathMemory[pathIndex][1] = a;
  pathIndex = (pathIndex + 1) % pathMemSize;
}

float readDistanceCM() {
  digitalWrite(trigPin, LOW); delayMicroseconds(2);
  digitalWrite(trigPin, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  long dur = pulseIn(echoPin, HIGH, 30000);
  return dur == 0 ? 999 : dur * 0.034 / 2;
}

void updateYaw() {
  if (millis() - lastIMUUpdate < 10) return;
  int16_t gx, gy, gz;
  imu.getRotation(&gx, &gy, &gz);
  float dt = (millis() - lastIMUUpdate) / 1000.0;
  lastIMUUpdate = millis();
  yaw += (gz / 131.0) * dt;
  if (yaw > 360) yaw -= 360; if (yaw < 0) yaw += 360;
}

void stopMoving() {
  digitalWrite(leftEnablePin, HIGH);
  digitalWrite(rightEnablePin, HIGH);
  delay(10);
  digitalWrite(leftEnablePin, LOW);
  digitalWrite(rightEnablePin, LOW);
}

void broadcastSensorData() {
  if (!deviceConnected) return;
  float temp = imu.getTemperature() / 340.0 + 36.53;
  StaticJsonDocument<200> doc;
  doc["distance"] = currentDistance;
  doc["battery"] = 100.0;
  doc["temperature"] = temp;
  doc["heading"] = yaw;
  String output; serializeJson(doc, output);
  pSensorChar->setValue(output.c_str()); pSensorChar->notify();
}
