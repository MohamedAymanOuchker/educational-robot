# Host regression doubles

`run_tests.py` compiles `harness.cpp`, which includes the production firmware sources directly. The stubs emulate the Arduino, BLE and FreeRTOS APIs needed by those sources. Motor GPIO writes and BLE notification fragments are recorded, and delay hooks reproduce STOP arriving during a blocking movement. Real mutexes protect the emulated critical sections.

JSON serialization is a small test double; the PlatformIO build checks integration with the pinned ArduinoJson library. These tests establish software behavior, not physical safety or over-the-air delivery. Run a full firmware build and the hardware acceptance checks in `../../README.md` as well.
