# P1 finalization status

Development revision: 8 October 2026. This file records what has been fixed and what still needs evidence; it is not a hardware sign-off.

## Software work

The current P1 change aligns the mobile app and firmware through [numbered commands and completion records](ble-protocol.md), replaces generated-text execution with typed block execution, fixes parameter editing/nesting, and introduces stop/disconnect cancellation and sensor validity checks. Autonomous safety faults now fail the active app program instead of appearing successful after its timer expires.

The motor implementation now targets the owner's confirmed **28BYJ-48 + ULN2003** hardware. It requires the [new eight-input wiring](../hardware/wiring.md), nominal half-step calibration and physical direction checks. The old STEP/DIR wiring and archived Arduino sketch do not apply to this revision.

## Validation

- **Firmware host regression suite: passed, 903 assertions.** Production firmware is compiled against test doubles for GPIO, sensors, BLE and RTOS facilities. Checks cover strict parsing/ranges, left/right coil sequences, STOP during motion, queue overflow, cancellation of already dequeued work, disconnect, failed/stale sensing, the 25–50cm navigation range, safety faults and concurrent notification producers. Run `python firmware/test/host/run_tests.py` with a C++17 compiler available.
- **ESP32 PlatformIO build: passed.** PlatformIO 6.1.18, Espressif32 7.0.1, ArduinoJson 6.21.6 and MPU6050 1.4.5. RAM usage: 39,972 / 327,680 bytes; flash usage: 1,190,949 / 1,310,720 bytes. This verifies compilation, not a flashed or measured robot.
- **Flutter regression suite: passed, 38 tests.** Covers mutable block parameters, editing limits, nesting/reparenting, independent program snapshots, true/false conditions, completion ordering, malformed/fragmented notifications, stale/incomplete telemetry, autonomous faults, failed writes, command deadlines, STOP retry, unconfirmed STOP disconnection, route exit, backgrounding and disposal. Uses simulated transport/robot clients; it does not validate Android Bluetooth on a physical phone.
- **Flutter analysis: passed with `--no-fatal-infos`.** No errors or warnings; 217 informational lints remain. Toolchain: Flutter 3.41.4 / Dart 3.11.1.
- **Android debug APK: built successfully** from the final app source with `flutter build apk --debug --no-pub`. Local output: `mobile-app/build/app/outputs/flutter-apk/app-debug.apk`. The incremental final build completed in 71.9 seconds. It is a debug-signed test package and has not been installed or tested against a physical robot in this pass.

CI now runs the firmware host suite/build and the app analysis/tests/Android debug build. App failures are no longer ignored. The workflow itself has not been run remotely in this change. Informational style lints are allowed; errors and warnings fail analysis. Kotlin 1.8.22 produced a future-support warning at this checkpoint; the subsequent [P2 toolchain update](p2-status.md#completed-android-release-preparation) resolves it. Release signing/store distribution and iOS builds remain outside this P1 validation.

Runtime `CALIBRATE` and `CLOOP_ON` explicitly return errors while unvalidated. Open-loop motion completion means the requested coil sequence finished, not that wheel displacement was independently measured. The front sensor does not protect the robot's rear or sides. Auto Navigate is an experimental reactive behavior bounded to three seconds by the app; no-path recovery now stops instead of reversing blindly.

## Items requiring the physical build or original records

**Motor and power selection is complete:** the owner authorized choosing the parts, and the [reference power system](../hardware/power-system.md) now records exact motor, battery, regulator and charger models, sources, a current budget, fuse/harness requirements and charging instructions. Existing firmware voltage endpoints match the chosen pack; only explanatory comments changed. This closes the selection decision, not the physical acceptance checks below.

- **Hardware acceptance remains open:** obtain or verify parts against the selected models, assemble the fused harness, check eight-input wiring, supply and divider voltages, motor directions, mechanical ratios, wheel dimensions, stop latency and sensor-failure behavior. No robot was attached during code development. The selected motor mounting pattern must be reconciled with the CAD before printing.
- **Printable hardware remains open:** the [CAD inventory and release checklist](../hardware/cad-release.md) now identify 10 native parts and 4 assemblies by filename, size and hash. The two Part3 files are byte-identical and retained pending reference checks. The owner will install CATIA later; geometry, STL/neutral exports, tolerances and assembled part/gear mapping remain unverified. Export from the actual validated design rather than inventing replacement geometry.
- **Research reconciliation remains open:** the study is author-confirmed as real, but the supplied paper folder contains aggregates rather than the original analysis records needed to resolve contradictions. See [the reconciliation checklist](research-reconciliation.md). Existing results have not been replaced with guessed numbers.

Do not label the entire project finalized until these open items are completed. Program persistence and practice progress are now addressed in the [P2 update](p2-status.md); expanded curriculum/loops, iOS release support and other P2 work remain separate from this P1 pass. The validation figures above record the P1 checkpoint; the P2 status records subsequent app validation.
