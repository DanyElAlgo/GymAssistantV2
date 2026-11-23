---
status: accepted
---

# Pose analysis runs in native Kotlin, and Flutter only receives events

Camera capture (CameraX), pose estimation (MediaPipe Pose Landmarker) and the whole analysis (1€ filter, angles, framing check, repetition state machine, posture rules) run in a native Kotlin module. Flutter never sees frames or landmarks: it receives events (framing, phase, repetition, error, performance) over an EventChannel and sends commands over a MethodChannel. Passing frames or landmarks across the Flutter bridge at 15+ fps would add latency, and an alert has to arrive within 300 ms while the repetition is still in progress (RNF-01).

**Consequences:** the analysis domain is plain Kotlin with no Android imports, so the posture rules and the state machine can be unit-tested with JUnit on recorded poses, with no camera or phone (RNF-18). The camera preview and the skeleton overlay are a native PlatformView embedded in Flutter. Adding an exercise means a new `ExerciseAnalyzer` plus rules-file entries, with no UI or sync changes (RNF-16). The channel contract is in Diseño §11.4.

Source: Diseño, "Decisiones que fijan este diseño", §1.2, §2.3.
