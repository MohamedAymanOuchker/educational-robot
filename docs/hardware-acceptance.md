# Physical robot acceptance record

Blank template prepared 8 October 2026. **All tests are NOT RUN until the tester records observations.** No phone, serial controller or physical robot was available for this documentation pass. CATIA validation/exports are deferred until the owner installs it.

Copy this file for each robot and test session. Use PASS, FAIL, NOT RUN or NOT APPLICABLE with a reason. A blank value is missing evidence, not zero or a pass. Keep this engineering record separate from participant/study data.

## Build identity

| Field | Recorded value |
| --- | --- |
| Robot / build ID | Pending |
| Tester and date | Pending |
| Git commit plus description of uncommitted changes | Pending |
| Firmware binary path + SHA-256 | Pending |
| App package path + SHA-256 / application ID / version | Pending |
| Phone model + Android version | Pending |
| ESP32 board/module revision | Pending |
| Delivered motor / driver labels, photos and polarity | Pending |
| Battery / regulator / charger model + condition | Pending |
| Harness connector, fuse, switch and wire identification | Pending |
| CAD assembly/revision + source hashes + export record | Pending |
| Mechanical dimensions / external gearing | Pending |
| Surface, payload and ambient conditions | Pending |
| Meter / timing / temperature instruments and resolution | Pending |

Use `Get-FileHash -Algorithm SHA256 -LiteralPath 'exact-file-path'` in PowerShell to identify a tested binary. A Git commit alone does not identify uncommitted firmware/configuration changes. Preserve the actual package and configuration used for each test.

## Acceptance limits agreed before testing

The power targets below come from the [project power specification](../hardware/power-system.md); they are not measured results. Record the remaining limits before judging a test. A successful protocol response is not proof of physical travel or stopping.

| Quantity | Target / decision required |
| --- | --- |
| Regulated 5 V rail | 4.8–5.2 V at specified test inputs/load and actual operation |
| Regulator test inputs / load | 8.4 V and 6.4 V input, 1.2 A output design load; use appropriate bench equipment |
| Battery operating procedure | Stop/recharge at about 6.4 V under load; no automatic firmware cutoff |
| Echo divider expected DC ratio | 3.3 / (2.2 + 3.3) = 0.6; approximately 3.0 V at 5.0 V input |
| Battery divider expected DC ratio | 10 / (20 + 10) = 1/3; approximately 2.8 V at 8.4 V input |
| Accessible-surface/component temperature limits | Record applicable component limits and an appropriate supervised-use limit before testing: pending |
| Explicit STOP maximum latency / extra travel | Pending; define for the intended test area and activity |
| BLE-loss maximum latency / extra travel | Pending; include radio loss-detection time, not only code response time |
| Linear error / repeatability at chosen distances | Pending |
| Left/right angular error / repeatability | Pending |
| Sensor error / repeatability at intended target distances | Pending |
| Required phone range and environmental conditions | Pending; no 12 m guarantee |

Without an agreed limit and measurement, record the result as NOT RUN or measured-but-not-accepted. Do not treat the absence of a failure message as acceptance.

## A. Mechanical and electrical preflight

Follow the [assembly guide](assembly-guide.md) and [wiring](../hardware/wiring.md). Wiring changes happen with power disconnected. Do not attach USB while the battery/external ESP32 5 V feed is connected.

| ID | Check | Measurement / evidence | Result |
| --- | --- | --- | --- |
| A1 | Native assembly opens; references resolved; part-to-file mapping complete | Pending | NOT RUN |
| A2 | Motor mounting, shaft/hub retention, gear ratio, free rotation and cable clearance | Pending | NOT RUN |
| A3 | Battery retention/removal, insulated terminals, fuse/switch/connector access | Pending | NOT RUN |
| A4 | Disconnected continuity, no supply short, ground/polarity/capacitor checks | Pending | NOT RUN |
| A5 | USB/external 5 V separation and actual ESP32 board pinout | Pending | NOT RUN |
| A6 | 8.4 V input, regulator unloaded and at 1.2 A design load | Pending | NOT RUN |
| A7 | 6.4 V input, regulator unloaded and at 1.2 A design load | Pending | NOT RUN |
| A8 | Battery divider before connection to GPIO35 | Pending | NOT RUN |
| A9 | Echo divider ratio and signal peak before connection to GPIO18 | Pending | NOT RUN |
| A10 | Actual idle/start/motion current, rail transients, fuse behavior | Pending | NOT RUN |
| A11 | Regulator, motor, driver, wiring and accessible-surface temperatures; test duration | Pending | NOT RUN |
| A12 | Charger/pack/harness match and external charging procedure | Pending | NOT RUN |

