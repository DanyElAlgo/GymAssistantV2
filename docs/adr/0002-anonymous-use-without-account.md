---
status: accepted
---

# Training works without an account

A person can install the app and train immediately with no account and no connection; their data stays on the phone and can be attached to an account when they first register or log in. Forcing sign-up before the first set would add friction in the gym (weak signal, no time) and would hurt adoption in the pilot.

**Consequences:** every local record has an owner that may be the placeholder `ANONYMOUS`, and attaching anonymous data must turn those records into normal outbox entries for the new account. Sync and professional links exist only for registered users.

Source: Análisis, "Decisiones de alcance" (RF-01, RF-04).
