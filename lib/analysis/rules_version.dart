/// The rules version the app analyses with (ADR-0006). The native analysis loads
/// `assets/rules/rules_v<version>.json`, and every workout session will store it.
///
/// Changing it picks another shipped file; thresholds never live in code.
const activeRulesVersion = '0.1.0';
