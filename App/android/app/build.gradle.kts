plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")

}

android {
    namespace = "com.example.bluealert"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // It's usually better to let flutter manage this or use flutter.ndkVersion

    compileOptions {
        // --- FIX 1: Enable core library desugaring ---
        isCoreLibraryDesugaringEnabled = true
        // --- END FIX 1 ---

        // Your existing Java version settings are fine.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.bluealert"
        minSdk = flutter.minSdkVersion // Manually setting to 21 as required by some packages
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// --- FIX 2: Add the dependencies block and the desugaring library ---
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")

}
// --- END FIX 2 ---
