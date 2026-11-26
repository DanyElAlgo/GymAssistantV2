---
status: accepted
---

# Errors are detected by angle rules with calibrated thresholds, not a trained model

Each posture error is a hand-written rule over joint angles with a threshold, persistence and priority, and repetitions are counted by a state machine with hysteresis. No classifier is trained. The thresholds live in a versioned JSON rules file shipped as an app asset (`assets/rules/rules_vX.Y.Z.json`), not in code, and every workout session stores the rules version it was measured with. A trained model would need a much larger labelled dataset than the pilot can produce, and rules are explainable to instructors and to the thesis committee. The "model" in CRISP-DM is therefore the set of thresholds, and calibration means fitting them to labelled gym recordings.

**Versioning:** 0.x versions are provisional: concrete but uncalibrated values used during development (F1 ships `rules_v0.1.0.json`). 1.0.0 is the first calibrated version, and pilot data is only measured with 1.x or later. Every version, provisional or not, has concrete values; `null` only appears in the design template.

**Consequences:** changing a threshold means a new rules-file version, never a code change (RF-19, RNF-17). The active version is a single constant in the Flutter app, which sends it to the native analysis and stores it with each workout session; pointing it at another shipped file is the only code change a new version needs. An invalid rules file, or one whose declared version differs from the one asked for, is refused with `INVALID_CONFIG` and the error is logged. It is never replaced by other values, because a set measured with thresholds nobody chose would corrupt pilot data. The files ship inside the app, so a JUnit test loads every one of them and CI stops an invalid file before release. Pilot results must always be reported together with the rules version used.

Source: Marco Teórico §3.2; Marco Metodológico §2.2; Diseño §1.1, §8.5.
