---
status: accepted
---

# Errors are detected by angle rules with calibrated thresholds, not a trained model

Each posture error is a hand-written rule over joint angles with a threshold, persistence and priority, and repetitions are counted by a state machine with hysteresis. No classifier is trained. The thresholds live in a versioned JSON rules file shipped as an app asset (`assets/rules/rules_vX.Y.Z.json`), not in code, and every workout session stores the rules version it was measured with. A trained model would need a much larger labelled dataset than the pilot can produce, and rules are explainable to instructors and to the thesis committee. The "model" in CRISP-DM is therefore the set of thresholds, and calibration means fitting them to labelled gym recordings.

**Versioning:** 0.x versions are provisional: concrete but uncalibrated values used during development (F1 ships `rules_v0.1.0.json`). 1.0.0 is the first calibrated version, and pilot data is only measured with 1.x or later. Every version, provisional or not, has concrete values; `null` only appears in the design template.

**Consequences:** changing a threshold means a new rules-file version, never a code change (RF-19, RNF-17). An invalid rules file falls back to the last valid values and logs the error. Pilot results must always be reported together with the rules version used.

Source: Marco Teórico §3.2; Marco Metodológico §2.2; Diseño §1.1, §8.5.