A multimeter DC reading alone does not measure transient rail droop or the peak of an Echo pulse. Record the instrument and any unmeasured behavior. Do not deliberately short a battery, defeat its protection or discharge it to emergency cutoff as a test.

## B. Stationary sensing and raised-wheel commissioning

Keep the chassis secured, wheels clear, hands away and the disconnect reachable. Restore/check wiring with power off between fault configurations. Use the app's short test programs described in the assembly guide.

| ID | Test | Observation / evidence | Result |
| --- | --- | --- | --- |
| B1 | Startup, connecting and reconnecting cause no uncommanded movement | Pending | NOT RUN |
| B2 | Forward/backward wheel directions and left/right turns agree with commands | Pending | NOT RUN |
| B3 | Single motion waits for completion; coils release after motion | Pending | NOT RUN |
| B4 | Stable front readings with measured targets at intended distances | Pending | NOT RUN |
| B5 | No echo / disconnected Echo signal reports unavailable and prevents forward motion | Pending | NOT RUN |
| B6 | Sensor fault during controlled forward motion stops/fails the action | Pending | NOT RUN |
| B7 | Battery estimate compared with meter; IMU temperature/relative heading interpreted correctly | Pending | NOT RUN |
| B8 | Physical disconnect stops powered drive; record any coasting | Pending | NOT RUN |

For B6, first agree a fault method that does not short or change energized wiring (for example a preinstalled insulated signal switch, or controlled loss of a valid acoustic target). Record the method and raw observation; do not label an arbitrary “far away” reading a guaranteed fault.

### Stop and cancellation observations

Begin with the wheels raised. Repeat relevant cases during short, controlled floor motion only after raised-wheel tests pass. Use video/timing equipment where needed. Record multiple trials, the maximum observed latency, extra wheel/chassis travel, and the app outcome. The reference point is the user action or fault onset, not receipt of a later log line.

| Trigger | Trials / conditions | Maximum measured latency | Extra travel / residual motion | App outcome; no restart on reconnect | Result |
| --- | --- | --- | --- | --- | --- |
| Whole-run Stop during a forward action | Pending | Pending | Pending | Pending | NOT RUN |
| Whole-run Stop during a turn | Pending | Pending | Pending | Pending | NOT RUN |
| Leave Robot Execution | Pending | Pending | Pending | Pending | NOT RUN |
| Background / lock phone | Pending | Pending | Pending | Pending | NOT RUN |
| Disconnect in Connect | Pending | Pending | Pending | Pending | NOT RUN |
| Disable phone Bluetooth / actual radio loss | Pending | Pending | Pending | Pending | NOT RUN |
| Ultrasonic invalid/stale condition during forward motion | Pending | Pending | Pending | Pending | NOT RUN |
| Auto Navigate timeout / fault | Pending | Pending | Pending | Pending | NOT RUN |

Differentiate a confirmed STOP, cancelled program, failed/unconfirmed STOP and disconnected robot. A UI status alone does not establish that physical motion ceased. Rear/side collision protection is not implemented.

## Motion calibration

Do this only after mechanical, power, sensor and stop checks pass. Constants are in `firmware/src/config.h`. The production formulas in `firmware/src/motor_control.cpp` are:

```text
linear half-steps = round(command_cm × 10 × STEPS_PER_REV / (pi × WHEEL_DIAMETER))
turn half-steps per wheel = round(ROBOT_WIDTH × abs(command_degrees) × STEPS_PER_REV
                                 / (360 × WHEEL_DIAMETER))
```

`STEPS_PER_REV` must represent effective half-steps per **wheel** revolution. If external gears exist, multiply motor-output half-steps/revolution by motor-output revolutions per wheel revolution. Verify tooth counts and physical motion; the nominal internal-gear value 4096 is not a measurement.

