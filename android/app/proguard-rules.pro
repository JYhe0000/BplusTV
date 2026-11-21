-dontwarn javax.annotation.Nullable
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.OpenSSLProvider

# JNI bindings (jnigen) rely on reflection and native symbol names.
-keep class com.example.piliplus.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# Flutter embedding and plugins that use reflection.
-keep class io.flutter.** { *; }
-keep class com.ryanheise.** { *; }
-keep class com.alexmercerind.** { *; }

# Keep native method names.
-keepclasseswithmembernames class * {
    native <methods>;
}

-dontwarn **
