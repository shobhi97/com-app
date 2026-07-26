# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Cloud Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Gson/JSON models used by Supabase realtime & google_sign_in internals
-keepattributes Signature
-keepattributes *Annotation*
-keep class * implements java.io.Serializable { *; }

# local_auth / biometric
-keep class androidx.biometric.** { *; }

# Keep line numbers for readable crash reports from Play Console
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
