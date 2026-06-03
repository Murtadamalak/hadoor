# Flutter proguard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# url_launcher
-keep class androidx.browser.** { *; }

# Keep all app classes
-keep class com.attendance.hadoor.** { *; }

# Suppress warnings for missing classes
-dontwarn androidx.preference.**
-dontwarn androidx.recyclerview.**
-dontwarn androidx.window.**
