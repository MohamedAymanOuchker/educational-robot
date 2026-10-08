# Educational Robot User Manual

Updated 8 October 2026 for the matching Android app and ESP32 firmware in this repository. This guide describes implemented controls. The [older manual](archive/user-manual.md) is preserved as historical planning material.

This is a supervised DIY prototype. Hardware acceptance, printable CAD exports and reconciliation of the reported study remain open; see [P1 status](p1-status.md) and [P2 status](p2-status.md). A successful software test does not establish physical robot safety, accuracy or learning outcomes.

## Before use

An adult must assemble and check the robot against the [wiring guide](../hardware/wiring.md) and [power-system specification](../hardware/power-system.md). The selected reference build uses **5 V 28BYJ-48 motors and ULN2003 drivers**, a protected **7.4 V 2S battery**, and a separate fixed **5 V regulator**. Verify the actual motor labels, connectors, fuse, polarity, voltage dividers and motor directions before operation.

Use a flat, open floor area, away from edges, stairs, liquids, fingers and loose wires. The front ultrasonic sensor cannot detect rear/side hazards or reliably protect against floor edges. An adult must be able to reach the physical power switch/disconnect. Test new programs with short distances and a clear area.

The USB socket does **not** charge the battery. Use the selected external charger and insulated adapter with the pack disconnected from the robot, following the [charging procedure](../hardware/power-system.md#charging-procedure). The hardware guide also describes the separation of USB and battery power during programming.

## Install and connect

1. Build or obtain the matching **Android debug APK** using the [app instructions](../mobile-app/README.md). Android 7.0 / API 24 is the current minimum. Use a phone with Bluetooth Low Energy; iOS release support is not validated.
2. Install the APK, shown as **RoboCode (Test)**, and allow the requested Bluetooth/Location permissions. Enable Bluetooth on the phone. This package uses a new test app ID; programs in the older app stay in that separate installation. Keep the old app if its saved programs are needed; see [installation identities](android-release.md#identity-and-build-variants).
3. Power the checked robot and open **Connect**. Tap **Scan for robots**. A scan lasts about ten seconds after permission/startup work, and **Stop scan** ends it early.
4. Look for **E-Bug ESP32** and tap **Connect**. The list contains devices advertising the robot service. Connection verifies the required characteristics and a STOP response before success is returned.
5. If permission, adapter or scan errors appear, correct them before retrying. If no robot appears, check its power, firmware and distance from the phone.

This app connects using Bluetooth Low Energy. There is no Wi-Fi setup or Wi-Fi password dialog. Changing tabs keeps the connection; **Disconnect** on Connect requests STOP and closes it.

## App navigation

| Screen | Use |
| --- | --- |
| Home | Select an unlocked practice level and see recorded practice checks. |
| Connect | Scan for the robot, connect and disconnect using Bluetooth. |
| Code | Build, edit, Save/Open and launch a program. |
| Sensors | View automatically pushed readings and their availability. |

**Robot Execution** opens from **Run** in Code; it is not a separate navigation tab. Its **Start** button starts the loaded program and its **Stop** button cancels the run.

## Build a program

1. Select a level on Home, then work in Code.
2. **Hold and drag** a toolbox block into the workspace. On narrow phones the toolbox scrolls horizontally above the workspace.
3. Tap a workspace block's heading to edit its numeric parameter. Use whole numbers within the limits below.
4. Arrange top-level blocks vertically: they execute from top to bottom. Horizontal position does not set execution order. Avoid overlapping blocks or placing roots at exactly the same height.
5. Drop blocks into **If Distance <** to make them conditional. Children execute in their displayed order; drag a child back into the workspace to make it unconditional.
6. Tap **Run**, then **Start**. The program uses a snapshot of the workspace and waits for command completion before the next block.

The current app has eight block types:

| Block | Parameter | Behavior |
| --- | --- | --- |
| Move Forward | 0–500 whole cm; default 100 | Requests forward movement. For a first test, edit the default to **10 cm**. |
| Move Backward | 0–500 whole cm; default 100 | Requests reverse movement; the front sensor cannot check behind the robot. |
| Turn Left / Turn Right | 0–360 whole degrees; default 90 | Requests an open-loop turn. Check clearance around the robot. |
| Stop | None | Stops the robot and disables Auto Navigate. **Later blocks can move it again.** |
| Wait | 0–60000 whole **milliseconds**; default 1000 | Pauses the program. **2000 means two seconds.** It cannot contain children. |
| If Distance < | 2–400 whole cm; default 20 | Takes one fresh valid distance reading. Executes children only if the distance is strictly below the threshold. It has no Else branch. |
| Auto Navigate | None | Runs an experimental reactive navigation activity for **three seconds**, then stops. It does not map a room or guarantee reaching a destination. |

A zero-valued move, turn or Wait does nothing and does not earn the corresponding practice check. Limits are accepted command ranges, not measured accuracy or safe travel allowances. Distance and angle must be calibrated on the assembled robot.

**If Distance is a single decision, not continuous monitoring.** With a false condition, its children are skipped and execution continues after the container. Invalid/stale distance makes the program fail and request STOP. A successful open-loop completion means the coil sequence finished, not that wheel travel was measured.

### A first example

At level 1, create these roots from top to bottom:

```text
Move Forward 10 cm
Turn Right 45 degrees
Stop
```

Predict the motion, clear the area and run once under supervision. Compare the observed result with your prediction. If direction or distance is wrong, stop and have an adult inspect the hardware/calibration before repeating.

## Stop and failure behavior

- **Stop on Robot Execution** cancels the whole program and requests robot STOP. It is different from a Stop block followed by more blocks.
- Leaving Robot Execution or putting the app in the background also cancels an active run. It does not resume automatically when you return.
- A movement error, sensor fault or disconnect prevents the run from being reported as completed.
- If STOP is unconfirmed, the app attempts to disconnect Bluetooth to trigger the firmware's disconnect behavior. Confirm the robot has stopped; use its physical power disconnect if needed. Reconnect only after checking the robot.
- An autonomous activity can fail even after its mode-enable command was acknowledged. Read the execution log and correct the cause; do not treat the three-second timer as proof of successful navigation.

Actual radio-loss detection and stop latency still need measurement on the robot.

## Saving and loading programs

Tap **Save**, enter a name of 1–64 characters and tap **Save program**. A name already in use asks for replacement confirmation; names are case-insensitive. Use a new name to keep a separate copy. The level, save time, parameters, positions, colors and nested blocks are stored locally.

Tap **Open** and select a saved program to resume editing. Its level must be unlocked. Opening asks before replacing unsaved changes; cancel to save them first. **Clear** asks before removing workspace blocks and leaves saved programs intact.

The library holds up to **50 programs**, with up to **100 blocks** per program. Empty drafts can be saved but cannot run. Save after editing: tab switches retain the workspace, but closing the app does not automatically save it. Uninstalling the app or clearing its data removes local programs and progress. Export, QR sharing and cloud backup are not implemented.

A failed save keeps the workspace and shows an error. Damaged or newer-format stored data is kept rather than silently overwritten.

## Practice levels

The progress bar counts five software practice checks, from 0% to 100%. **Save never completes a lesson.** The whole program must succeed, including the final STOP, and the relevant actions must actually execute:

| Level | Toolbox additions | Practice check |
| --- | --- | --- |
| 1 — Basic Movement | Move Forward/Backward, Turn Left/Right, Stop | Execute a nonzero move or turn. |
| 2 — Movement Sequences | Wait | Execute a nonzero move or turn and a nonzero Wait. |
| 3 — Distance Decisions | If Distance < | Execute a nonzero move/turn, Stop or Auto Navigate inside a true condition. Auto Navigate becomes available at level 4. |
| 4 — Auto Mode | Auto Navigate | Complete the three-second Auto Navigate activity. |
| 5 — Combined Behaviors | Same blocks as level 4 | Complete Auto Navigate and a conditional response in one run. Auto Navigate inside a true condition satisfies both. |

Skipped children, failures and cancelled runs do not earn checks. Completing a check unlocks the next lesson; select it on Home. Old versions awarded badges from block presence: existing lesson access is retained, but those old badges do not count as executed practice.

These checks do not assess student understanding or physical accuracy. Use the [current five-level curriculum](curriculum-guide.md) for teacher observations and exercises. Detailed achievement badges, a twenty-lesson automatic progression, Repeat/While loops, general comparisons, If/Else and standalone sensor-value blocks are not implemented.

## Sensor readings

Sensors shows pushed telemetry automatically; it has no Start/Stop monitoring control and does not command movement.

- **Front distance:** available only when the validity flag and combined firmware/local age satisfy the 500 ms freshness limit. Missing/invalid data is not displayed as zero or “all clear.”
- **Battery estimate:** a voltage-derived percentage, not a charge guarantee. Verify the divider and calibration. The selected operating recharge target is about 6.4 V under load; use a meter until telemetry is validated. Automatic low-battery movement lockout is not implemented.
- **IMU temperature:** chip temperature, not a calibrated room-temperature measurement.
- **Relative heading:** a gyro estimate relative to startup. It can drift; it is not a compass and does not verify a turn's physical angle.

No sample, a disconnect, or telemetry older than 500 ms shows **Unavailable**. Missing fields in a new telemetry packet do not borrow values from an older packet. The display checks ageing every 250 ms, so its stale indicator can appear on the next display tick; program execution validates freshness when a reading is used.

## Troubleshooting

| Problem | Action |
| --- | --- |
| Scan reports permissions or Bluetooth errors | Enable Bluetooth and review the app's requested permissions in Android settings, then retry. |
| No matching robots found | Check robot power and the matching service-advertising firmware. Move nearer and scan again. |
| Connection fails | Verify the app and firmware revision match. A connected BLE device alone is insufficient; the command service and STOP handshake must work. |
| Program fails or stops unexpectedly | Read its execution log. Inspect the reported obstacle, sensor, connection or command error before another run. |
| Distance is unavailable | Check sensor wiring, Echo divider and front target. Do not bypass validity checks to make movement proceed. |
| Movement is reversed or inaccurate | Check coil wiring, direction settings, gear ratio, wheel dimensions and calibration against the hardware guide. |
| Save fails | Keep the workspace open and retry. If the library already has 50 programs, replace an existing name. Stored format problems require recovery before more saves. |
| A practice check stays incomplete | Read the requirement above Code. Confirm the relevant nonzero action/true branch actually executed and the entire run succeeded. |

Use the selected component manufacturers' actual instructions for battery care and charging. The repository provides no packaged-kit warranty, app-store release, guaranteed Bluetooth range, movement accuracy or battery runtime. Measure the assembled robot and record results before claiming them.

## Developer and historical references

- [Build and test the app](../mobile-app/README.md)
- [BLE commands and telemetry](ble-protocol.md)
- [Wiring](../hardware/wiring.md) and [power selection](../hardware/power-system.md)
- [P1 evidence and blockers](p1-status.md), [P2 status](p2-status.md), [research reconciliation](research-reconciliation.md)
- [Archived manual](archive/user-manual.md) and [archived expanded curriculum](archive/curriculum-guide.md): historical proposals and reported claims, not current operating instructions
