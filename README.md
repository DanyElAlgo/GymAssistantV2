# GymAssistant

Android app (Flutter UI plus a native Kotlin analysis module) that watches a user on one of three gym machines through the phone camera, counts repetitions, raises live alerts for posture errors and tracks progress over weeks. Minimum supported version: Android 13.

## Builds

Two Android flavors install side by side on the same phone (ADR-0013):

| Flavor | Application ID | Purpose |
| --- | --- | --- |
| `play` (default) | `io.github.danyelalgo.gymassistant` | Public release |
| `research` | `io.github.danyelalgo.gymassistant.research` | Reference phones: landmark recording and debug panel |

```sh
flutter run                      # play
flutter run --flavor research
```

## Tests

```sh
flutter analyze
flutter test
cd android && ./gradlew :analysis-core:test   # JUnit, JDK 17
```

`android/analysis-core` is a pure Kotlin/JVM module with the analysis domain (ADR-0010), so its tests run on the desktop without a phone. GitHub Actions runs all three on every pull request and every push to `main`.
