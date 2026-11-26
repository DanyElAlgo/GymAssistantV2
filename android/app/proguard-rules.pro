# MediaPipe Tasks reads its protobuf-lite messages by reflection (field names such as
# `platform_`), so R8 must keep them as they are in release builds.
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
# Its logger, Flogger, finds the calling class on the stack by name.
-keep class com.google.common.flogger.** { *; }
-dontwarn com.google.mediapipe.**
