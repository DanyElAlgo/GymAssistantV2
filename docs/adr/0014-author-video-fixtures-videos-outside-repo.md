---
status: accepted
---

# Early test fixtures come from the author's own videos; the videos stay out of the repo

Before any gym recordings exist, the author recorded lat-pulldown sets of themself from the side, oblique and front camera positions, with known errors per repetition. A desktop tool in `tools/` extracts landmark recordings from these videos using the same MediaPipe pose model the app uses. The compressed recordings (side, oblique, idle and no-person clips) and a ground-truth manifest are committed as test fixtures. The videos never enter the repository (MM §6.1). This gives the F1 angle checks and the F2 counting and lat-pulldown rule tests real data months before calibration in the gym.

**Consequences:** the repository is public, so these fixtures publish the author's body measurements, with the author's consent as both subject and owner. Publishing is a one-way door: data pushed to a public repo can't be fully withdrawn. Recordings of anyone else never go into the repo. The desktop and Android MediaPipe runtimes may produce slightly different landmarks, so one clip is checked on the phone before tests depend on exact values. Leg-press and leg-extension rules still need gym data (F4).
