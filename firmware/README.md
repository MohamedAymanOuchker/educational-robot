# E-Bug ESP32 firmware

The supported firmware is `src/`, built with PlatformIO for an ESP32 Dev Module. It controls two **28BYJ-48 motors through ULN2003 boards**. The archived `legacy/arduino_main/` sketch is historical reference and is not a supported firmware option for this release.

## Wiring and calibration

The old STEP/DIR wiring does not apply. Rewire each ULN2003 board in its marked IN1–IN4 order:

| Connection | ESP32 GPIOs |
|---|---|
| Left ULN2003 IN1, IN2, IN3, IN4 | 26, 27, 25, 33 |
| Right ULN2003 IN1, IN2, IN3, IN4 | 14, 13, 32, 23 |
| HC-SR04 trigger, echo | 5, 18 |
| MPU6050 SDA, SCL | 21, 22 |
| Battery divider ADC input | 35 |

See [the wiring guide](../hardware/wiring.md) and [selected motor/power parts](../hardware/power-system.md) before applying power. The reference design uses 5 V motors, a protected 2S Li-ion pack and a fixed 5 V regulator. Check existing parts against that selection. Share logic ground; reduce the HC-SR04 Echo voltage and verify the battery divider before connecting the ESP32. Firmware cannot select or verify the motor's physical voltage rating.

The driver uses an eight-phase half-step sequence, nominal **4096 half-steps per output revolution**, and **2000 microseconds per half-step** (500 half-steps/s, subject to RTOS scheduling). Gearbox variants differ: calibrate steps/revolution, the retained 65mm wheel diameter and 150mm track width against the actual robot. These geometry values are assumptions, not measured results.

The [physical acceptance record](../docs/hardware-acceptance.md#motion-calibration) provides calibration formulas and trial tables, including external gearing. Use the [assembly sequence](../docs/assembly-guide.md) to keep USB programming separate from powered motor tests. No runtime calibration command replaces those measurements.

`LEFT_MOTOR_INVERT=false` and `RIGHT_MOTOR_INVERT=true` assume mirrored mounting. Check forward, backward and both turns with wheels raised, and adjust these constants to match the wiring/mounting. Motors start deenergized and release their coils after each movement. STOP deenergizes all eight outputs and stays latched until a new explicit command is accepted. Old stored motor-speed settings are not loaded.

## Build, test and upload

Install PlatformIO Core, then run from this folder:

```sh
pio run
python test/host/run_tests.py
```

The host tests require Python and a C++17 compiler (`g++` or `clang++`, or set `CXX`). They compile the production source with hardware/FreeRTOS/BLE doubles. They check parsing, coils, cancellation races, queue capacity, sensor failures/freshness and navigation thresholds. They do not validate motor torque, actual radio delivery, power integrity or physical stopping distance.

The reproducible build pins Espressif32 7.0.1, ArduinoJson 6.21.6 and MPU6050 1.4.5. Only upload after checking the wiring and motor voltage:

```sh
pio run --target upload
pio device monitor
```

Serial monitoring uses 115200 baud. Board flashing is not part of the automated checks.

## BLE commands and results

The complete app/firmware contract is in [BLE protocol](../docs/ble-protocol.md). UUIDs remain unchanged. Send one ASCII command in one GATT write, with a request ID from 1 through 65535 and a trailing newline:

```text
1:F20
2:L90
3:STOP
```

| Command | Meaning |
|---|---|
| `F0` through `F500` | Forward distance in centimetres |
| `B0` through `B500` | Backward distance in centimetres |
| `L0` through `L360`, `R0` through `R360` | Turn angle in degrees |
| `STOP`, `AUTO_OFF` | Priority stop, cancel queue and leave autonomous mode |
| `AUTO_NAV` | Enable autonomous mode; completion confirms mode activation |
| `CLOOP_OFF` | Confirm the supported open-loop turning mode |
| `CALIBRATE`, `CLOOP_ON` | Explicit error: unavailable in this release |

Unnumbered commands are accepted for manual diagnostics and return ID 0. Runtime recalibration and closed-loop turns are not enabled. Initial IMU calibration may still run at boot if no calibration is stored; keep the robot still during startup.

Unknown commands, negative/fractional values, overflow, trailing garbage and overlong writes are rejected. They never become STOP or a clamped movement. Queue-full requests return errors. STOP bypasses the queue, cancels pending commands and prevents previously dequeued commands from rearming motion. Disconnection performs the same physical stop and queue cancellation; results cannot be delivered while disconnected.

All responses are newline-delimited JSON on the sensor notification characteristic. Records are split into chunks of at most 20 bytes; clients must buffer until newline. Complete records are serialized under a mutex so telemetry and command responses cannot interleave.

```json
{"type":"command","id":1,"status":"done"}
{"type":"command","id":2,"status":"cancelled","message":"stopped during command"}
{"type":"telemetry","distance":null,"distance_valid":false,"distance_age_ms":320,"battery":80,"heading":0,"temperature":25,"timestamp":10200}
```

An autonomous safety abort also emits `{"type":"fault","message":"..."}` so the app fails the active program even after mode activation was acknowledged. A user STOP alone does not emit a fault.

A blocked/aborted movement returns `error`/`cancelled`, never `done`. A failed movement also cancels the remaining queued program. `AUTO_NAV` runs until STOP/AUTO_OFF, disconnect or a sensing failure; the mobile app bounds its autonomous block to three seconds and then sends STOP.

## Sensing and remaining hardware checks

Ultrasonic sampling is scheduled every 60ms, with trigger spacing shared by all callers. No echo or out-of-range echo immediately invalidates the range. A successful sample older than 250ms is also invalid. Forward motion checks this coherent sensor snapshot at every half-step; missing/stale distance or a reading below 15cm stops the movement. Invalid range is reported as JSON `null`, never a false-clear 999cm value.

The sensor task services IMU integration nominally every 10ms (ultrasonic echo waits can delay it). Telemetry is sent separately every 250ms. Heading is an uncorrected gyro estimate and may drift; MPU6050 temperature is die temperature. Battery percentage depends on the configured pack/divider calibration.

Autonomous forward steps cover the previous 25–50cm dead zone. Invalid range or critically close obstacles stop autonomous operation. The existing turning/scanning heuristic remains experimental. There is no rear/side sensor: supervise backward movement and rotations. Bench validation must still establish motor direction, distance/angle calibration, reliable BLE stop/disconnect behavior, voltage levels, and stopping clearance on the actual robot.
