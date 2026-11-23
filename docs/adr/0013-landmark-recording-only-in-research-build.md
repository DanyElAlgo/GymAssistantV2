---
status: accepted
---

# Landmark recording exists only in the research build

The app has two Android build flavors: the Play release and a `research` build (application ID suffix `.research`). The research build is installed only on the reference phones, which run both the calibration recordings and the pilot measurements (MM §4.4, §5.1). Only the research build records. Every set produces a landmark recording automatically, with a switch to turn it off. Each recording is tagged with a participant code, never a name or email, and is exported through the share sheet. Keeping the recorder out of the release build means the public app can't collect per-frame body data at all, while the research protocol still gets a complete recording of every set without participants having to start anything.

**Consequences:** pilot data and the performance figures for RNF-01/02 come from the research build, so it must match the release in everything that affects analysis. Recording runs off the analysis thread, so it can't add latency.
