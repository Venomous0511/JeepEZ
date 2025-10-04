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

    // Kotlin DSL version of keystore loading
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties().apply {
        load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            val keystorePath: String? = project.findProperty("KEYSTORE_PATH") as String?
            val keystoreAlias: String? = project.findProperty("KEYSTORE_ALIAS") as String?
            val keystorePassword: String? = project.findProperty("KEYSTORE_PASSWORD") as String?
            val keyPassword: String? = project.findProperty("KEYSTORE_KEY_PASSWORD") as String?

            if (!keystorePath.isNullOrEmpty() && !keystoreAlias.isNullOrEmpty() && !keystorePassword.isNullOrEmpty() && !keyPassword.isNullOrEmpty()) {
                storeFile = file(keystorePath)
                storePassword = keystorePassword
                keyAlias = keystoreAlias
                keyPassword = keyPassword
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
