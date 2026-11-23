---
status: accepted
---

# Offline-first: the phone's database is the source of truth for workout sessions

Every workout session is written to the local SQLite database (Drift) first. An outbox then sends it to the cloud when there is a connection, retrying with exponential backoff. The phone generates every identifier (UUID v4) for sessions, sets, repetitions, detected errors and personal goals, so the backend can ignore anything it has already received. Gyms often have weak signal, and the research requires that 100 % of offline repetitions reach the backend exactly once (RNF-05).

**Consequences:** the camera, analysis, feedback and recording modules (M2–M5) must work in airplane mode (RNF-04). Sync endpoints must be idempotent. A repetition is saved as soon as it closes, so a crash mid-set loses nothing (RNF-06).

Source: Diseño §1.1, DE-02, DS-03, DAC-02.
