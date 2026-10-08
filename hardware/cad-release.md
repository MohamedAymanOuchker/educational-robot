# CAD inventory and mechanical release

Status on 8 October 2026: **native files inventoried; geometry and assembly references not validated; no printable or neutral exports supplied**. The owner will install CATIA later. Native files have been preserved without renaming or deletion.

## What is present

[cad-inventory.json](cad-inventory.json) records exact relative paths, file sizes and SHA-256 hashes for **10 CATPart files and 4 CATProduct files**. Hashes identify these file versions; they do not verify dimensions, manufacturability or assembly completeness.

| Native file | Bytes | Role in the robot |
| --- | ---: | --- |
| `jh.CATPart` | 553637 | Unverified |
| `Part1.CATPart` | 367475 | Unverified |
| `Part2.CATPart` | 171317 | Unverified |
| `Part3 (1).CATPart` | 83476 | Unverified; byte-identical to Part3 |
| `Part3.CATPart` | 83476 | Unverified; byte-identical to Part3 (1) |
| `Part4.CATPart` | 194926 | Unverified |
| `Part6.CATPart` | 227954 | Unverified |
| `StepperMotor.CATPart` | 78186 | Name suggests a motor model; compatibility with delivered motor unverified |
| `Zoo Text-to-CAD_1.CATPart` | 343300 | Unverified |
| `Zoo Text-to-CAD_2.CATPart` | 321603 | Unverified |
| `Product1 1.CATProduct` | 80326 | Candidate assembly; hierarchy unverified |
| `Product1.CATProduct` | 79714 | Candidate assembly; hierarchy unverified |
| `Product3.CATProduct` | 28491 | Candidate assembly; hierarchy unverified |
| `miter-gear-and-driver-gear-to-drive-it-make-the-driver-gear-one-half-size-of-the-miter-gear (1).CATProduct` | 15896 | Name suggests gears; actual ratio and placement unverified |

Do not delete either Part3 copy until CATIA shows which paths the assemblies reference. File identity does not establish that either filename is unused. Likewise, similar product names do not establish which assembly is final. A filename describing a gear ratio is not a dimensional measurement.

## Work to complete when CATIA is available

1. Open each candidate CATProduct from this folder. Record the CATIA version, missing references, load/update warnings and resolved child paths. Select the actual top-level robot assembly using its contents and the intended physical build.
2. Identify each printable part and each purchased/reference component. Record quantities, mirrored variants, suppressed components and dependencies. Map descriptive part names to existing files before considering native-file renames.
3. Verify dimensions in millimetres: delivered motor mounting and shaft profile, wheel/hub fit, external gear tooth counts and alignment, battery retention/removal, PCB mounting, switch access, wire clearance and sensor sight line. Use [selected parts](power-system.md), with actual measurements taking precedence over provisional envelopes.
4. Check clashes, fastener engagement, wall thickness, free wheel/gear motion and assembly access. Record tolerances and intended fabrication method. Do not infer clearances from screenshots.
5. Export the verified printable parts to STL and suitable neutral geometry to STEP. Record units, source revision, export settings and part quantity. These formats are deliverables to create, not files already present.
6. Reopen exports in an independent viewer/slicer. Confirm scale against a known measured feature, dimensions, orientation and mesh suitability. Slice a critical fit piece first and record the printer/material/settings and result.
7. Supply an assembly drawing or annotated views showing how part names, fasteners and electrical components correspond to the actual design. Complete the mapping below and update the inventory for intentionally revised native files, retaining the prior inventory with the build evidence.

## Part-to-file and export record

The names below describe functions to identify. They do not assert that a matching part exists in the current assembly. Add or remove rows after inspecting the real design.

| Function | Native source + assembly instance | Quantity | Measured critical dimensions / fit | STL / STEP / drawing paths | Verification evidence |
| --- | --- | --- | --- | --- | --- |
| Chassis / structural base | Pending | Pending | Pending | Not supplied | Not checked |
| Motor mounts | Pending | Pending | Delivered mounting holes and shaft access | Not supplied | Not checked |
| Wheel hubs / wheels | Pending | Pending | Shaft profile, diameter, retention | Not supplied | Not checked |
| External gears, if actually used | Pending | Pending | Tooth counts, ratio, alignment | Not supplied | Not checked |
| Battery holder / retention | Pending | Pending | Delivered pack + harness/removal clearance | Not supplied | Not checked |
| Ultrasonic / IMU mount | Pending | Pending | Sensor orientation and sight line | Not supplied | Not checked |
| Electronics mounting / cover, if used | Pending | Pending | PCB spacing, access, insulation | Not supplied | Not checked |

For each export, keep its hash and the native source hash from the inventory. Record any repair or unit conversion. A successful export alone is not a passed physical fit test.

Continue with the [assembly guide](../docs/assembly-guide.md) and [hardware acceptance record](../docs/hardware-acceptance.md) once the necessary geometry and parts are ready.
