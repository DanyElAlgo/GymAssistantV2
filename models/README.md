# Pose models

MediaPipe Pose Landmarker bundles, float16, from Google's official model storage
(`https://storage.googleapis.com/mediapipe-models/pose_landmarker/<variant>/float16/latest/<variant>.task`).
Only Lite and Full are shipped; Heavy is not included (SCRUM-45).

| File | SHA-256 |
| --- | --- |
| `pose_landmarker_lite.task` | `59929e1d1ee95287735ddd833b19cf4ac46d29bc7afddbbf6753c459690d574a` |
| `pose_landmarker_full.task` | `4eaa5eb7a98365221087693fcc286334cf0858e2eb6e15b506aa4a7ecdcec4ad` |

The Android build packages this folder as app assets, and the desktop video tool
(ADR-0014) reads the same Full file, so app and tool estimate poses with the same model.
