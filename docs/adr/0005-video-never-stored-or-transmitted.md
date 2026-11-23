---
status: accepted
---

# Camera frames never leave memory

Frames are processed and discarded inside the Kotlin module. No frame or video is ever written to disk, sent over a channel, or sent over the network. Other gym members appear in the camera image, the pilot needs approval from the university's ethics committee, and the privacy argument in the thesis rests on this guarantee (RNF-07).

**Consequences:** landmarks and angles are data, not images, so they may be stored, for example as calibration recordings. Anything that saves or uploads imagery, including a debug screenshot feature, breaks this guarantee and must be raised with the user first. RNF-07 is verified by reviewing the code and the network traffic.

Source: Análisis RNF-07, §7.2, §7.4; Marco Metodológico §6.1.
