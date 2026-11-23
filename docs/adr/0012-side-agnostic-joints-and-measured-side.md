---
status: accepted
---

# Exercises name joints without a side; the measured side is chosen at framing

The rules file names an exercise's required joints and measurements by joint (hip, knee, ankle…), not by MediaPipe landmark index. When framing becomes valid, the side whose required landmarks have the higher mean visibility becomes the measured side, and it stays fixed for the set. A side view shows only one side clearly, and which one depends on where the tripod stands relative to the machine. Hardcoding the left side, as the Diseño §8.5 example does with landmarks 23/25/27, would fail whenever the phone is on the other side.

**Consequences:** this changes the rules-file format in Diseño §8.5. Every landmark recording stores the measured side so it can be interpreted later.
