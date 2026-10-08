#ifndef COMMAND_PROTOCOL_H
#define COMMAND_PROTOCOL_H

#include <stddef.h>
#include <string.h>
#include "types.h"
#include "config.h"

// One ASCII command per GATT write, optional final LF for manual clients.
// Numbered writes use 1..65535; malformed parameters never become movement/STOP.
inline bool parseRobotCommand(const char* input, size_t length, Command& out) {
  out = Command{'?', 0};
  if (!input || length == 0 || length > 20) return false;
  if (input[length - 1] == '\n') --length;
  if (length == 0) return false;
  size_t start = 0;
  if (input[0] >= '0' && input[0] <= '9') {
    unsigned int id = 0;
    while (start < length && input[start] >= '0' && input[start] <= '9') {
      id = id * 10 + (input[start++] - '0');
      if (id > 65535) return false;
    }
    if (!id || start >= length || input[start++] != ':') return false;
    out.id = static_cast<uint16_t>(id);
  }
  const char* command = input + start;
  const size_t size = length - start;
  struct Token { const char* text; char type; int value; };
  const Token tokens[] = {{"STOP", 'S', 0}, {"AUTO_NAV", 'A', 1},
    {"AUTO_OFF", 'A', 0}, {"CALIBRATE", 'C', 0},
    {"CLOOP_ON", 'K', 1}, {"CLOOP_OFF", 'K', 0}};
  for (const auto& token : tokens) {
    if (strlen(token.text) == size && memcmp(command, token.text, size) == 0) {
      out.type = token.type;
      out.value = token.value;
      return true;
    }
  }
  if (size < 2 || (command[0] != 'F' && command[0] != 'B' &&
                  command[0] != 'L' && command[0] != 'R')) return false;
  const unsigned int limit = (command[0] == 'F' || command[0] == 'B')
    ? MAX_MOVE_DISTANCE_CM : MAX_TURN_ANGLE;
  unsigned int value = 0;
  for (size_t i = 1; i < size; ++i) {
    if (command[i] < '0' || command[i] > '9') return false;
    value = value * 10 + (command[i] - '0');
    if (value > limit) return false;
  }
  out.type = command[0];
  out.value = static_cast<int>(value);
  return true;
}

#endif
