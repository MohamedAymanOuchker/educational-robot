> **Historical planning material — archived 8 October 2026.** Use the [current user manual](../user-manual.md) for this build. This preserved version mixes proposed features, historical claims and implemented behavior; it is not an operating or release specification. Reported research figures remain subject to [reconciliation](../research-reconciliation.md), not revalidated by this archive.

# Educational Robot User Manual

> **Prototype status:** use the updated [wiring and power guide](../../hardware/wiring.md) before operating this hardware revision. The repository supplies a DIY prototype, not a packaged kit with an included charger. Some lessons/features below are historical design material and remain pending implementation or validation; see [P1 completion status](../p1-status.md).

## Quick Start Guide

### Welcome to Your Educational Robot! 🤖

Congratulations on your new educational robot! This guide will help you get started with programming and controlling your robot using the mobile app.

**Required for operation:**
- An assembled and checked robot matching the current wiring
- The [selected protected 7.4 V battery and fixed 5 V regulator](../../hardware/power-system.md), with the checked power harness
- The selected Tenergy TLP-4000 external charger and matching insulated pack adapter
- An Android 7.0+ phone with Bluetooth Low Energy running the matching app version

The ESP32 USB connector does not charge the 2S battery pack. The charger is a separate purchase, and charging takes place with the pack disconnected from the robot. The [power guide](../../hardware/power-system.md#charging-procedure) specifies the procedure. The reference motor voltage is 5 V; check existing parts against the selected models before use.

## Current P1 operation

Updated 8 October 2026. This section describes the current app and matching firmware. The curriculum and concept screens later in this manual also describe planned features; use this section as the operating reference for P1.

| Available block | Parameter and behavior |
|---|---|
| Move Forward / Move Backward | Whole centimetres, 0–500; default 100 |
| Turn Left / Turn Right | Whole degrees, 0–360; default 90 |
| Wait | Whole **milliseconds**, 0–60000; default 1000. Enter **2000** for two seconds. Wait has no child blocks. |
| If Distance < | Threshold in whole centimetres, 2–400; default 20. Runs its child blocks only when a fresh, valid distance is strictly below the threshold. |
| Stop | Stops motion and disables autonomous mode. Later blocks in the program can issue new movement commands. |
| Auto Navigate | Runs an autonomous activity for three seconds, then stops before the next block. Sensor or motion faults fail the run. |

The toolbox exposes these blocks progressively by level. Zero-valued movement and turn commands are no-ops. The front sensor cannot check rear or side clearance; supervise reverse movement and turns.

1. Connect from the app's **Connect → Bluetooth** screen. Wait for the connection to succeed.
2. **Hold and drag** a toolbox block into the workspace. Tap a workspace block's heading to edit its parameter.
3. Arrange top-level blocks from top to bottom. Drop child blocks inside an **If Distance <** block to make them conditional; children execute in their displayed order.
4. Tap **Run** to open Robot Execution, then tap **Start** to execute. Completion waits for the robot's acknowledgements; it does not verify physical wheel displacement.
5. Tap **Stop** on Robot Execution to cancel the whole run. Going back or backgrounding the app also cancels it. If STOP is unconfirmed, the app attempts to disconnect Bluetooth to trigger the firmware's stop behavior. Check that the robot has stopped; use the physical power disconnect if needed. Reconnect only after checking the robot.

**Available in the P2 persistence update:** named **Save** and **Open**, plus practice checks after successful robot execution. Saving alone does not complete a lesson. See [Saving and Loading Programs](#-saving-and-loading-programs) and [P2 status](../p2-status.md).

**Still planned:** Repeat/While loops, If/Else, general comparison/math blocks, standalone distance/battery blocks, joystick/speed control, sharing/export, Wi-Fi operation and iOS release support. Historical lessons using those features remain design material.

---

## Table of Contents

1. [Safety First](#safety-first)
2. [Getting Started](#getting-started)
3. [Mobile App Guide](#mobile-app-guide)
4. [Programming Basics](#programming-basics)
5. [Learning Levels](#learning-levels)
6. [Advanced Features](#advanced-features)
7. [Maintenance](#maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Educational Activities](#educational-activities)

---

## Safety First

### 🛡️ Important Safety Rules

**Before You Start:**
- Always have an adult nearby when first learning
- Keep robot away from stairs and high surfaces
- Don't use near water or wet surfaces
- Never disassemble the robot
- Charge the disconnected pack with a charger specified for its chemistry, cell count and connector/polarity; follow the pack and charger manufacturer's instructions

**During Use:**
- Clear the play area of obstacles
- Keep fingers away from moving wheels
- Stop robot if it makes unusual sounds
- Don't block the robot's sensors
- Take breaks every 30 minutes

**Battery Safety:**
- Charge in open, well-ventilated area
- Never leave charging unattended
- Unplug when fully charged
- Stop using if battery swells or gets hot

---

## Getting Started

### Step 1: First Power-On

1. **Check the assembly and power wiring** against the [current hardware guide](../../hardware/wiring.md).
2. **Connect the correctly rated supply** using the switch and connector fitted to your verified assembly.
3. **Turn on the robot** and check its startup messages using the serial monitor, then look for **E-Bug ESP32** in the app's Bluetooth scan.
4. **Check the configured battery telemetry** after connection. Its percentage is meaningful only after the divider and pack voltage settings have been verified.

The current firmware releases the motor coils at startup and waits for an explicit movement command. It does not implement the previously described motor self-test or colored power, connection and battery LED indications.

### Step 2: Download the App

**For Android:**
1. Build the matching Android test APK using the [mobile app instructions](../../mobile-app/README.md), or obtain that same build from the project author
2. Enable "Install from unknown sources" in Settings
3. Install the Educational Robot app
4. Grant Bluetooth and Location permissions

**For iPhone/iPad:**
- Coming soon! Check our website for updates

### Step 3: Connect Your Robot

1. **Open the app** and select **Connect → Bluetooth**, then scan for devices
2. **Make sure Bluetooth is on** on your phone/tablet
3. **Look for "E-Bug ESP32"** in the device list
4. **Tap to connect** and wait for the app to confirm the connection
5. **You're ready to program!** 🎉

---

## Mobile App Guide

### Main Screen Overview

The following is a historical concept sketch; use [Current P1 operation](#current-p1-operation) for available controls and blocks.

```
┌─────────────────────────────────┐
│  🤖 Educational Robot           │
│  ┌─────────┐    ┌─────────────┐ │
│  │Connected│    │ Battery: 85%│ │
│  └─────────┘    └─────────────┘ │
│                                 │
│  ┌─── Programming Area ────────┐│
│  │                             ││
│  │  Drag blocks here to        ││
│  │  create your program        ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  [▶ Run] [⏹ Stop] [💾 Save]    │
│                                 │
│  ┌─── Block Palette ──────────┐ │
│  │ 🔄 Move  🔁 Turn  ⏱ Wait   │ │
│  │ 🔀 If    🔂 Loop  📡 Sensor │ │
│  └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Key Features

**🔗 Connection Status**
- Green: Connected and ready
- Yellow: Connecting...
- Red: Disconnected - check robot power and Bluetooth

**🔋 Battery Monitor**
- Shows robot's current battery level
- Updates every few seconds
- Warning appears when low

**📱 Real-Time Data**
- Distance to obstacles
- Robot's direction (compass)
- Internal temperature
- Connection quality

---

## Programming Basics

### Understanding Blocks

Your robot understands different types of commands, represented as colorful blocks:

#### 🔄 Movement Blocks (Blue)
- **Move Forward**: Makes robot go straight
- **Move Backward**: Makes robot go in reverse  
- **Turn Left**: Rotates robot left
- **Turn Right**: Rotates robot right

#### ⏱ Timing Blocks (Orange)
- **Wait**: Pause for a whole number of milliseconds; 1000 ms is one second
- **Repeat**: Planned; unavailable in P1

#### 🔀 Logic Blocks (Purple)
- **If Distance <**: Run child blocks when a fresh, valid distance is below the threshold
- **If/Else**: Planned; unavailable in P1

#### 📡 Sensor Blocks (Purple)
- Standalone **Distance** and **Battery** blocks are planned. P1 provides the **If Distance <** condition and the Sensors screen.

### Creating Your First Program

**Let's make the robot move in a square:**

1. **Hold and drag a "Move Forward" block** to the programming area
2. **Set the distance** to 50 cm by tapping the block's heading
3. **Add a "Turn Right" block** below it
4. **Set the angle** to 90 degrees
5. **Repeat these steps** 3 more times
6. **Tap the "Run" button** ▶ to open Robot Execution
7. **Tap "Start"** to begin; use **Stop** to cancel the run

The program requests a square path. Verify motor direction and calibrate distances and angles on the actual robot; open-loop motor steps do not guarantee a perfect square.

### Block Snapping

- **Drop inside If Distance <** to attach a child block; the drop area highlights while it accepts a block
- **Drag a child into another condition** to move it there
- **Drag a child back into the workspace** to make it a top-level block
- **Use Clear** to remove the whole workspace; individual trash-can deletion is not implemented

---

## Learning Levels

The following four lesson outlines are historical curriculum material. The current app exposes five level labels, with only the blocks listed in [Current P1 operation](#current-p1-operation) implemented. References below to loops, comparisons and If/Else describe planned lessons.

### 🟢 Level 1: Basic Movement (Ages 7-8)
**What You'll Learn:**
- How to make the robot move forward and backward
- How to turn left and right
- How to create simple shapes

**Available Blocks:**
- Move Forward/Backward
- Turn Left/Right
- Basic timing

**Sample Challenge:**
*"Make your robot draw a triangle by moving and turning!"*

**Success Criteria:**
- Complete 3 basic movement programs
- Create a simple shape (triangle, square, or star)
- Understand cause and effect of each block

---

### 🟡 Level 2: Sequences and Timing (Ages 8-10)
**What You'll Learn:**
- How to create longer sequences
- Using wait blocks for timing
- Making patterns and dances

**New Blocks Added:**
- Wait (with time setting)
- Repeat (basic loops)

**Sample Challenge:**
*"Program your robot to do a dance with moves and pauses!"*

**Success Criteria:**
- Create programs with 10+ blocks
- Use timing to create rhythmic patterns
- Combine movement and waiting effectively

---

### 🟠 Level 3: Sensors and Decisions (Ages 9-11)
**What You'll Learn:**
- How robots can "see" obstacles
- Making decisions based on sensor data
- Creating reactive behaviors

**New Blocks Added:**
- If (conditional logic)
- Distance sensor reading
- Compare blocks (greater than, less than)

**Sample Challenge:**
*"Make your robot avoid obstacles by checking distance!"*

**Success Criteria:**
- Use sensors to make decisions
- Create programs that react to environment
- Understand conditional logic

---

### 🔴 Level 4: Autonomous Behavior (Ages 10-12)
**What You'll Learn:**
- Complex logic and nested conditions
- Autonomous navigation
- Advanced programming concepts

**New Blocks Added:**
- If/Else (full conditional logic)
- Nested loops
- Advanced sensor combinations
- Autonomous mode

**Sample Challenge:**
*"Program your robot to explore a room completely on its own!"*

**Success Criteria:**
- Create complex, multi-step programs
- Implement autonomous behaviors
- Understand advanced programming concepts

---

## Advanced Features

### 📊 Telemetry Dashboard

Access real-time robot data by tapping the "Data" button:

**Distance Sensor**
- Shows exact distance to nearest obstacle
- Range: 2-400 centimeters
- Updates 10 times per second

**Compass/Heading**
- Shows which direction robot is facing
- 0° = North, 90° = East, 180° = South, 270° = West
- Useful for navigation programs

**System Health**
- Battery percentage and voltage
- Internal temperature (should be 20-40°C)
- Connection signal strength

### 🎮 Manual Control Mode

Sometimes you want to drive the robot directly:

1. **Tap "Manual Control"** in the main menu
2. **Use on-screen joystick** or arrow buttons
3. **Adjust speed** with the slider
4. **Perfect for** testing movements and exploring

### 💾 Saving and Loading Programs

**To Save a Program:**
1. Create your program with blocks
2. Tap the "Save" button 💾
3. Enter a name (1–64 characters) and tap "Save program"
4. Confirm replacement if the name is already used, or cancel and use a new name to keep both copies. Names are case-insensitive.

The program's current level, parameters, positions and nested blocks are stored on this device. The library holds up to 50 named programs, each with up to 100 blocks. Saving an empty draft is allowed. Save after editing; unsaved changes are not automatically restored after closing the app. Uninstalling the app or clearing its data removes these local programs. There is no export or cloud backup yet.

**To Load a Program:**
1. Tap "Open" in the Code screen
2. Select a saved program; its name, lesson and save time are shown
3. If prompted about unsaved changes, cancel to save them first or confirm replacement
4. Continue editing in the program's saved level. That level must be unlocked.

"Clear" asks before removing workspace blocks and leaves saved programs intact. Switching tabs retains the current workspace. A failed save shows an error and keeps the workspace available for retry.

**Robot practice progress:** the progress bar counts five practice checks, from 0% to 100%. Checks are recorded only after the whole program succeeds and the final STOP is confirmed. Follow the requirement displayed above the editor:

| Level | Practice check |
| --- | --- |
| 1 | Execute a nonzero move or turn. |
| 2 | Execute a nonzero move or turn and a nonzero Wait. |
| 3 | Execute a move, turn, Stop or Auto Navigate inside a true If Distance condition. |
| 4 | Complete the three-second Auto Navigate block. |
| 5 | Complete Auto Navigate and the conditional response described for level 3 in one run. |

Skipped branches, zero-valued moves/waits, failures and cancelled runs do not earn these checks. Completing a check unlocks the next lesson; select it on Home. Earlier versions awarded badges from block presence alone: their unlocked lesson access is retained, but their badges are not counted as executed practice. These checks record software execution, not measured wheel travel, course accuracy or educational effectiveness; teachers still assess learning and physical behavior.

**Sharing Programs:**
- File and QR export are not implemented
- Share screenshots of your block programs
- Show friends your robot's movements!

### 🏆 Achievement System

The detailed achievement badges below are planned. The implemented app currently records only the five robot practice checks described above:

**First Steps**
- ✅ First successful program
- ✅ First shape creation
- ✅ First sensor use

**Getting Creative**
- ✅ Program with 20+ blocks
- ✅ Use all block types
- ✅ Create original dance

**Master Programmer**
- ✅ Complete all level challenges
- ✅ Create autonomous behavior
- ✅ Help someone else learn

---

## Maintenance

### Daily Care

**After Each Use:**
- Turn off the robot to save battery
- Put robot in a safe place away from edges
- Clean any dust from sensors with soft cloth

**Weekly Maintenance:**
- Check all connections are secure
- Clean wheels if they've collected debris
- Charge battery if below 50%

### Battery Care

**Charging Best Practices:**
- Stop and recharge around the selected 6.4 V operating target, using a meter until telemetry is calibrated; the firmware does not automatically stop on low battery
- Follow the [external charging procedure](../../hardware/power-system.md#charging-procedure) with the pack removed from the robot
- Follow the external charger's completion indication and instructions; the robot has no implemented charging-status LED
- Follow the pack manufacturer's storage guidance; the selected pack's specification recommends about half charge for long storage
- Replace battery if it swells or won't hold charge

**Battery Runtime:**
- Runtime with the selected pack and updated motor driver has not been measured. Record it during supervised testing; the previous 90/60/45-minute figures are not verified expectations for this revision.

### Storage

**Short-term (1-7 days):**
- Turn off robot
- Store on flat surface away from edges
- Room temperature location

**Long-term (weeks/months):**
- Prepare the battery for storage according to its manufacturer's instructions
- Remove battery and store separately
- Keep in original box or safe location
- Avoid extreme temperatures

---

## Troubleshooting

### Connection Problems

**🔴 Can't find robot in app:**
1. Check the robot's supply/switch and startup messages; no specific robot LED indicates readiness in this firmware
2. Check Bluetooth is enabled on your device
3. Move closer to robot (within 3 meters)
4. Restart the app
5. Try turning robot off and on again

**🔴 Connection keeps dropping:**
1. Check robot battery level (charge if low)
2. Move away from WiFi routers and other devices
3. Close other Bluetooth apps
4. Keep device closer to robot during use

### Programming Issues

**🔴 Robot doesn't move as expected:**
1. Check for obstacles in the path
2. Make sure robot is on flat, smooth surface
3. Verify your program logic step-by-step
4. Try simpler movements first

**🔴 Blocks won't snap together:**
1. Hold a toolbox block before dragging it into the workspace
2. Drop onto the highlighted area inside an If Distance < block to nest it
3. Wait and movement blocks cannot contain children; a block cannot be nested inside itself or its descendants
4. Use landscape mode for more space

**🔴 Program stops unexpectedly:**
1. Check if obstacle was detected (safety feature)
2. Verify battery isn't too low
3. Look for error messages in the app
4. Try breaking program into smaller parts

### Hardware Issues

**🔴 Robot makes unusual sounds:**
1. Turn off robot immediately
2. Check for objects caught in wheels
3. Look for loose screws or parts
4. Contact support if sounds continue

**🔴 Sensors seem inaccurate:**
1. Clean sensor lenses with soft, dry cloth
2. Check sensor isn't blocked by decorations
3. Test in different lighting conditions
4. Restart robot to recalibrate

**🔴 LED indicators not working:**
The current firmware does not drive status LEDs. Any LED built into the ESP32, motor driver or external charger follows that component's own behavior; use the app's connection status, serial messages and verified battery measurements to check the robot.

### Getting Help

**When to Contact Support:**
- Hardware damage or unusual behavior
- Persistent connection problems
- Safety concerns
- Questions not covered in this manual

**Support Channels:**
- 📧 Email: ayman.ouchker@outlook.com
- 💬 GitHub Issues: Report bugs and request features

**Before Contacting Support:**
1. Try the troubleshooting steps above
2. Note exactly what you were doing when the problem occurred
3. Check what version of the app you're using
4. Have your robot's serial number ready (found on bottom sticker)

---

## Educational Activities

### 🎯 Structured Learning Activities

#### Activity 1: Robot Dance Party (Level 1-2)
**Age Group:** 7-10 years  
**Time:** 15-20 minutes  
**Learning Goals:** Sequencing, timing, creativity

**Instructions:**
1. Choose your favorite song
2. Program your robot to "dance" to the music
3. Use forward, backward, and turning moves
4. Add wait blocks to match the rhythm
5. Show your dance to family or friends!

**Extensions:**
- Create different dances for different types of music
- Program multiple robots to dance together
- Add LED patterns (if available)

#### Activity 2: Obstacle Course Challenge (Level 3)
**Age Group:** 9-12 years  
**Time:** 30-45 minutes  
**Learning Goals:** Problem-solving, sensor use, debugging

**Setup:**
- Create a simple course with boxes, books, or toys
- Leave clear paths between obstacles
- Make sure robot can fit through gaps

**Instructions:**
1. Program robot to navigate through course
2. Use distance sensor to detect obstacles
3. Add decision-making: if obstacle is close, turn
4. Test and adjust your program
5. Time how fast your robot completes the course!

**Extensions:**
- Make the course more complex
- Program robot to find specific objects
- Create a maze-solving challenge

#### Activity 3: Room Mapping Explorer (Level 4)
**Age Group:** 10+ years  
**Time:** 45-60 minutes  
**Learning Goals:** Autonomous behavior, advanced logic

**Instructions:**
1. Choose a safe room or large area
2. Program robot to explore systematically
3. Use sensors to avoid walls and furniture
4. Create a pattern: wall-following or grid search
5. Challenge: Can your robot return to start position?

**Extensions:**
- Draw a map of where the robot went
- Program robot to find the largest open space
- Create a "search and rescue" scenario

### 🏫 Classroom Integration Ideas

#### Mathematics Integration
**Geometry and Measurement:**
- Program robots to draw geometric shapes
- Calculate perimeter and area of robot's path
- Explore angles through turning commands
- Practice measurement using distance moves

**Example Lesson Plan:**
```
Topic: Understanding Perimeter
1. Review perimeter concept (5 minutes)
2. Program robot to trace rectangle (15 minutes)
3. Measure actual vs. programmed distances (10 minutes)
4. Calculate and verify perimeter (10 minutes)
5. Challenge: Create shape with specific perimeter (15 minutes)
```

#### Science Integration
**Physics Concepts:**
- Distance, speed, and time relationships
- Forces and motion through robot movement
- Sensor technology and measurement
- Energy and battery concepts

**Programming as Scientific Method:**
- Hypothesis: "Robot will move exactly 100cm"
- Experiment: Program and test movement
- Observation: Measure actual distance
- Analysis: Calculate error and adjust
- Conclusion: Understand real-world vs. theory

#### Language Arts Integration
**Storytelling with Robots:**
- Create stories where robot is the main character
- Program robot to act out story scenes
- Write step-by-step instructions (technical writing)
- Present robot programs to class (public speaking)

### 👨‍👩‍👧‍👦 Family Learning Activities

#### Parent-Child Programming Sessions
**For Parents New to Programming:**

**Session 1: Introduction (30 minutes)**
- Learn together - no pressure to know everything
- Start with simple forward/backward movements
- Celebrate small successes
- Let child teach you what they discover

**Session 2: Problem Solving (45 minutes)**
- Give robot a "mission" (reach a toy, avoid obstacles)
- Work together to solve the challenge
- Discuss different approaches
- Learn from "failures" - they're learning opportunities!

**Session 3: Creative Expression (60 minutes)**
- Let child lead the programming
- Ask questions: "What do you think will happen?"
- Encourage experimentation
- Document creations with photos/videos

#### Sibling Collaboration Projects
**For Multiple Children:**

**Relay Programming:**
- Each child programs one part of a longer sequence
- Robot must complete all parts successfully
- Teaches planning and teamwork
- Great for different skill levels

**Robot Olympics:**
- Create different "events" (speed, accuracy, creativity)
- Each child programs robot for their event
- Friendly competition with scoring
- Celebrate all achievements

### 🎓 Assessment and Progress Tracking

#### Self-Assessment Questions
**For Students to Ask Themselves:**

**After Each Programming Session:**
- What did I learn today?
- What was challenging and how did I solve it?
- What would I like to try next time?
- How can I help someone else learn this?

**Weekly Reflection:**
- What programming concepts do I understand now?
- What real-world problems could robots help solve?
- How has my problem-solving improved?
- What questions do I still have?

#### Portfolio Development
**Document Learning Journey:**

**Week 1-2: First Steps**
- Screenshots of first programs
- Photos of robot completing tasks
- Written description of what was learned

**Week 3-4: Building Complexity**
- More sophisticated program examples
- Problem-solving strategies discovered
- Collaboration experiences with others

**Week 5-6: Advanced Projects**
- Original robot challenges created
- Teaching moments with younger children
- Connections made to other subjects

#### Progress Indicators
**Observable Signs of Learning:**

**Beginner (Level 1-2):**
- Can create simple sequential programs
- Understands cause-and-effect of commands
- Shows persistence when programs don't work
- Expresses excitement about robot's movements

**Intermediate (Level 3):**
- Uses logical thinking to solve problems
- Incorporates sensor feedback into programs
- Explains thinking process to others
- Creates original challenges

**Advanced (Level 4):**
- Designs complex, multi-step solutions
- Debugs programs systematically
- Helps others learn programming concepts
- Makes connections to real-world applications

---

## Appendices

### Appendix A: Block Reference Guide

**Current movement/Wait parameters and historical planned block examples:** only the blocks in [Current P1 operation](#current-p1-operation) are available. Repeat, If/Else and standalone sensor blocks below are planned.

#### Movement Blocks
```
Move Forward [distance]
- Example: Move Forward 50cm
- Makes robot go straight ahead
- Distance: 0-500 whole centimeters

Move Backward [distance]  
- Example: Move Backward 30cm
- Makes robot go in reverse
- Distance: 0-500 whole centimeters

Turn Left [angle]
- Example: Turn Left 90°
- Rotates robot counterclockwise
- Angle: 0-360 whole degrees

Turn Right [angle]
- Example: Turn Right 45°
- Rotates robot clockwise  
- Angle: 0-360 whole degrees
```

#### Control Blocks
```
Wait [time]
- Example: Wait 2000 ms (two seconds)
- Pauses program execution
- Time: 0-60000 whole milliseconds

Repeat [number] times
- Example: Repeat 4 times
- Executes contained blocks multiple times
- Number: 1-100 repetitions

If [condition]
- Example: If distance < 20cm
- Executes blocks only if condition is true
- Conditions: sensor comparisons

If [condition] Else
- Executes first blocks if true, second if false
- Useful for either/or decisions
```

#### Sensor Blocks
```
Distance Sensor
- Returns current obstacle distance
- Range: 2-400 centimeters
- Updates continuously

Battery Level
- Returns current battery percentage
- Range: 0-100%
- Useful for low-battery behaviors
```

### Appendix B: Error Messages and Solutions

**Common error messages you might see:**

```
"Robot not responding"
→ Check connection and battery level

"Obstacle detected - stopping"
→ Clear path or adjust program logic

"Invalid distance value"
→ Use whole numbers between 0-500 for movement

Low battery
→ Stop and recharge; an automatic low-battery movement lockout is not implemented

"Connection lost"
→ Move closer to robot, check Bluetooth
```

### Appendix C: Technical Specifications

**Historical capability targets (unverified for the selected P1 hardware):**
- Movement accuracy: ±2cm per meter
- Rotation accuracy: ±5 degrees
- Speed: the current 500 half-steps/s and assumed 65 mm wheel / 4096 half-steps per revolution imply approximately 2.5 cm/s before external gearing; measure the assembled robot
- Battery life: measurement pending with the selected 2200 mAh pack
- Sensor range: 2-400cm
- Operating temperature: 0-40°C
- Bluetooth range: 12+ meters line-of-sight

**Mobile App Requirements:**
- Android 7.0+ (API 24 minimum for the current build; iOS release support pending)
- Bluetooth 4.0+ (BLE support)
- 50MB storage space
- 2GB RAM recommended

### Appendix D: Warranty and Support

The following is historical packaged-product planning material. This DIY repository establishes no included battery/charger warranty or return service; use the selected component suppliers' actual terms.

**Limited Warranty:**
- Hardware: 1 year from purchase date
- Software: Free updates and bug fixes
- Battery: 6 months or 300 charge cycles
- Excludes damage from misuse or accidents

**What's Covered:**
- Manufacturing defects
- Component failures under normal use
- Software bugs and compatibility issues

**What's Not Covered:**
- Physical damage from drops or impacts
- Water damage
- Normal wear and tear
- Battery degradation after warranty period

**Warranty Claims:**
1. Contact support with serial number
2. Describe the problem in detail
3. Follow troubleshooting steps if requested
4. Return shipping instructions will be provided

---

**Need More Help?**

📧 **Email:** ayman.ouchker@outlook.com  
📱 **Community:** Join our Discord server for tips and project sharing

**Thank you for choosing our Educational Robot!**  
*Happy programming and learning! 🚀*

---

*User Manual Version 1.0 - Last Updated: June 2025*  
*© 2025 Educational Robot Project - Open Source MIT License*
