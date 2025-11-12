plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smarthomedevices_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // FIX: Ensure Java 11 is used
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // FIX: Ensure the Kotlin compiler also targets Java 11
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.smarthomedevices_app"
        minSdk = flutter.minSdkVersion
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

dependencies {

    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))


    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
}