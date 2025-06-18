# Educational Robot User Manual

## Quick Start Guide

### Welcome to Your Educational Robot! 🤖

Congratulations on your new educational robot! This guide will help you get started with programming and controlling your robot using the mobile app.

**What's in the Box:**
- ✅ Assembled educational robot
- ✅ 7.4V Li-Po battery
- ✅ USB charging cable
- ✅ Quick start card
- ✅ Safety information sheet

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
- Charge battery only with included charger

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

1. **Locate the power switch** on the back of your robot
2. **Install the battery** by sliding it into the compartment
3. **Turn on the robot** - you should see:
   - Green LED: Power on
   - Blue LED: Bluetooth ready (blinking)
   - Brief motor sound: Self-test

4. **Check battery level:**
   - Green LED solid: >50% battery
   - Yellow LED: 20-50% battery
   - Red LED blinking: <20% battery (charge soon!)

### Step 2: Download the App

**For Android:**
1. Download the APK from our GitHub repository
2. Enable "Install from unknown sources" in Settings
3. Install the Educational Robot app
4. Grant Bluetooth and Location permissions

**For iPhone/iPad:**
- Coming soon! Check our website for updates

### Step 3: Connect Your Robot

1. **Open the app** and tap "Find Robot"
2. **Make sure Bluetooth is on** on your phone/tablet
3. **Look for "E-Bug ESP32"** in the device list
4. **Tap to connect** - the blue LED will stop blinking when connected
5. **You're ready to program!** 🎉

---

## Mobile App Guide

### Main Screen Overview

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

#### ⏱ Timing Blocks (Green)
- **Wait**: Pause for a number of seconds
- **Repeat**: Do something multiple times

#### 🔀 Logic Blocks (Orange)
- **If**: Do something only if a condition is true
- **If/Else**: Do one thing or another

#### 📡 Sensor Blocks (Purple)
- **Distance**: Check how far away obstacles are
- **Battery**: Check robot's power level

### Creating Your First Program

**Let's make the robot move in a square:**

1. **Drag a "Move Forward" block** to the programming area
2. **Set the distance** to 50 cm by tapping the number
3. **Add a "Turn Right" block** below it
4. **Set the angle** to 90 degrees
5. **Repeat these steps** 3 more times
6. **Tap the "Run" button** ▶

Your robot should move in a perfect square!

### Block Snapping

- **Blocks snap together** when you drag them close
- **Green highlight** shows where the block will attach
- **Pull blocks apart** by dragging them away
- **Delete blocks** by dragging them to the trash can

---

## Learning Levels

The app includes 4 progressive levels designed for different ages and skill levels:

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
3. Give your program a name
4. Choose a category (Beginner, Intermediate, Advanced)

**To Load a Program:**
1. Tap "Load" from the main menu
2. Browse your saved programs
3. Tap to load and continue editing

**Sharing Programs:**
- Export as QR code (coming in v1.1)
- Share screenshots of your block programs
- Show friends your robot's movements!

### 🏆 Achievement System

Earn badges as you learn:

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
- Charge when battery shows yellow or red
- Don't overcharge (unplug when green LED solid)
- Store with 50-75% charge if not using for weeks
- Replace battery if it swells or won't hold charge

**Battery Life Expectations:**
- New battery: 90+ minutes of active use
- After 6 months: 60+ minutes typical
- After 1 year: 45+ minutes expected

### Storage

**Short-term (1-7 days):**
- Turn off robot
- Store on flat surface away from edges
- Room temperature location

**Long-term (weeks/months):**
- Charge battery to 50-75%
- Remove battery and store separately
- Keep in original box or safe location
- Avoid extreme temperatures

---

## Troubleshooting

### Connection Problems

**🔴 Can't find robot in app:**
1. Make sure robot is turned on (green LED)
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
1. Drag blocks slowly and carefully
2. Look for green highlighting before releasing
3. Try zooming in for better precision
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
1. Check battery charge level
2. Try turning robot off and on
3. Look for loose connections (contact support)

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

**Complete list of all programming blocks with examples:**

#### Movement Blocks
```
Move Forward [distance]
- Example: Move Forward 50cm
- Makes robot go straight ahead
- Distance: 1-200 centimeters

Move Backward [distance]  
- Example: Move Backward 30cm
- Makes robot go in reverse
- Distance: 1-200 centimeters

Turn Left [angle]
- Example: Turn Left 90°
- Rotates robot counterclockwise
- Angle: 1-360 degrees

Turn Right [angle]
- Example: Turn Right 45°
- Rotates robot clockwise  
- Angle: 1-360 degrees
```

#### Control Blocks
```
Wait [time]
- Example: Wait 2 seconds
- Pauses program execution
- Time: 0.1-60 seconds

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
→ Use numbers between 1-200 for movement

"Battery too low for movement"
→ Charge robot before continuing

"Connection lost"
→ Move closer to robot, check Bluetooth
```

### Appendix C: Technical Specifications

**Robot Capabilities:**
- Movement accuracy: ±2cm per meter
- Rotation accuracy: ±5 degrees
- Maximum speed: 25cm/second
- Battery life: 90+ minutes active use
- Sensor range: 2-400cm
- Operating temperature: 0-40°C
- Bluetooth range: 12+ meters line-of-sight

**Mobile App Requirements:**
- Android 5.0+ (iOS coming soon)
- Bluetooth 4.0+ (BLE support)
- 50MB storage space
- 2GB RAM recommended

### Appendix D: Warranty and Support

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