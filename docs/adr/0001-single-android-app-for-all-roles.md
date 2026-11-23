---
status: accepted
---

# One Android app for every role, with no web panel

Users, professionals and the administrator all use the same Android app; professional and admin screens appear only when the account's role allows them. A separate professional app or a web admin panel would double the UI work for a one-person thesis project, and the admin's only jobs (approving role requests, exporting research data) are small enough to live in the app.

**Consequences:** navigation is guarded by role (go_router redirects), and the backend must enforce the same role checks independently, because hiding a screen is not authorization.

Source: Análisis, "Decisiones de alcance"; Diseño, "Decisiones que fijan este diseño".
