> Historical assembly guide preserved before the 8 October 2026 handoff revision. Dimensions, print settings, time estimates, performance targets and unverified procedures below are not current build instructions. Use the [current assembly guide](../assembly-guide.md), [wiring](../../hardware/wiring.md) and [power specification](../../hardware/power-system.md). Original text is retained for provenance.

# Educational Robot Assembly Guide

> **P1 hardware selection (8 October 2026):** build toward the [selected 5 V motor and protected battery system](../../hardware/power-system.md), using the [eight-input wiring map and sensing dividers](../../hardware/wiring.md). The previous STEP/DIR wiring is obsolete. Physical wiring, loading and CAD fit still require verification. STL filenames below are planned exports; those files are not yet supplied.

## Table of Contents
1. [Safety Information](#safety-information)
2. [Required Tools and Materials](#required-tools-and-materials)
3. [Component Overview](#component-overview)
4. [3D Printing Instructions](#3d-printing-instructions)
5. [Electronic Assembly](#electronic-assembly)
6. [Mechanical Assembly](#mechanical-assembly)
7. [Software Installation](#software-installation)
8. [Testing and Calibration](#testing-and-calibration)
9. [Troubleshooting](#troubleshooting)

---

## Safety Information

⚠️ **IMPORTANT SAFETY WARNINGS**

- **Adult supervision required** for children under 12
- **Soldering iron safety**: Use proper ventilation and safety equipment
- **Battery safety**: Never short circuit, puncture or dismantle the selected protected Li-ion pack
- **3D printer safety**: Ensure proper ventilation and temperature controls
- **Small parts warning**: Keep away from children under 3 years

### Required Safety Equipment
- Safety glasses for 3D printing and soldering
- Well-ventilated workspace
- Fire extinguisher nearby when working with batteries
- First aid kit accessible

---

## Required Tools and Materials

### Tools Needed
- [ ] 3D printer (minimum 200×200×200mm build volume)
- [ ] Soldering iron (25-40W) with fine tip
- [ ] Wire strippers
- [ ] Small Phillips head screwdriver
- [ ] Hot glue gun
- [ ] Multimeter (for testing)
- [ ] Computer with PlatformIO for the current firmware

### Consumables
- [ ] PLA filament (200g minimum) - White or colored
- [ ] TPU filament (50g) - For wheels (optional)
- [ ] 60/40 rosin-core solder
- [ ] Heat shrink tubing (various sizes)
- [ ] Jumper wires (male-to-female, 20cm)
- [ ] Hot glue sticks

### Hardware Components
- [ ] M3×12mm screws (8 pieces)
- [ ] M3×8mm screws (4 pieces)
- [ ] M3 nuts (12 pieces)
- [ ] M2×6mm screws (4 pieces) - For sensor mounting
- [ ] Motor-mount hardware selected after checking the delivered Olimex kit's M4 holes and bracket thickness; the historical M3 list is not a verified motor-mount specification

---

## Component Overview

### Electronic Components

Use the [selected bill of materials](../../README.md#-selected-bill-of-materials) and [power-system specification](../../hardware/power-system.md) as the common parts list. It selects two Olimex 5 V motor/ULN2003 kits, Tenergy 31003 protected pack, Pololu D24V22F5 and Tenergy TLP-4000, plus the specified harness, fuse, switch, capacitors and sensing dividers. Controller and sensor parts remain as listed in the project. Optional status LEDs are not controlled by the current firmware. A breadboard may be used for signals, but not for motor power distribution.

The old $36 electronic-parts subtotal omitted necessary items and is superseded. Current sourced prices are recorded once in the power specification; a complete delivered build cost remains pending.

### 3D Printed Components

| Part Name | Print Time | Infill | Support Required |
|-----------|------------|--------|------------------|
| Main Chassis | 4 hours | 20% | No |
| Battery Compartment | 2 hours | 15% | No |
| Sensor Mount | 1 hour | 25% | Yes |
| Wheel Hubs | 1 hour | 30% | No |
| Top Cover | 1.5 hours | 15% | No |

---

## 3D Printing Instructions

### Printer Settings
```
Layer Height: 0.2mm
Infill: 20% (cubic pattern)
Print Speed: 50mm/s
Nozzle Temperature: 210°C (PLA) / 230°C (TPU)
Bed Temperature: 60°C
Support: Only where specified
Brim: Recommended for better adhesion
```

### Pre-Print Checklist
- [ ] Bed properly leveled and clean
- [ ] Filament dry and properly loaded
- [ ] Nozzle clean and at correct temperature
- [ ] STL files verified in slicer software

### Part-Specific Instructions

**Main Chassis (chassis.stl)**
- Print orientation: Flat on largest surface
- No supports needed
- Critical dimension: the selected motor supplier lists **35 mm hole spacing and M4 holes**; 28 mm is the motor body diameter. Check the delivered kit and update/verify CAD before printing, as described in the [power/parts specification](../../hardware/power-system.md#mechanical-checks-and-acceptance).
- Post-processing: Light sanding of motor mount holes if needed

**Battery Compartment (battery-compartment.stl)**
- Print orientation: Opening facing up
- Add supports for overhangs >45°
- Test fit with actual battery before final assembly
- Critical: Ensure proper ventilation gaps

**Sensor Mount (sensor-mount.stl)**
- Print orientation: Mounting surface down
- Supports required for sensor bracket
- Angle: 15° downward for optimal detection
- Post-processing: Drill out mounting holes with 2mm bit

**Wheel Hubs (wheel-hub.stl) - 2 pieces**
- Print orientation: Flat surface down
- 30% infill for strength
- Critical: 5mm center hole must fit motor shaft exactly
- Test fit before removing supports

**Top Cover (top-cover.stl)**
- Print orientation: Largest surface down
- Include ventilation holes in design
- Optional: Print in transparent filament for LED visibility
- Post-processing: Sand edges for smooth fit

### Quality Check
After printing, verify:
- [ ] All holes are properly sized
- [ ] No warping or layer separation
- [ ] Smooth surfaces where components will mate
- [ ] No support material remaining in critical areas

---

## Electronic Assembly

### Step 1: Prepare the ESP32
1. **Test the ESP32** before assembly
   ```cpp
   // Upload this test code first
   void setup() {
     Serial.begin(115200);
     Serial.println("ESP32 Test - Success!");
   }
   void loop() {
     delay(1000);
   }
   ```

2. **Solder header pins** (if not pre-installed)
   - Use 2.54mm pitch headers
   - Ensure pins are straight and properly seated
   - Test continuity with multimeter

### Step 2: Motor Driver Preparation
1. **Check ULN2003 boards**
   - Inspect IN1..IN4, motor connector and power terminal labels
   - With the wheels raised, verify the half-step coil sequence using the updated firmware

2. **Verify the supply rating**
   - Read the motor voltage label and the driver board documentation
   - Follow [hardware/wiring.md](../../hardware/wiring.md); do not infer board jumper changes from a generic IC datasheet

### Step 3: Sensor Preparation

**HC-SR04 Ultrasonic Sensor**
Connect Echo through the divider in [the wiring guide](../../hardware/wiring.md) before this test. Ordinary HC-SR04 Echo is 5 V logic.
1. Test sensor functionality:
   ```cpp
   const int trigPin = 5;
   const int echoPin = 18;
   
   void setup() {
     Serial.begin(115200);
     pinMode(trigPin, OUTPUT);
     pinMode(echoPin, INPUT);
   }
   
   void loop() {
     digitalWrite(trigPin, LOW);
     delayMicroseconds(2);
     digitalWrite(trigPin, HIGH);
     delayMicroseconds(10);
     digitalWrite(trigPin, LOW);
     
     long duration = pulseIn(echoPin, HIGH);
     float distance = duration * 0.034 / 2;
     
     Serial.printf("Distance: %.2f cm\n", distance);
     delay(500);
   }
   ```

**MPU6050 IMU**
1. Verify I2C communication:
   ```cpp
   #include <Wire.h>
   
   void setup() {
     Serial.begin(115200);
     Wire.begin();
     
     Wire.beginTransmission(0x68); // MPU6050 address
     if (Wire.endTransmission() == 0) {
       Serial.println("MPU6050 found!");
     } else {
       Serial.println("MPU6050 not found!");
     }
   }
   ```

### Step 4: Power System Assembly

**Buck Converter Setup**
1. **Use the fixed-output Pololu D24V22F5**; there is no voltage-adjustment potentiometer
2. **Measure the output before connecting electronics**, then test at the specified input voltages and 1.2 A design load
3. **Fit the specified capacitors and power harness**, then check actual motor-start transients and regulator temperature using the [acceptance procedure](../../hardware/power-system.md#mechanical-checks-and-acceptance)

**Battery Connection**
1. **Fit the keyed J1 harness** specified in the power guide, with verified polarity and insulated contacts
2. **Fit F1, a 2 A DC-rated fuse**, close to the pack positive output; verify fuse, holder, wire rating and startup behavior
3. **Test polarity** multiple times before connecting to circuit

### Step 5: Main Circuit Assembly

**Breadboard Layout**
```
Row 1: ESP32 (pins 1-19)
Row 8: ESP32 (pins 20-38)
Row 15: Motor Driver 1 (Left)
Row 20: Motor Driver 2 (Right)
Row 25: Sensors and power distribution
```

**Connection Table**
| ESP32 Pin | Connection | Component |
|-----------|------------|-----------|
| 5 | Trig Pin | HC-SR04 |
| 18 | Echo through 2.2 kohm / 3.3 kohm divider | HC-SR04 |
| 21 | SDA | MPU6050 |
| 22 | SCL | MPU6050 |
| 26 | IN1 | Left ULN2003 |
| 27 | IN2 | Left ULN2003 |
| 25 | IN3 | Left ULN2003 |
| 33 | IN4 | Left ULN2003 |
| 14 | IN1 | Right ULN2003 |
| 13 | IN2 | Right ULN2003 |
| 32 | IN3 | Right ULN2003 |
| 23 | IN4 | Right ULN2003 |
| 35 | Battery through 20 kohm / 10 kohm divider | 2S pack sensing |
| 3.3V | VCC | MPU6050 |
| Regulated 5V | VCC | HC-SR04 and selected 5 V motor rail |
| GND | GND | All components |

### Step 6: Wiring Best Practices

1. **Use consistent color coding:**
   - Red: +5V power
   - Black: Ground
   - Yellow: Signal wires
   - Blue: I2C (SDA/SCL)

2. **Secure all connections:**
   - Twist and solder wire joints
   - Cover with heat shrink tubing
   - Test continuity before powering on

3. **Cable management:**
   - Route wires away from moving parts
   - Leave service loops for future maintenance
   - Use cable ties or adhesive mounts

---

## Mechanical Assembly

### Step 1: Motor Installation

1. **Prepare motor mounts:**
   - Test fit motors in chassis holes
   - File or sand if too tight (common with PLA shrinkage)

2. **Install motors:**
   - Insert motors from inside chassis
   - Use fasteners that match the actual mounting holes and measured bracket thickness; do not assume the historical M3×12mm hardware fits the selected kit
   - Ensure motor shafts are parallel and level

3. **Attach wheel hubs:**
   - Press fit hubs onto motor shafts
   - Ensure tight fit (use small amount of threadlocker if needed)
   - Test rotation - should be smooth with no wobble

### Step 2: Sensor Mounting

1. **Install ultrasonic sensor:**
   - Mount sensor bracket at 15° downward angle
   - Secure with M2×6mm screws
   - Ensure clear line of sight forward

2. **Install IMU:**
   - Mount as close to robot center as possible
   - Ensure flat, stable mounting surface
   - Orient X-axis pointing forward

### Step 3: Electronic Integration

1. **Install breadboard:**
   - Use double-sided foam tape
   - Position for easy access to connections
   - Ensure no interference with moving parts

2. **Route wiring:**
   - Keep power wires separate from signal wires
   - Secure with small cable ties
   - Leave enough slack for any chassis flexing

### Step 4: Battery Installation

1. **Test battery compartment fit:**
   - Battery should slide in easily but not rattle
   - Adjust compartment size if needed with file or sandpaper

2. **Install power connections:**
   - Make the battery connector accessible for removal and external charging with a compatible charger
   - Follow the [power and charging boundary](../../hardware/wiring.md#power-and-charging-boundary); no onboard charger has been validated
   - Install main power switch in accessible location
   - Add LED power indicator

### Step 5: Final Assembly

1. **Install top cover:**
   - Ensure all wires are properly routed
   - Check that no components interfere with cover
   - Secure with M3×8mm screws

2. **Attach wheels (if using TPU printed wheels):**
   - Press fit onto wheel hubs
   - Ensure wheels are aligned and balanced
   - Test rotation and ground contact

---

## Software Installation

### Step 1: Development Environment Setup

**PlatformIO**
1. Install Visual Studio Code
2. Install PlatformIO extension
3. Clone the repository and open the `firmware` folder
4. Check the wiring against [hardware/wiring.md](../../hardware/wiring.md) before powering the motors

The supported project is the multi-file application in `firmware/src`, built with `firmware/platformio.ini`. The archived Arduino sketch uses the old driver assumptions and is not an upload target for this revision.

### Step 2: Library Installation

PlatformIO installs the pinned platform and libraries from `platformio.ini`. From the `firmware` directory, build before connecting the robot:

```bash
pio run
```

### Step 3: Code Upload

1. **Connect ESP32** via USB cable
2. **Check the ESP32 board and serial port** against the PlatformIO configuration
3. **Upload firmware:**
   ```bash
   pio run --target upload
   ```

### Step 4: Initial Configuration

1. **Open Serial Monitor** (115200 baud)
2. **Verify startup messages:**
   ```
   E-Bug Educational Robot Starting...
   Version: 1.0.0
   Motor control initialized
   Sensor management... OK
   BLE communication... OK
   Navigation system... OK
   Robot ready for commands...
   ```

3. **Test basic functions:**
   - BLE advertising should start
   - Sensors should report valid readings
   - Motors should respond to test commands

---

## Testing and Calibration

### Step 1: System Health Check

**Power System Test**
- [ ] Battery voltage: 6.4-8.4 V operating target; recharge before reaching the specified 6.0 V endpoint
- [ ] 5 V rail: 4.8-5.2 V at the design test load and during actual operation
- [ ] Validate the calculated 1.2 A output-load budget, startup behavior and fuse choice; record actual idle/moving current instead of assuming the old <800 mA figure

**Sensor Test**
- [ ] Ultrasonic: Range 2-400cm, stable readings
- [ ] IMU: No error messages, reasonable temperature
- [ ] BLE: Discoverable from mobile device

**Motor Test**
- [ ] Left motor: Smooth rotation both directions
- [ ] Right motor: Smooth rotation both directions
- [ ] Synchronization: Both motors start/stop together

### Step 2: Movement Calibration

**Distance Calibration**
1. Place robot on smooth, flat surface
2. Mark starting position
3. Command 100cm forward movement
4. Measure actual distance traveled
5. Check `STEPS_PER_REV` and `WHEEL_DIAMETER` in `firmware/src/config.h` against the measured gearing and wheel travel

Use the current motor/wheel configuration in `firmware/src/config.h`; account for any external gears. The old 200-pulse STEP/DIR calibration does not apply to the ULN2003 half-step driver.

**Rotation Calibration**
1. Mark robot's starting orientation
2. Command 90° rotation
3. Measure actual rotation angle
4. Adjust `ROBOT_WIDTH` in `firmware/src/config.h` only after measuring the actual wheel track and calibrating wheel travel

**Surface Adaptation**
- Test on different surfaces (tile, carpet, wood)
- Note any variations in accuracy
- Consider implementing surface-specific calibration

### Step 3: Mobile App Integration

**BLE Connection Test**
1. Install mobile app on test device
2. Ensure robot is discoverable
3. Test connection establishment (<5 seconds)
4. Verify bidirectional communication

**Programming Interface Test**
1. Create simple forward movement program
2. Verify program execution matches expectation
3. Test all programming blocks
4. Confirm telemetry data accuracy

**Range Testing**
1. Test BLE range in open space (should reach 12m)
2. Test through common obstacles (walls, furniture)
3. Verify graceful handling of connection loss

### Step 4: Educational Validation

**Age Group Testing (if possible)**
1. Test with children aged 7-12
2. Observe ease of use and engagement
3. Note any confusion points or improvements needed
4. Document successful completion rates

**Curriculum Alignment**
1. Verify learning objectives are met
2. Test progressive difficulty curve
3. Ensure age-appropriate complexity
4. Validate the supervised operating procedure and document its limits

---

## Troubleshooting

### Common Assembly Issues

**Problem: Motors don't turn smoothly**
- Check motor mounting screws aren't over-tightened
- Verify motor driver connections
- Test motor independently of robot chassis
- Check for mechanical interference

**Problem: Inconsistent sensor readings**
- Verify sensor power supply (5V for HC-SR04, 3.3V for MPU6050)
- Check wire connections for intermittent contact
- Ensure sensors are firmly mounted
- Test in different environments to rule out interference

**Problem: BLE connection fails**
- Verify ESP32 is programmed correctly
- Check for correct BLE UUIDs in code
- Ensure mobile device BLE is enabled
- Try restarting both devices

**Problem: Battery drains quickly**
- Check for short circuits with multimeter
- Verify buck converter efficiency
- Look for unnecessary current draws
- Consider battery capacity vs. expected runtime

### Performance Issues

**Problem: Robot movements are jerky**
- Adjust stepper motor speed (increase delay values)
- Check power supply stability under load
- Verify mechanical assembly smoothness
- Verify the motor supply rating and ULN2003 coil wiring; this board has no adjustable STEP/DIR driver current setting

**Problem: Navigation seems erratic**
- Keep the robot still and level during startup gyro calibration; the MPU6050 does not provide a compass heading
- Check ultrasonic sensor mounting angle
- Verify obstacle detection thresholds
- Test navigation algorithm in controlled environment

### Software Issues

**Problem: Upload fails**
- Check USB cable and connections
- Verify correct board selection in IDE
- Try different USB port
- Hold BOOT button during upload if needed

**Problem: Sensor data appears incorrect**
- Verify pin assignments match code
- Check sensor orientation (especially IMU)
- Test sensors individually with simple code
- Verify I2C address for MPU6050 (usually 0x68)

### Getting Help

If you encounter issues not covered here:

1. **Check GitHub Issues** for similar problems
2. **Review serial monitor output** for error messages
3. **Test components individually** to isolate problems
4. **Document your specific setup** when asking for help
5. **Include photos** of wiring and assembly if needed

**Support Channels:**
- GitHub Issues: Technical problems and bugs
- Email: ayman.ouchker@outlook.com
- Documentation: Complete guides and tutorials

---

## Appendix

### A. Bill of Materials with Supplier Links
[Include specific part numbers and recommended suppliers]

### B. 3D Printing Troubleshooting
[Common 3D printing issues specific to these parts]

### C. Alternative Component Options
[Substitute components for different budgets or availability]

### D. Advanced Modifications
[Optional enhancements for advanced users]

---

**Assembly Time:** 4-6 hours (experienced) / 8-12 hours (beginner)  
**Difficulty Level:** Intermediate (requires basic soldering skills)  
**Age Recommendation:** 14+ for assembly, 7+ for use

*P1 motor/power selection updated: 8 October 2026. Mechanical dimensions and historical performance estimates remain subject to physical validation.*
