#include "common.h"
#define private public
#include "../../src/motor_control.cpp"
#include "../../src/sensor_manager.cpp"
#include "../../src/ble_communication.cpp"
#include "../../src/navigation.cpp"
#include "../../src/main.cpp"
#undef private

#include <cassert>
#include <iostream>

static int assertions = 0;
#define CHECK(expr) do { ++assertions; if (!(expr)) {std::cerr << "FAIL line " << __LINE__ << ": " << #expr << "\n"; std::exit(1);} } while (0)

void send(const char* input) { bleManager.processCommand(input, strlen(input)); }
void goodDistance(float cm = 100) {
  sensorManager.sensorData.distance = cm;
  sensorManager.sensorData.distanceValid = true;
  sensorManager.sensorData.distanceTimestamp = millis();
}
void reset() {
  delayHook = nullptr;
  bleManager.deviceConnected = true;
  bleManager.stopAll();
  notifications.clear();
  leftCoilPatterns.clear();
  rightCoilPatterns.clear();
  risingSteps = 0;
  goodDistance();
}
std::string output() {
  std::string out;
  for (const auto& chunk : notifications) { CHECK(chunk.size() <= 20); out += chunk; }
  return out;
}
bool result(uint16_t id, const char* status) {
  const std::string out = output();
  std::istringstream records(out);
  std::string line;
  while (std::getline(records, line)) {
    if (line.find("\"id\":"+std::to_string(id)+",") != std::string::npos &&
        line.find("\"status\":\""+std::string(status)+"\"") != std::string::npos) return true;
  }
  return false;
}
void drain() { while (bleManager.hasCommand()) executeCommand(bleManager.getNextCommand()); }
void parserTests() {
  for (const char* valid : {"1:F100\n", "65535:R360\n", "9:B500", "3:L0\n", "1:STOP\n", "2:AUTO_NAV\n", "2:AUTO_OFF\n", "F0", "2:CALIBRATE\n", "2:CLOOP_OFF\n"}) {
    Command cmd; CHECK(parseRobotCommand(valid,strlen(valid),cmd)); CHECK(cmd.type!='?');
  }
  for (const char* bad : {"", "\n", "F", "R", "F-1", "F501", "L361", "F1x", "F 5", "F1.5", "GET_SENSORS", "FORWARD:100", "LEFT:90", "0:F1", "65536:F1", "999999999999999:F1", "1:F99999999999999", "1:STOPX", "1:F1\n2:F1", "1: F1", "1:F1\r\n"}) {
    Command cmd; CHECK(!parseRobotCommand(bad,strlen(bad),cmd));
  }
  const char nul[] = {'1', ':', 'F', '1', '\0', '2'};
  Command cmd; CHECK(!parseRobotCommand(nul,sizeof(nul),cmd));
  CHECK(parseRobotCommand("65535:F500\n",11,cmd)); CHECK(cmd.id==65535 && cmd.value==500);
  reset(); send("10:GET_SENSORS\n"); CHECK(result(10,"error")); CHECK(bleManager.getQueueSize()==0); CHECK(motorController.isStopPending());
  std::cout << "PASS strict parser, bounds, overflow and malformed commands\n";
}
void coilTests() {
  reset(); motorController.arm(motorController.getGeneration()); collectCoils=true;
  motorController.leftPhase=0; motorController.rightPhase=0;
  CHECK(motorController.moveBackwardSteps(8)==MotionResult::Done);
  const std::vector<int> expected = {9,1,3,2,6,4,12,8,0};
  CHECK(leftCoilPatterns==expected); CHECK(risingSteps==8);
  const std::vector<int> forward = {12,4,6,2,3,1,9,8,0};
  CHECK(rightCoilPatterns==forward); // opposite electrical sequence for mirrored mounting
  for (int pin : {26,27,25,33,14,13,32,23}) CHECK(pins[pin]==0);
  CHECK(motorController.getSpeed()==2000);
  CHECK(motorController.distanceToSteps(10)>=2000 && motorController.distanceToSteps(10)<=2010);
  leftCoilPatterns.clear(); rightCoilPatterns.clear();
  CHECK(motorController.moveForwardSteps(8)==MotionResult::Done);
  CHECK(leftCoilPatterns==forward); CHECK(rightCoilPatterns==expected);
  std::cout << "PASS ULN2003 eight-phase sequence, nominal gearing and coil release\n";
}
void framingTests() {
  reset();
  const std::string first = "{\"producer\":1,\"payload\":\"abcdefghijklmnopqrstuvwxyz0123456789\"}";
  const std::string second = "{\"producer\":2,\"payload\":\"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\"}";
  std::atomic<int> ready{0};
  auto transmit=[&](const std::string& record) {
    ++ready;
    while(ready.load()<2) std::this_thread::yield();
    bleManager.broadcastSensorData(String(record));
  };
  std::thread a(transmit, std::cref(first));
  std::thread b(transmit, std::cref(second));
  a.join(); b.join();
  const std::string all=output();
  CHECK(all==first+"\n"+second+"\n" || all==second+"\n"+first+"\n");
  std::cout << "PASS concurrent NDJSON producers keep complete records serialized\n";
}
void stopTests() {
  reset(); send("1:B100\n"); send("2:R90\n"); const Command stale=bleManager.getNextCommand();
  send("3:STOP\n"); CHECK(motorController.isStopPending()); CHECK(bleManager.getQueueSize()==0);
  CHECK(result(2,"cancelled")); CHECK(result(3,"done"));
  executeCommand(stale); CHECK(result(1,"cancelled")); CHECK(risingSteps==0);
  send("4:B1\n"); drain(); CHECK(result(4,"done")); CHECK(risingSteps>0);

  reset(); send("5:B100\n"); bool triggered=false;
  delayHook=[&](unsigned long ms) { if (ms==2 && !triggered) {triggered=true;send("6:STOP\n");} };
  drain(); delayHook=nullptr;
  CHECK(triggered); CHECK(result(5,"cancelled")); CHECK(!result(5,"done")); CHECK(result(6,"done"));
  CHECK(risingSteps==1); CHECK(motorController.isStopPending());
  for (int pin : {26,27,25,33,14,13,32,23}) CHECK(pins[pin]==0);

  reset();
  for(int i=0;i<COMMAND_QUEUE_SIZE;++i) send((std::to_string(20+i)+":B1\n").c_str());
  send("31:B1\n"); CHECK(result(31,"error"));
  send("32:STOP\n"); CHECK(result(32,"done")); CHECK(bleManager.getQueueSize()==0);
  for(int i=0;i<COMMAND_QUEUE_SIZE;++i) CHECK(result(20+i,"cancelled"));

  reset(); send("40:AUTO_NAV\n"); drain(); CHECK(navigator.isAutonomous());
  send("41:B1\n"); const Command priorDisconnect=bleManager.getNextCommand();
  bleManager.serverCallbacks->onDisconnect(nullptr); CHECK(!navigator.isAutonomous()); CHECK(motorController.isStopPending());
  executeCommand(priorDisconnect); CHECK(risingSteps==0);
  bleManager.serverCallbacks->onConnect(nullptr); CHECK(motorController.isStopPending());
  send("42:B1\n"); drain(); CHECK(result(42,"done"));
  std::cout << "PASS priority STOP, in-flight interruption, queue-full, stale dequeue and disconnect\n";
}
void sensorTests() {
  reset(); sensorManager.sensorData.temperature=20;
  echoDuration=5800; CHECK(std::isfinite(sensorManager.readDistanceCM())); CHECK(sensorManager.isDistanceValid());
  echoDuration=0; CHECK(std::isnan(sensorManager.readDistanceCM())); CHECK(!sensorManager.isDistanceValid()); CHECK(motorController.checkObstacle());
  CHECK(std::isnan(sensorManager.getCurrentDistance()));
  bleManager.sendTelemetry(sensorManager.getSensorData()); CHECK(output().find("\"distance\":null")!=std::string::npos); CHECK(output().find("\"distance_valid\":false")!=std::string::npos);
  send("50:F1\n"); drain(); CHECK(result(50,"error")); CHECK(!result(50,"done")); CHECK(risingSteps==0);
  goodDistance(); delay(DISTANCE_MAX_AGE_MS+1); CHECK(!sensorManager.isDistanceValid());
  send("51:F1\n"); drain(); CHECK(result(51,"error")); CHECK(risingSteps==0);
  goodDistance(10); send("52:F1\n"); drain(); CHECK(result(52,"error")); CHECK(risingSteps==0);
  goodDistance(); send("53:F10\n"); drain(); CHECK(result(53,"error")); CHECK(risingSteps>0 && risingSteps<2010);
  std::cout << "PASS failed/expired echo invalidation, null telemetry, obstacle and mid-motion stale stop\n";
}
void navigationTests() {
  for(float cm : {25.1f,30.0f,50.0f,51.0f}) {
    reset(); goodDistance(cm); send("60:AUTO_NAV\n"); drain(); CHECK(result(60,"done"));
    delay(501); goodDistance(cm);
    delayHook=[cm](unsigned long ms) {if(ms==2)goodDistance(cm);};
    navigator.executeAutonomousStep(); delayHook=nullptr;
    CHECK(risingSteps>0); CHECK(navigator.isAutonomous());
  }
  reset(); send("61:AUTO_NAV\n"); drain(); delay(501);
  navigator.executeAutonomousStep(); CHECK(risingSteps==0); CHECK(!navigator.isAutonomous());
  CHECK(output().find("\"type\":\"fault\"")!=std::string::npos);
  reset(); goodDistance(10); send("62:AUTO_NAV\n"); drain(); delay(501); goodDistance(10);
  navigator.executeAutonomousStep(); CHECK(risingSteps==0); CHECK(!navigator.isAutonomous());
  CHECK(output().find("\"type\":\"fault\"")!=std::string::npos);
  reset(); send("65:AUTO_NAV\n"); drain(); send("66:STOP\n");
  CHECK(output().find("\"type\":\"fault\"")==std::string::npos);
  reset(); send("63:CALIBRATE\n"); send("64:CLOOP_ON\n"); CHECK(result(63,"error")); CHECK(result(64,"error")); CHECK(bleManager.getQueueSize()==0);
  std::cout << "PASS 25-50cm autonomous progression, fail-closed sensing, explicit unsupported modes\n";
}
int main() {
  bleManager.begin(); motorController.begin(); sensorManager.sensorData.temperature=20;
  parserTests(); coilTests(); stopTests(); sensorTests(); navigationTests(); framingTests();
  std::cout << "All host regressions passed (" << assertions << " assertions). Hardware and BLE radio are mocked.\n";
}
