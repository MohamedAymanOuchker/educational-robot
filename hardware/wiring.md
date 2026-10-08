# 28BYJ-48 / ULN2003 wiring

The project owner confirmed two 28BYJ-48 motors with ULN2003 boards on 6 October 2026. The updated firmware uses four coil inputs per motor. **Rewire to this map before uploading the updated firmware.** The previous STEP/DIR/ENABLE table was incompatible with this hardware.

This is a proposed, explicit wiring revision matching `firmware/src/config.h`. Continuity, supply voltages, motor direction, actual wheel geometry and any external gears must be checked on the assembled robot before floor testing. Record those checks and calibration trials in the [hardware acceptance record](../docs/hardware-acceptance.md), following the [assembly sequence](../docs/assembly-guide.md).

The [selected power system](power-system.md) now specifies **5 V Olimex motor/ULN2003 kits, a Tenergy 31003 protected 7.4 V / 2200 mAh pack, a Pololu D24V22F5 regulator and a Tenergy TLP-4000 charger**. Use that parts list and power harness alongside this GPIO map. The selection does not establish what is already fitted to the robot.

## Motor connections

| ESP32 GPIO | Connection |
|---|---|
| 26 | Left ULN2003 IN1 |
| 27 | Left ULN2003 IN2 |
| 25 | Left ULN2003 IN3 |
| 33 | Left ULN2003 IN4 |
| 14 | Right ULN2003 IN1 |
| 13 | Right ULN2003 IN2 |
| 32 | Right ULN2003 IN3 |
| 23 | Right ULN2003 IN4 |
| GND | Both ULN2003 GND terminals and supply ground |

Connect each motor's five-wire plug to its driver board. Verify connector/coil order against the actual board; IN1 through IN4 are the labels on the board, not the physical order of GPIO numbers. Do not connect a coil directly to an ESP32 GPIO. The ULN2003 has no STEP/DIR/ENABLE interface; turning all four inputs off releases the motor.

The selected motors require a regulated 5 V rail. Check existing motor labels before reuse. A 7.4 V nominal battery can reach 8.4 V: it must not be connected directly to this motor rail. Follow the [power connection and USB programming procedure](power-system.md#power-connections) for the regulator and ESP32 board.

The default is nominally 4096 half-steps per geared motor output revolution, with a conservative 2000 microsecond interval. Manufacturing variants and additional axle/gearing change the effective steps per wheel revolution. These constants require calibration. The existing 65 mm wheel diameter and 150 mm track width are retained starting values, not newly verified measurements.

## Sensor and battery connections

| ESP32 GPIO | Connection |
|---|---|
| 5 | HC-SR04 TRIG |
| 18 | HC-SR04 ECHO through divider below |
| 21 | MPU6050 SDA (3.3 V logic) |
| 22 | MPU6050 SCL (3.3 V logic) |
| 35 | Battery voltage through divider below |
| GND | All sensor grounds and battery/supply ground |

Supply the ordinary HC-SR04 with regulated 5 V. Its 5 V Echo signal must be reduced before reaching GPIO18. The following divider produces approximately 3.0 V from a 5.0 V Echo signal:

```text
HC-SR04 ECHO ----- 2.2 kohm -----+----- GPIO18
                               |
                            3.3 kohm
                               |
                              GND
```

Use suitable 1% resistors and measure the signal/divider wiring before connecting the ESP32. This choice is for the ordinary 5 V HC-SR04; a different sensor variant requires checking its own specifications. Sources: [HC-SR04 pinout](https://learn.adafruit.com/ultrasonic-sonar-distance-sensors/pinouts), [ESP32-WROOM-32 electrical limits](https://documentation.espressif.com/esp32_wroom-32_datasheet_en.pdf).

The firmware's 2S battery measurement expects a divide-by-three network. At an 8.4 V pack voltage, GPIO35 sees approximately 2.8 V:

```text
Switched battery + ----- 20 kohm -----+----- GPIO35 (ADC1)
                                     |
                                  10 kohm
                                     |
                                    GND
```

Use suitable 1% resistors; verify the midpoint with a multimeter before connecting GPIO35. Never connect the pack directly to the GPIO. Check reported voltage against the meter and calibrate the divider/ADC as necessary. Battery percentage is a voltage-based estimate, not a calibrated fuel gauge. It is not battery protection or a low-voltage cutoff.

## Power and charging boundary

```text
Tenergy 31003 protected 2S pack
        |
  2 A DC fuse + keyed disconnect + DC-rated switch
        |
        +---- battery divider ---- GPIO35
        |
  Pololu D24V22F5 ---- regulated 5 V rail

All grounds share a common reference.
```

Part selection, fuse/harness requirements and the external charging procedure are specified in [power-system.md](power-system.md); physical assembly and measurements remain pending. Unplug the pack from the robot and charge it with the selected TLP-4000 through its matching insulated adapter. There is no onboard charging or simultaneous charge-and-run mode. The ESP32 USB connector and a buck converter do **not** constitute a 2S charging system.

## Bring-up checklist

1. With all power removed, verify each IN1..IN4 wire and common ground against the table.
2. Check motor labels, regulated supply voltage and divider ratios with a meter.
3. Raise the wheels. Command a short movement; STOP and BLE disconnection must turn all motor outputs off. Coil release does not mechanically brake a wheel or hold the robot on a slope.
4. Verify both physical directions. Adjust the firmware's per-side direction inversion configuration if a mirrored motor turns the wrong way.
5. At low speed on a clear, flat area, calibrate distance and turns. Record actual motor output gearing, external gear ratio, wheel diameter, track width and software version.
6. Verify sensor failure/timeout, stale data, obstacle stopping and stop latency before an educational demo. A front sensor does not protect the rear or sides during reverse/turning.

Native CAD files remain in this directory. Printable STL exports, neutral CAD exports, the axle/gear assembly mapping and measured mechanical drawings are still required for a reproducible release; this wiring revision does not supply those missing parts.
