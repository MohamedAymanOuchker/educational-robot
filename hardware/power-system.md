# Selected motor and power system

Design selection: 8 October 2026. The owner authorized choosing a complete compatible setup. These are the parts to build toward; online research does not identify the parts already installed. The assembly still needs inspection and bench testing.

## Selected parts

| Item | Qty | Selected part | Reason / specification |
|---|---:|---|---|
| Motor and driver | 2 | [Olimex SM-5VDC-DRV](https://www.olimex.com/Products/Robot-CNC-Parts/StepperMotors/SM-5VDC-DRV/) | 5 V 28BYJ-48, nominal 1:64 gearing, ULN2003 board; matches the current four-input-per-motor firmware |
| Battery | 1 | [Tenergy 31003](https://power.tenergy.com/tenergy-li-ion-7-4v-2200mah-rechargeable-battery-w-pcb-2s1p-16-25wh-4a-rate/) | Factory-assembled, PCB-protected 2S1P Li-ion pack, 7.4 V nominal, 2200 mAh |
| Regulator | 1 | [Pololu D24V22F5, item 2858](https://www.pololu.com/product/2858) | Fixed 5 V buck regulator; manufacturer lists 2.5 A typical maximum at 24 V input, with actual capacity depending on input and cooling |
| External charger | 1 | [Tenergy TLP-4000, 01281](https://power.tenergy.com/tenergy-tlp-4000-universal-1a-smart-charger-for-li-ion-polymer-battery-pack-3-7v-14-8v-1-4-cell/) | 1 A CC/CV charger, explicitly listed by Tenergy for battery 31003; automatically recognizes supported cell counts |

Use two matching 5 V motors. Existing units may be retained only after their labels, wiring and gearing are checked. A ULN2003 board marked "5–12 V" does not change the attached motor's voltage rating. Do not apply the battery directly to the motor supply.

The chosen pack uses **8.4 V at full charge and 6.0 V as its specified discharge endpoint**. The existing firmware constants (8.4 / 6.0 V and a divide-by-three sensing network) already match those endpoints. The older [manufacturer specification, page 3](https://www.tenergy.com/core/media/media.nl/id.36145/c.671216/.f?h=384b24cc1d4ad2a6829c) confirms them. Battery percentage remains an approximate voltage-based indication, not protection or an automatic shutdown.

Source discrepancies are recorded instead of silently selecting the larger rating: the current battery page shows both 3 A and 4 A discharge figures, so use **3 A as the design ceiling**. The older sheet and current listing also differ on physical dimensions; measure the delivered pack before finalizing its holder.

## Additional assembly parts

These are project design choices, subject to the load and wiring checks below:

- **F1:** 2 A fast-acting fuse with a documented DC rating of at least 32 V, in an insulated holder close to the battery's positive output. Use a fuse/holder suitable for a lithium battery's possible fault current; the pack PCB does not replace it.
- **S1:** accessible on/off switch rated at least 3 A at 12 V DC. An AC-only switch rating is not sufficient evidence of its DC rating.
- **J1:** keyed, locking two-pin battery connector/harness rated at least 3 A at 12 V DC, with recessed battery-side contacts. Specify pin 1 as positive/red and pin 2 as negative/black on both the robot and charger adapter; verify polarity electrically.
- Short **20 AWG stranded copper** power leads, insulated joints, strain relief and a soldered/terminal-block distribution point. Keep motor current out of solderless breadboard rails and thin signal jumpers.
- **C1:** 470 microfarad, 16 V electrolytic across the 5 V distribution rail, observing polarity; 100 nF ceramic locally across each driver's supply.
- Echo divider: **2.2 kohm / 3.3 kohm, 1%**. Battery divider: **20 kohm / 10 kohm, 1%**. See the [GPIO wiring guide](wiring.md).
- Insulated regulator mounting, battery retention and a charger mains lead/plug suitable for the local socket. Do not open or modify mains-side equipment.

The standard battery is supplied with bare leads and the charger with clips: **the parts do not arrive as a plug-and-play harness**. Have the pack supplier or a competent assembler fit J1 and an insulated matching charger adapter. Work on the provided leads, never directly on the cells. Exposed clip connections are not the student operating interface.

## Power connections

```text
Tenergy 31003 protected pack
  P+ -- F1 (2 A) -- J1 pin 1 -- S1 --+-- Pololu VIN
                                   +-- 20k/10k divider -- GPIO35
  P- -------------- J1 pin 2 -------+-- common GND

Pololu VOUT (5 V) --+-- left ULN2003 motor supply
                   +-- right ULN2003 motor supply
                   +-- HC-SR04 VCC
                   +-- removable feed --> ESP32 board 5V input
                   +-- C1 positive; C1 negative --> GND

ESP32 board 3V3 ---------------------- MPU6050 supply (3.3 V-compatible module)
All board/driver/sensor grounds ------ common GND

Charging: unplug J1 from the robot and connect the fused pack harness
          to the matching TLP-4000 adapter instead. No simultaneous load.
```

Use the regulator's labeled **VIN, GND and VOUT**. Leave **EN and PG unconnected** in this design; EN has an onboard pull-up. Do not connect EN to an ESP32 GPIO directly. Its fixed output needs no potentiometer adjustment. The regulator's dropout, thermal and current limits must be verified at the actual load. [Pololu connection instructions](https://www.pololu.com/product/2858).

The controller reference is an **ESP32-DevKitC V4 with an ESP32-WROOM module**. Feed its 5V header, never a bare WROOM module's 3.3 V supply. Espressif requires choosing only one board power source. For USB programming, unplug the battery and remove the board's external 5 V feed so USB cannot backfeed the regulator/motor rail. Disconnect USB before restoring battery operation. An existing different ESP32 board needs its own pinout checked. [Espressif board power instructions](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32/esp32-devkitc/user_guide.html).

## Current budget and operating limits

This is a **calculated design allowance**, not a measurement or battery-life claim:

| 5 V rail load | Allowance |
|---|---:|
| Both motors, up to two energized coils each | 0.45 A |
| ESP32 development board, including radio activity | 0.55 A |
| Sensors and driver indicator LEDs | 0.10 A |
| Reserve | 0.10 A |
| **Design test load** | **1.20 A / 6 W** |

The motor estimate uses the 50 ohm +/-10% winding example in [Waveshare's 28BYJ-48 documentation](https://files.waveshare.com/upload/f/f8/Motor_Control_Shield_User_Manual_EN.pdf): four active coils at 5 V / 45 ohm give approximately 0.44 A before driver losses. That is an assumption until the selected motors are measured. The controller allowance accounts for [Espressif's recommendation of at least 500 mA supply capability](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32/schematic-checklist.html), not a claim that the board continuously draws that current.

At 6.4 V input, 6 W output and an assumed 85% conversion efficiency, estimated battery current is `6 / (6.4 * 0.85) = 1.10 A`. This is below the conservative pack limit and leaves room below F1's nominal rating. Validate startup inrush and fuse suitability; do not increase the fuse simply to hide an unexplained trip.

For supervised use, stop and recharge at about **6.4 V under load**, before the specified 6.0 V endpoint. This is an operating target, not a firmware cutoff. Verify voltage with a meter while calibrating telemetry; do not intentionally run to the pack's emergency PCB cutoff. Keep the power switch off during storage. Actual runtime and loaded motor torque remain unmeasured.

## Charging procedure

1. An adult switches the robot off, unplugs J1 and removes the pack for charging. The fuse stays with the pack harness.
2. Check the pack and keyed adapter, then use the selected TLP-4000 according to its instructions. It accepts 100–240 V AC and charges this protected 2S pack at up to 1 A; charge indoors within the pack's permitted temperature range.
3. Charge attended, clear of combustible materials. Disconnect after the charger's completion indication. Reconnect to the robot only after removing the charger.

This charger is specified for **protected** Li-ion/LiPo packs; it is not a balance charger for unprotected hobby packs. Do not substitute a TP4056 single-cell board or an ordinary DC adapter. No onboard charging is part of this design. [Tenergy charger requirements](https://power.tenergy.com/tenergy-tlp-4000-universal-1a-smart-charger-for-li-ion-polymer-battery-pack-3-7v-14-8v-1-4-cell/).

## Mechanical checks and acceptance

- The selected motor kit lists **35 mm mounting-hole spacing**, with M4 mounting holes. The previous assembly guide confused the 28 mm motor diameter with hole spacing. Verify the delivered parts, shaft/hub fit and CAD; select screw length after measuring the bracket.
- Reserve roughly **75 x 40 x 25 mm plus connector, wire-bend and retention space** for the battery as a preliminary envelope. This allowance is not a verified CAD fit.
- Before connecting the ESP32, measure the regulator rail and both divider outputs. At 8.4 V battery input, the battery divider should produce approximately 2.8 V; a 5 V Echo should produce approximately 3.0 V.
- Check the fixed regulator remains within **4.8–5.2 V** at 8.4 V and 6.4 V input under the 1.2 A design test load, with no sustained thermal shutdown, loose contacts or unsafe accessible surfaces. Check transients during real motor starts as well.
- With wheels raised, verify both directions, STOP, Bluetooth loss and sensor-failure behavior. Only then perform supervised floor tests and distance/turn calibration.

Record the delivered part numbers, motor labels, measured voltages/current/temperature and results in a copy of the [hardware acceptance record](../docs/hardware-acceptance.md) before marking hardware acceptance complete. Use the [CAD release checklist](cad-release.md) to reconcile mounts and the holder with the actual geometry. Firmware cannot prove the voltage printed on a physical motor or certify its power wiring.

## Cost and availability snapshot

Manufacturer listings checked 8 October 2026: two Olimex kits **EUR 5.00 total**, battery **USD 18.49**, regulator **USD 18.95**, charger **USD 29.99**. The three power items total **USD 67.43**, before motors, wiring, protection accessories, controller, sensors, fabrication, tax, shipping or import charges. The charger is reusable lab equipment. These selections replace the old incomplete USD 40 project estimate; they are not a local delivered quote. Pololu's direct listing showed backorders; confirm distributor stock before purchasing. Nothing has been ordered.
