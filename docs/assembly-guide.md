# Educational Robot Assembly Guide

Updated 8 October 2026 for the 5 V 28BYJ-48 / ULN2003 reference build. This is a staged build procedure, not a completed hardware validation. The [previous guide](archive/assembly-guide.md) is retained as historical material.

The actual CATIA geometry has not yet been opened or exported in this revision. The owner will install CATIA later. Do not treat the old chassis, battery holder, sensor mount, hub or cover STL names as supplied files. Start with the [CAD release checklist and inventory](../hardware/cad-release.md).

## Build references

| Subject | Authoritative project file |
| --- | --- |
| Selected motors, battery, regulator, charger, fuse and power harness | [Power specification](../hardware/power-system.md) |
| GPIOs, ULN2003 coil order, Echo and battery dividers | [Wiring guide](../hardware/wiring.md) |
| Native part inventory and mechanical export requirements | [CAD release checklist](../hardware/cad-release.md) |
| Measurements, test outcomes and final decision | [Hardware acceptance record](hardware-acceptance.md) |
| Supported firmware and commands | [Firmware guide](../firmware/README.md) |
| Current Android app and classroom activities | [User manual](user-manual.md) and [curriculum](curriculum-guide.md) |

Make a copy of the acceptance record for each physical robot. Enter measured values and evidence as the work proceeds. Keep unanswered items marked NOT RUN. Firmware compilation, an app badge and an assembly photo are not substitutes for physical tests.

## 1. Confirm the parts and mechanical design

1. Record the actual part labels. The selected motors are **5 V** units; existing 28BYJ-48 motors must have their voltage verified before reuse. Verify the protected 2S pack, fixed regulator and external charger against the power specification.
2. In CATIA, open candidate assemblies, resolve their references, and identify the actual top-level robot assembly and printed parts. Keep native filenames unchanged until dependencies have been checked.
3. Measure the delivered motor mount, shaft profile and usable shaft length. The selected kit's listed 35 mm mounting spacing and M4 holes are reference dimensions to verify. A generic 5 mm round hub hole is not a validated shaft fit.
4. Verify battery retention and removal, connector access, electronics clearance, switch access and cable paths against measured parts. The battery's preliminary envelope in the power specification is not a finished holder design.
5. Establish whether there are external gears between the motor output and wheel. Record tooth counts, the resulting ratio, and wheel diameter/track width. Do not infer a physical gear ratio from a filename.
6. Complete the part-to-file mapping, export actual geometry and check it in the slicer before printing.

No print times, filament weights, support settings or fixed fastener lengths have been validated. Choose material and slicer settings for the actual geometry, printer and filament; record them. Check one critical fit piece before committing to the whole build. Do not force a battery into a tight holder or rely on an unverified press fit for a rotating hub.

## 2. Prepare the work area and tools

An adult with electronics assembly experience performs wiring, power checks and charging. Use eye protection and suitable ventilation for fabrication/soldering. Keep battery contacts insulated and the pack disconnected while wiring.

Have a multimeter, caliper/ruler, an angle reference, insulated tools, the specified wiring/protection parts, and the correct charger. Use a suitable current-limited supply and load equipment for the regulator tests if available; otherwise have a competent electronics assembler perform them. Thermal and transient measurements need appropriate instruments. Record any measurement that could not be made.

Build on a flat surface with space to secure the chassis and raise the wheels. A person must be able to reach the power disconnect. Later floor tests need a clear area with no edges or rear/side hazards.

## 3. Assemble and verify the power harness

