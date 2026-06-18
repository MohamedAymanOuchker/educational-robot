#ifndef NAVIGATION_H
#define NAVIGATION_H

#include "types.h"
#include "config.h"

class Navigation {
private:
  // State
  bool isAutonomousMode;
  unsigned long lastNavigationUpdate;
  float lastBestAngle;
  int stuckCounter;

  // Path memory (circular buffer)
  PathMemoryEntry pathMemory[PATH_MEMORY_SIZE];
  int pathIndex;

  // Path planning helpers
  float findBestPath();
  float calculateScore(float distance, float angle);
  bool hasRecentPath(float angle, float tolerance);
  void updatePathMemory(float distance, float angle);
  void clearPathMemory();

  // Recovery maneuvers
  void emergencyManeuver();
  void avoidStuckSituation();
  void performUTurn();

public:
  Navigation();

  // Initialization
  void begin();

  // Mode control
  void enableAutonomousMode();
  void disableAutonomousMode();
  bool isAutonomous() const;

  // Main autonomous step (called from the motor task)
  void executeAutonomousStep();

  // Environment analysis
  bool detectDeadEnd();
  void scanEnvironment();

  // Diagnostics
  void printPathMemory();
  void printNavigationStats();
  int getPathMemorySize() const;
  void resetNavigationStats();
};

// Global navigation instance
extern Navigation navigator;

#endif // NAVIGATION_H
