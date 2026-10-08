# Robot command protocol (P1 revision)

Use the matching updated app and firmware together. The service/characteristic UUIDs remain unchanged; old apps that send `FORWARD:100` or `GET_SENSORS` are not compatible with this protocol.

- Service: `12345678-1234-1234-1234-123456789abc`
- Write command: `12345678-1234-1234-1234-123456789abd`
- Notify records: `12345678-1234-1234-1234-123456789abe`

## Commands

A request is ASCII `<id>:<command>\n`, with an integer ID from 1 to 65535. Keep IDs unique for pending requests. A BLE write acknowledgement only confirms transport; wait for the matching completion record before continuing a program.

| Command | Meaning |
|---|---|
| `F0` .. `F500` | Move forward by an integer number of centimetres |
| `B0` .. `B500` | Move backward by an integer number of centimetres |
| `L0` .. `L360` | Turn left by an integer number of degrees |
| `R0` .. `R360` | Turn right by an integer number of degrees |
| `STOP` | Interrupt motion, release coils, cancel queued commands and disable autonomy |
| `AUTO_NAV` | Enable reactive obstacle avoidance; completion means mode was enabled |
| `AUTO_OFF` | Disable autonomous motion and stop |
| `CALIBRATE` | Currently rejected; runtime calibration is not validated in this revision |
| `CLOOP_ON` | Currently rejected; experimental closed-loop turning is unavailable |
| `CLOOP_OFF` | Keep open-loop calibrated half-step turning |

Zero-valued movements are no-ops. Reject malformed, negative, fractional and out-of-range parameters instead of silently clamping them. Unknown commands return an error; they must not become STOP. Optional unnumbered commands are reserved for manual diagnostic clients; the app always uses IDs.

Example request: `42:F20\n`.

## Notifications

All notifications form a stream of UTF-8 JSON records, each terminated by a real newline. A record may span several notifications, and a receiver must not assume one notification equals one record. The firmware uses chunks of at most 20 bytes to fit the baseline ATT notification payload and serializes records to prevent telemetry/completion fragments from interleaving.

Buffer bytes until newline, decode the complete record, then parse JSON. Bound the receive buffer and handle malformed records without reporting success.

Command completion example:

```json
{"type":"command","id":42,"status":"done"}
```

`status` is `done`, `error`, or `cancelled`. An optional `message` explains rejection, sensor failure, obstacle interruption or cancellation. A blocked/aborted move must not report `done`. Queue overflow is an error. STOP is processed ahead of queued motion, and requests received before STOP cannot rearm motion afterward. A new explicit request after stopping can rearm; reconnecting alone cannot.

An autonomous safety abort stops the robot and sends a separate fault record, since the earlier `AUTO_NAV` completion only acknowledged enabling the mode:

```json
{"type":"fault","message":"autonomous distance unavailable or stale"}
```

The app aborts an active program on a fault, requests STOP, and reports failure. A deliberate user STOP does not generate a fault. Fault records use the same newline framing and serialized notification stream as other records.

Telemetry example (illustrative, not a measurement):

```json
{"type":"telemetry","distance":30.0,"distance_valid":true,"distance_age_ms":20,"battery":80.0,"heading":10.0,"temperature":25.0,"timestamp":1234}
```

Invalid distance is represented by `distance_valid:false` and a null distance. The client considers both firmware measurement age and local time since reception; a stale observation is not a clear path. `timestamp` is device uptime, not wall-clock time. Status/heartbeat/command records must not overwrite the last telemetry snapshot.

Each telemetry record replaces the prior sample atomically, including optional battery, temperature and heading fields. A missing field cannot inherit an old value with a refreshed receipt time. The current Sensors display uses a 500 ms freshness limit, checks expiry every 250 ms, and clears values on disconnect. Distance age includes `distance_age_ms`; other displayed fields use receipt age. These display checks do not replace the executor's freshness check when it evaluates a condition.

There are no `GET_SENSORS`, `GET_DISTANCE`, `SET_SPEED` or Dart-source commands. The app uses pushed telemetry. The app's Auto Navigate block runs a bounded three-second activity and then stops; it does not treat enabling an indefinite autonomous mode as a completed route.

The app starts command deadlines before transport writes and never treats a write acknowledgement as motion completion. A STOP without a matching successful response stays unconfirmed: the app attempts to disconnect BLE to trigger the firmware's disconnect stop, then waits for old native writes to finish before allowing a reconnect. It does not report a confirmed physical stop just because it requested disconnection. Actual radio loss detection and stop latency require hardware testing.

## Required checks

- Valid motion and a matching completion; no early completion on BLE write success.
- Fragmented/multiple/malformed records and unrelated command IDs.
- True and false distance conditions, including missing/stale measurements.
- STOP during motion, with pending work and a full queue; no old command resumes.
- Device disconnect, app backgrounding and leaving the run view stop/cancel execution.
- Invalid command/range, queue overflow, sensor timeout and blocked movement return failure rather than success.

Open-loop completion means the requested motor sequence finished; there is no wheel encoder verifying physical displacement. Check direction, calibration and stopping behavior on the actual robot. The front sensor cannot detect rear/side hazards.