Record mechanical wheel diameter and centre-to-centre track width first. Resolve slipping, binding or missed steps before numerical correction. Repeat the same motion on the same surface and load; retain every trial, including failed/cancelled ones. Exclude failed motion from parameter fitting with a recorded reason.

| Trial | Command / direction | Actual distance (cm) or angle (degrees) | Surface / load / pack voltage | Completion / slip / notes |
| --- | --- | --- | --- | --- |
| 1 | Pending | Pending | Pending | Pending |
| 2 | Pending | Pending | Pending | Pending |
| 3 | Pending | Pending | Pending | Pending |
| 4 | Pending | Pending | Pending | Pending |
| 5 | Pending | Pending | Pending | Pending |

Copy the table for each distance and turn direction. Begin with 20 cm travel and 45° turns; increase to a longer baseline/90° only when clearance and the preceding checks permit.

For stable, nonzero travel measurements, adjust **one** linear parameter, not both at once:

```text
STEPS_PER_REV_new = STEPS_PER_REV_old × commanded_distance / mean_measured_distance
```

Alternatively, with independently established steps/revolution, use an effective rolling diameter:

```text
WHEEL_DIAMETER_new = WHEEL_DIAMETER_old × mean_measured_distance / commanded_distance
```

After linear calibration, an effective turn-track correction is:

```text
ROBOT_WIDTH_new = ROBOT_WIDTH_old × requested_turn_magnitude / mean_measured_turn_magnitude
```

These formulas follow the open-loop implementation; they are not measured results. Keep physical dimensions and fitted effective parameters separately identified. Round `STEPS_PER_REV` to a suitable integer. Do not average away a left/right discrepancy: inspect mechanics and record each direction's residual error. Rebuild/reflash and repeat tests after changes. Significant gearing/speed changes also require checking the app's command deadlines; a timeout must not be relabeled as successful completion.

| Parameter | Before | Measured basis / calculation | After | Retest evidence |
| --- | --- | --- | --- | --- |
| Effective half-steps / wheel revolution | Pending | Pending | Pending | Pending |
| Physical / effective wheel diameter (mm) | Pending | Pending | Pending | Pending |
| Physical / effective track width (mm) | Pending | Pending | Pending | Pending |
| Left/right inversion and step interval | Pending | Pending | Pending | Pending |

## C. Physical phone and lesson checks

| ID | Test | Phone / conditions / evidence | Result |
| --- | --- | --- | --- |
| C1 | First-run permission grant/denial/retry; Bluetooth off/on | Pending | NOT RUN |
| C2 | Scan finds the correct robot; stop/timeout/cancel; no late background scan | Pending | NOT RUN |
| C3 | Connect/reconnect after backgrounding and radio loss | Pending | NOT RUN |
| C4 | Sensors reflect fresh data; stale/missing/disconnected readings become Unavailable | Pending | NOT RUN |
| C5 | Short movement/Wait/nested true and false distance programs | Pending | NOT RUN |
| C6 | Save, app restart, Open, edit and supervised Run; no false practice badge | Pending | NOT RUN |
| C7 | False/invalid distance condition and aborted run report the right outcome | Pending | NOT RUN |
| C8 | Three-second Auto Navigate: actual trajectory, final heading, timeout/fault and stop behavior | Pending | NOT RUN |
| C9 | Portrait layout, large text, keyboard and system Back on intended phones | Pending | NOT RUN |
| C10 | Measured connection time/range with stated environment and radio-loss response | Pending | NOT RUN |

Auto Navigate may stop during a scan/turn; it does not promise a completed route or return to its original heading. Sensor validity is not clearance behind or beside the robot. A successful practice badge is not a study outcome.

## Decision and unresolved work

| Field | Recorded value |
| --- | --- |
| Failed / unmeasured items and corrective actions | Pending |
| Retest references after fixes | Pending |
| Permitted supervised activity and operating limits | Pending |
| Reviewer / date | Pending |
| Overall decision | NOT ACCEPTED — template is unfilled |

Do not convert NOT RUN to PASS to close the project. Keep native/exported CAD evidence, physical test evidence, Android signing/distribution and [research reconciliation](research-reconciliation.md) as separate deliverables. None is established by filling in another.
