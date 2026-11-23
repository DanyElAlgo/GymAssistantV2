---
status: accepted
---

# Progress metrics are implemented twice: in the app and in the backend

Correct percentage, volume, effective sets, estimated 1RM, technical decline and goal progress are computed in Dart (for the partial dashboard, offline) and in Python (for the full dashboard and the professional's view). The duplication is deliberate: the offline dashboard can't call the backend, and the professional's view can't depend on the user's phone being online.

**Consequences:** both implementations are tested against the same test cases (same inputs, same expected outputs), so the numbers can't drift. A formula change touches both sides and the shared cases in the same change.

Source: Diseño §1.3.
