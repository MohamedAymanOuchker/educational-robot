# Educational Robot Curriculum Guide

Updated 8 October 2026. This teaching sequence matches the **five practice levels and eight block types** implemented in the current Android/BLE prototype. It is a proposed guide for the repaired build, not evidence that this software revision was used in the earlier study.

The [archived expanded curriculum](archive/curriculum-guide.md) preserves the earlier twenty-lesson plan and its reported results. Loop/If-Else activities, swarm coordination, mapping, self-calibration and advanced autonomy described there are future design material. Reported study and follow-up figures remain subject to [research reconciliation](research-reconciliation.md).

## Preparation

Before a lesson, an adult must complete the relevant checks in the [wiring](../hardware/wiring.md) and [power-system](../hardware/power-system.md) guides. Motor direction, physical travel, sensor readings and STOP behavior must be checked on the assembled robot. This document does not sign off that hardware.

Use a flat floor area with no drops or stairs, a clear perimeter, a tape measure, large cardboard targets and one matching Android/BLE app per robot. Keep fingers away from wheels and supervise reverse movement and turning: the front sensor cannot see the sides, rear or floor edges. Do not make speed competitions or unsupervised room exploration part of the initial lessons.

Work individually or in pairs with rotating roles: **programmer** arranges blocks; **observer** predicts, watches clearance and records the result. Allow about 30–45 minutes per level as a planning estimate, adapting the pace to the class. Stop early if the hardware behaves unexpectedly.

Learners can build and save offline, but running programs and earning practice checks requires a connected robot. This build has no simulator, joystick or speed control. Use **Run in Code → Start** for execution and **Stop on Robot Execution** to cancel. Read the [user manual](user-manual.md) before teaching.

## Learning sequence

| Level | Main idea | New available blocks | Evidence to discuss |
| --- | --- | --- | --- |
| 1 — Basic Movement | A command describes a motion request | Move Forward/Backward, Turn Left/Right, Stop | Predict and compare a short movement. |
| 2 — Movement Sequences | Order and timing change behavior | Wait | Explain the order and units of a sequence. |
| 3 — Distance Decisions | A condition selects a group of actions | If Distance < | Predict and observe both true and false branches. |
| 4 — Auto Mode | An automated behavior reacts during a bounded activity | Auto Navigate | Describe observations without claiming a planned route. |
| 5 — Combined Behaviors | Combine decisions and a bounded activity | No additional types | Explain a complete program and its limits. |

A robot practice badge records successful execution of a specific check. It does **not** establish mastery, course accuracy or learning improvement. Teachers assess the explanations and observations below separately.

## Level 1 — Basic Movement

**Goal:** distinguish distance from angle and predict what one movement request will do.

1. Show the physical power disconnect and the app's Stop control. Connect to **E-Bug ESP32** through Connect.
2. Drag **Move Forward** into Code and edit its default **100 cm** to **10 cm**. Predict its direction and mark the intended start/end positions.
3. Run once in a clear area. Measure the actual displacement and record the requested versus observed distance.
4. Add **Turn Right 45 degrees** below it and a **Stop** block last. Predict the full sequence before running.
5. Save the program with a name, leave/reopen it with Open, and confirm the parameter values.

```text
Move Forward 10 cm
Turn Right 45 degrees
Stop
```

**Software check:** a complete run containing a nonzero move or turn. Zero-distance/zero-angle commands do not qualify.

**Teacher check:** ask the learner to identify which parameter changes travel and which changes turning. Discuss differences between requested and observed motion without blaming the learner for uncalibrated hardware. Stop for adult inspection if direction or distance is wrong.

## Level 2 — Movement Sequences

**Goal:** explain top-to-bottom execution and distinguish milliseconds from seconds.

```text
Move Forward 10 cm
Wait 1000 ms
Turn Right 90 degrees
Wait 500 ms
Move Forward 10 cm
Stop
```

1. Predict the position and pauses after each root block. Each command completes before the next starts.
2. Run once, then change a Wait value and compare. **2000 ms is two seconds.**
3. Rearrange the roots and predict how the result changes before testing.
4. Optional square exercise: place four explicit Move Forward / Turn Right pairs. There is **no Repeat block**, so each pair must be placed separately. Explain the repeated pattern on paper as a future abstraction.

**Software check:** a complete run with a nonzero move/turn and a nonzero Wait.

**Teacher check:** have the learner explain one order change and convert a wait from milliseconds to seconds. The normal Stop block does not cancel the rest of a program; later blocks can move again. The Stop **button** cancels the whole run.

## Level 3 — Distance Decisions

**Goal:** predict whether child blocks execute from one valid distance reading.

Start with a stationary robot and this program:

```text
If Distance < 30 cm
    Stop
```

