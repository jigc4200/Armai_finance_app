# Flutter ML Kit Text Recognition ProGuard rules
# Ignore missing language recognizers that are not bundled or needed
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.** { *; }
