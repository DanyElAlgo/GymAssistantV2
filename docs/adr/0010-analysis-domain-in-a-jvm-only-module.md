---
status: accepted
---

# The analysis domain lives in its own JVM-only Gradle module

The pose-analysis domain lives in a separate pure Kotlin/JVM Gradle module, `analysis-core`, that the Android app module depends on. It holds the 1€ filter, angle calculation and framing check, and from F2 the repetition state machine and posture rules. CameraX, MediaPipe and the Flutter channels stay in the app module. ADR-0004 requires the domain to have no Android imports: a JVM-only module turns that into a compile error instead of a convention, and its JUnit tests run on the desktop in seconds with no phone or emulator. Module boundaries exist only at compile time, so this costs nothing at runtime.

**Considered options:** everything in `android/app` gives the same runtime with the rule enforced only by discipline; a Flutter plugin package adds packaging work without adding isolation.
