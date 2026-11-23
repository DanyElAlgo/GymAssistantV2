---
status: accepted
---

# Analysis uses the front camera

The phone stands on a tripod with its screen toward the user so live alerts can be read from 2 m (RNF-13), which makes the front camera the analysis camera. The rear camera gives a better image, but the user couldn't see feedback while training. The thesis documents don't state this choice; it belongs in Diseño.

**Consequences:** F1 must confirm that the front camera reaches ≥ 15 fps on the reference phone (RNF-02). The preview is mirrored for the user, but analysis runs on the unmirrored frames, so the skeleton overlay has to be mirrored to line up with the preview. Left and right come from the landmarks, never from the preview's orientation (ADR-0012).
