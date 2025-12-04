# Flutter
-keep class io.flutter. app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io. flutter.util.** { *; }
-keep class io.flutter.view. ** { *; }
-keep class io.flutter.** { *; }
-keep class io. flutter.plugins.** { *; }

# Firebase
-keep class com.google. firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com. google.android.gms.**

# Preserve generic signatures
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep crash reporting
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang. Exception