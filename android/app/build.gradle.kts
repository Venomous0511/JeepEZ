import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jeepez.app"
    compileSdk = 36
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.jeepez.app"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val ksPath: String? = project.findProperty("KEYSTORE_PATH") as String?
            val ksAlias: String? = project.findProperty("KEYSTORE_ALIAS") as String?
            val ksPassword: String? = project.findProperty("KEYSTORE_PASSWORD") as String?
            val ksKeyPassword: String? = project.findProperty("KEYSTORE_KEY_PASSWORD") as String?

            if (!ksPath.isNullOrEmpty() && !ksAlias.isNullOrEmpty() && !ksPassword.isNullOrEmpty() && !ksKeyPassword.isNullOrEmpty()) {
                storeFile = file(ksPath)
                storePassword = ksPassword
                keyAlias = ksAlias
                keyPassword = ksKeyPassword
            } else {
                println("⚠️ Release signing not configured. APK will be unsigned.")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}