1. Place a broad target about 20 cm in front of the stationary sensor and confirm a valid live reading on Sensors. Predict whether the condition is true.
2. Run and inspect the log for the child **Stop** finishing.
3. Move the target to about 50 cm, verify its reading, predict again and rerun. Look for **Condition false; child blocks skipped**.
4. Explain why the robot ends stopped in both tests: the executor also sends a final STOP. The execution log, rather than visible travel, distinguishes these two branches.
5. Once hardware behavior is verified and clearance permits, the teacher may substitute a small turn for the child Stop to observe a conditional motion. Check clearance around the entire robot.

**Software check:** a complete run in which a nonzero move/turn or Stop inside a true condition executes. An empty condition or false branch does not qualify. Auto Navigate is added at level 4.

**Teacher check:** ask for both predictions, not just the badge. **If Distance samples once when reached**; it does not monitor continuously and has no Else branch. An unavailable/stale reading fails the run rather than counting as false or “clear.” Do not unplug sensors during a moving classroom exercise; fault-injection belongs in controlled adult hardware acceptance.

## Level 4 — Auto Mode

**Goal:** distinguish a prewritten reactive activity from a route the learner specified.

```text
Auto Navigate
```

1. In an adult-checked, open floor area, review the front sensor's limits and the Stop control.
2. Predict possible responses to a visible target, without promising an exact path.
3. Run **one** Auto Navigate block. It lasts three seconds and then requests STOP. Stop sooner if behavior is unexpected.
4. Record what actually happened, whether the app completed or reported a fault, and how the observation differed from the prediction.

**Software check:** the entire three-second activity and final STOP complete successfully. Enabling autonomous mode alone does not pass.

**Teacher check:** explain that this is experimental reactive obstacle avoidance. It has no map, destination planner, learning model or guaranteed route. A failure is a useful observation requiring inspection, not a result to relabel as success.

## Level 5 — Combined Behaviors

**Goal:** explain how a distance decision controls a bounded autonomous activity.

```text
If Distance < 100 cm
    Auto Navigate
Stop
```

1. Choose a broad target in a clear, supervised area, with a valid reading comfortably below 100 cm (for example around 60 cm). Keep enough open space for the checked robot's three-second activity.
2. Predict whether Auto Navigate will start. When the condition is true, the child activity runs and then stops.
3. With a target giving a valid reading above the threshold, predict and inspect the skipped branch. Do not assume an out-of-range or missing echo is a valid false condition.
4. Save both versions under distinct names. Explain the difference between a new saved copy and replacement.
5. Present the program, its actual observations and one known limitation to a partner.

**Software check:** Auto Navigate and an executed conditional response in the same completed run. Auto Navigate inside a true If Distance satisfies both parts. The false-branch version does not earn this check.

**Teacher check:** ask the learner to trace the true and false paths and describe the front sensor's blind spots. The threshold is checked before the child activity, not continuously by the If block. Auto Navigate has its own firmware behavior during the three-second activity.

## Assessment record

Keep requested/observed motion and student explanations separate from app practice checks. A simple record can contain:

| Field | Record |
| --- | --- |
| Lesson and program name | Level, saved name and app/firmware revision |
| Prediction | Learner's expected action sequence or branch |
| Observation | Actual motion, log result and any fault |
| Explanation | Learner's account of order, parameter units or condition |
| Revision | One deliberate change and its observed effect |
| Support | Prompts, pairing or adaptations used |

A teacher may rate explanations as **needs support**, **explains with prompts**, or **explains independently**, using examples from the session. This is a proposed classroom rubric, not a validated research instrument. Do not convert app badges into CTA/PCMS scores or retrofit these lessons into the earlier study's records.

For younger learners, start with two blocks and paper predictions. For learners needing more challenge, compare manually repeated sequences, nested distance conditions and measured travel errors using the available blocks. Offer a seated observer/programmer role, larger targets and verbal predictions when helpful. Adapt the physical setup to each learner rather than assuming the app is fully accessible or localized.

## Scope of this revision

Implemented: short movements and turns, explicit sequences, Wait, one-sided distance conditions, three-second Auto Navigate, local Save/Open and practice checks. There are **no** Repeat/While loops, If/Else, general math/comparison blocks, standalone battery/distance blocks, speed slider, joystick, Wi-Fi control, synchronized swarm behavior, mapping, QR export or automatic achievement system beyond the five checks. The app interface is English; a validated Arabic/iOS release is not supplied.

Unplugged discussions of loops, units or robotics applications may supplement these lessons, but do not instruct learners to find controls that the app lacks. The [archived twenty-lesson plan](archive/curriculum-guide.md) is available for future design work and historical traceability. No research outcome, runtime, motion accuracy or radio-range guarantee is established by this guide.
