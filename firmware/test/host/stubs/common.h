
#pragma once
#include <string>
#include <vector>
#include <deque>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <algorithm>
#include <cstdio>
#include <cstdint>
#include <atomic>
#include <mutex>
#include <functional>
#include <map>
#include <sstream>
#include <type_traits>
#include <thread>
using std::abs;
inline std::atomic<uint64_t> testMicros {1000000};
inline unsigned long millis() { return testMicros / 1000; }
inline std::function<void(unsigned long)> delayHook;
inline void delay(unsigned long ms) { testMicros += ms * 1000; if (delayHook) delayHook(ms); }
inline void delayMicroseconds(unsigned long us) { testMicros += us; }
inline long echoDuration = 0;
inline long pulseIn(int,int,unsigned long) { return echoDuration; }
inline uint32_t analogReadMilliVolts(int) { return 2500; }
inline long random(long a,long b) { return a; }
#define PI 3.14159265358979323846
#define HIGH 1
#define LOW 0
#define OUTPUT 1
#define INPUT 0
#define pdTRUE 1
#define pdMS_TO_TICKS(v) (v)
#define portMAX_DELAY 9999999
inline int risingSteps=0;
inline int pins[40] = {};
inline std::vector<int> leftCoilPatterns;
inline std::vector<int> rightCoilPatterns;
inline bool collectCoils = false;
inline void pinMode(int,int) {}
inline void digitalWrite(int pin,int value) {
  pins[pin]=value;
  if(pin==23 && collectCoils) {
    int pattern=pins[26]*8+pins[27]*4+pins[25]*2+pins[33];
    leftCoilPatterns.push_back(pattern);
    rightCoilPatterns.push_back(pins[14]*8+pins[13]*4+pins[32]*2+pins[23]);
    if(pattern) ++risingSteps;
  }
}
template<class T> T constrain(T x,T low,T high) { return std::min(high,std::max(low,x)); }
class String {
  std::string s;
 public:
  String() = default;
  String(const char* v):s(v) {}
  String(std::string v):s(v) {}
  String(char c):s(1,c) {}
  String(int n):s(std::to_string(n)) {}
  const char* c_str() const { return s.c_str(); }
  size_t length() const {return s.length();}
  void trim() { auto a=s.find_first_not_of(" \t\r\n"), b=s.find_last_not_of(" \t\r\n"); s=a==std::string::npos?"":s.substr(a,b-a+1); }
  bool startsWith(const char* p) const {return s.rfind(p,0)==0;}
  String substring(size_t n) const {return s.substr(n);}
  long toInt() const {return std::atol(s.c_str());}
  bool operator==(const char* other) const {return s==other;}
  friend String operator+(const String& a,const String& b) {return a.s+b.s;}
};
struct SerialStub { void begin(int){} template<class...T> void print(T...){} template<class...T> void println(T...){} template<class...T> void printf(T...){} };
inline SerialStub Serial;
struct ESPStub { const char* getChipModel(){return "host";} int getCpuFreqMHz(){return 240;} int getFreeHeap(){return 100000;} int getFlashChipSize(){return 4000000;} };
inline ESPStub ESP;
using TaskHandle_t = void*;
using TickType_t = unsigned int;
using portMUX_TYPE = std::recursive_mutex;
#define portMUX_INITIALIZER_UNLOCKED {}
#define portENTER_CRITICAL(m) (m)->lock()
#define portEXIT_CRITICAL(m) (m)->unlock()
inline void xTaskCreatePinnedToCore(...) {}
inline void vTaskDelay(int ms) {delay(ms);}
struct Queue {size_t capacity,size;std::deque<std::vector<unsigned char>> items;};
using QueueHandle_t = Queue*;
inline QueueHandle_t xQueueCreate(size_t n,size_t z){return new Queue{n,z,{}};}
inline int xQueueSend(QueueHandle_t q,const void* ptr,int){if(q->items.size()==q->capacity)return 0;const auto* bytes=(const unsigned char*)ptr;q->items.emplace_back(bytes,bytes+q->size);return 1;}
inline int xQueueReceive(QueueHandle_t q,void* ptr,int){if(q->items.empty())return 0;memcpy(ptr,q->items.front().data(),q->size);q->items.pop_front();return 1;}
inline int uxQueueMessagesWaiting(QueueHandle_t q){return q->items.size();}
inline void xQueueReset(QueueHandle_t q){q->items.clear();}
inline void vQueueDelete(QueueHandle_t q){delete q;}
using SemaphoreHandle_t = std::mutex*;
inline SemaphoreHandle_t xSemaphoreCreateMutex(){return new std::mutex;}
inline void xSemaphoreTake(SemaphoreHandle_t m,int){m->lock();}
inline void xSemaphoreGive(SemaphoreHandle_t m){m->unlock();}
inline void vSemaphoreDelete(SemaphoreHandle_t m){delete m;}
class Preferences {public: bool begin(const char*,bool){return false;} void end(){} int getInt(const char*,int d){return d;} bool getBool(const char*,bool d){return d;} short getShort(const char*,int d){return d;} void putInt(const char*,int){} void putShort(const char*,short){} void putBool(const char*,bool){} };
inline int16_t testGz = 0;
class MPU6050 {public: void initialize(){} bool testConnection(){return true;} void getMotion6(int16_t*a,int16_t*b,int16_t*c,int16_t*d,int16_t*e,int16_t*f){*a=*b=*c=*d=*e=0;*f=testGz;} void getRotation(int16_t*a,int16_t*b,int16_t*c){*a=*b=0;*c=testGz;} int16_t getTemperature(){return 0;} void getAcceleration(int16_t*a,int16_t*b,int16_t*c){*a=*b=*c=0;} };
struct WireStub {void begin(int,int){}};
inline WireStub Wire;
inline std::string jsonQuote(const char* s) {
  std::string result="\"";
  for(;*s;++s) { if(*s=='\\' || *s=='"') result+='\\'; result+=*s; }
  return result+"\"";
}
template<size_t N> class StaticJsonDocument {
 public:
  std::map<std::string,std::string> fields;
  struct Field {
    std::string& out;
    void operator=(const char* v){out=jsonQuote(v);}
    void operator=(const String& v){out=jsonQuote(v.c_str());}
    void operator=(std::nullptr_t){out="null";}
    void operator=(bool v){out=v?"true":"false";}
    template<class T> void operator=(T v){ std::ostringstream s; s<<v; out=s.str(); }
  };
  Field operator[](const char* key) {return {fields[key]};}
};
template<class T> void serializeJson(T& doc,String& out){
  std::string s="{"; bool first=true;
  for(const auto& field:doc.fields) {if(!first)s+=",";first=false;s+=jsonQuote(field.first.c_str())+":"+field.second;}
  out=String(s+"}");
}
inline std::vector<std::string> notifications;
class BLEServer;
class BLECharacteristic;
class BLEServerCallbacks {public:virtual ~BLEServerCallbacks()=default;virtual void onConnect(BLEServer*){} virtual void onDisconnect(BLEServer*){}};
class BLECharacteristicCallbacks {public:virtual ~BLECharacteristicCallbacks()=default;virtual void onWrite(BLECharacteristic*){}};
class BLE2902 {};
class BLECharacteristic {public:static constexpr int PROPERTY_WRITE=1, PROPERTY_NOTIFY=2; void setCallbacks(BLECharacteristicCallbacks*){} void addDescriptor(BLE2902*){} std::string value; void setValue(uint8_t* p,size_t n){value.assign((char*)p,n);} void notify(){notifications.push_back(value);} std::string getValue(){return "";}};
class BLEService {public: BLECharacteristic* createCharacteristic(const char*,int){return new BLECharacteristic;} void start(){}};
class BLEAdvertising {public:void addServiceUUID(const char*){} void setScanResponse(bool){} void setMinPreferred(int){}};
class BLEServer {public:void setCallbacks(BLEServerCallbacks*){} BLEService* createService(const char*){return new BLEService;} void startAdvertising(){} void disconnect(int){} int getConnId(){return 0;}};
class BLEDevice {public: static void init(const char*){} static BLEServer* createServer(){return new BLEServer;} static BLEAdvertising* getAdvertising(){static BLEAdvertising a;return &a;} static void startAdvertising(){} struct Address{std::string toString(){return "host";}}; static Address getAddress(){return {};}};