Follow the [power connection diagram](../hardware/power-system.md#power-connections).

1. With all sources disconnected, fit the specified fuse, keyed connector, switch, insulated power distribution and strain relief. Keep motor current out of solderless breadboard rails.
2. Verify connector polarity, ground continuity, regulator terminal labels, capacitor polarity and absence of a short across the supply. Do not use an ohmmeter on an energized circuit.
3. Test the regulator before connecting the ESP32, motor drivers or sensors. Record results at 8.4 V and 6.4 V input, including the 1.2 A design load. The project rail target is 4.8–5.2 V; current allowance and temperature still need measurement.
4. Verify the battery divider midpoint before connecting GPIO35. The 20 kohm / 10 kohm network gives approximately 2.8 V at 8.4 V input.
5. Verify the Echo divider before connecting GPIO18. The 2.2 kohm / 3.3 kohm network gives approximately 3.0 V from a 5 V signal. A multimeter can verify a controlled DC test; it does not prove the peak of a pulsed Echo signal.
6. Remove power before adding the electronics. Record actual startup/load behavior and temperatures once the real loads are connected.

Stop at an unexpected voltage, reversed polarity, unexplained fuse trip, damaged pack, loose connection or abnormal heating. Correct the cause and repeat the affected checks before proceeding. The 6.4 V loaded recharge target is an operating procedure; firmware does not enforce a low-voltage cutoff.

## 4. Mount and wire the electronics

- Connect both ULN2003 boards in their marked IN1–IN4 order using the eight GPIOs in the wiring guide. No STEP/DIR/ENABLE wiring applies.
- Supply the selected motors and ordinary HC-SR04 from regulated 5 V. Use a 3.3 V-compatible MPU6050 module and the documented I2C wiring. Share ground.
- Secure motors and hubs using the measured mount/shaft geometry. Confirm free rotation and clearance without forcing or distorting parts.
- Begin with the ultrasonic sensor facing forward near level. Check the actual beam path with the robot at its operating height; determine mounting angle through tests with the floor and intended obstacles. The historical 15° downward setting is not a validated optimum.
- Mount the IMU rigidly and record its orientation. Keep the robot still during startup calibration. Its relative gyro heading is not a compass.
- Retain the battery without crushing it, protect its leads from moving parts, and make removal, charging and the main disconnect accessible. Select fasteners after checking hole size and material thickness.
- Photograph the finished wiring, divider connections and harness before closing the cover. Repeat continuity and polarity checks with power disconnected.

## 5. Build and load the matching software

The supported PlatformIO project is `firmware/src` with `firmware/platformio.ini`; the archived Arduino sketch is not an upload target.

From `firmware`, build with `pio run`. Before connecting USB, disconnect the battery **and remove the ESP32 board's external 5 V feed**, as described in the power guide. This prevents USB from powering/backfeeding the motor rail through the board. Check the actual board and upload port, then use `pio run --target upload --upload-port PORT` with the verified port.

For this reference wiring, USB and battery operation are separate stages. Do not restore the external 5 V feed while USB is attached. The serial monitor is useful for the USB-only startup check; disconnect USB before powered motor testing. A different simultaneous diagnostic connection needs an independently verified isolation arrangement.

Use `pio device monitor --baud 115200` for the USB-only startup log. Retain the actual log rather than comparing it with a fabricated success transcript. The firmware may print a sensor warning and still finish initialization; inspect warnings and validate each sensor separately.

Install the matching [Android test APK](android-release.md#build-a-supervised-test-apk). It appears as **RoboCode (Test)** and has separate local storage from the older app ID. Enable Bluetooth and follow the user manual's connection procedure.

## 6. Commission with the wheels raised

Disconnect USB, restore the verified external feed and power the robot from the checked harness. Secure the chassis and keep hands and wires clear of the wheels. Use Code to create one short action at a time, initially Forward 5 cm, Backward 5 cm, Left 15° and Right 15°, with STOP available.

1. Confirm startup and connection alone do not move the motors.
2. Verify both wheel directions and phase order. Correct `LEFT_MOTOR_INVERT` / `RIGHT_MOTOR_INVERT` in `firmware/src/config.h` only after confirming the wiring; rebuild and reflash through the USB-only procedure.
3. Check the forward distance reading using a stationary target. A missing/stale reading should be Unavailable and must not authorize forward motion. Keep a valid clear front target for the direction test.
4. Verify normal completion, whole-run Stop, leaving the run screen, app backgrounding and Bluetooth loss. Watch the wheels; record elapsed time and any residual motion. No old action should resume on reconnection.
5. Test an ultrasonic fault by switching power off, removing only its signal connection, securing the loose lead, and restarting the same raised-wheel setup. Forward motion must fail; do not create a live short as a fault test. Restore wiring with power off.
6. Confirm the app shows failure/cancellation truthfully. A requested or acknowledged STOP is not evidence of zero physical motion.

Use the acceptance record for repeated observations. Do not proceed to floor tests while motion direction, stopping, power integrity or sensing has an unresolved failure.

## 7. Calibrate on the floor

Use a clear flat area, short movements first and a reachable power disconnect. Record surface, battery voltage, load and the constants used. Verify rear/side clearance manually before backward motion or rotation.

- Begin with 20 cm travel. Once direction, stopping and clearance are established, increase the calibration baseline to 50–100 cm if the area permits. Repeat and record each measurement.
- Resolve slipping hubs, mismatched wheels, binding gears or missed steps before changing constants.
- Calibrate wheel travel before turns. Start with 45° turns, then 90° left and right. Record overshoot, undershoot and repeatability separately for each direction.
- Use the formulas and tables in the [acceptance record](hardware-acceptance.md#motion-calibration). Rebuild/reflash after a configuration change and repeat the affected checks.

The defaults of 4096 half-steps, 65 mm wheel diameter and 150 mm track width are starting assumptions. Runtime `CALIBRATE` and `CLOOP_ON` are deliberately unsupported. Open-loop completion indicates the requested coil sequence ended, not that measured travel was correct.

## 8. Check the app and bounded Auto Navigate activity

Follow the [five implemented practice levels](user-manual.md#practice-levels), including Save/Open, true and false distance conditions, invalid sensing and cancellation. Measure connection time and usable range on the intended phones; there is no established 5-second connection guarantee or 12-metre operating range.

Test Auto Navigate only after the earlier checks pass. It is a three-second experimental activity, not a promise to complete a scan or navigate a route. With these slow motors the timer can end while the chassis is turning; do not assume it returns to its starting heading. Record the behavior and final orientation. Front sensing does not establish rear/side clearance.

The bench record concerns robot operation. It is not a learning study, does not authorize testing with children, and does not replace the original research records.

## 9. Release the physical build

Retain the completed acceptance record, CAD/print mapping, measured calibration, photographs, app/firmware identifiers and unresolved limitations. Mark failed or unmeasured items explicitly. Decide whether the build is fit for the stated supervised activity only after the evidence has been reviewed.

For charging, disconnect and remove the pack and follow the [external charging procedure](../hardware/power-system.md#charging-procedure). The USB port does not charge this pack. For Android distribution, follow the [signing and release guide](android-release.md).
