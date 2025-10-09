import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.jeepez"
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
        applicationId = "com.example.jeepez"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // optional, helps if methods exceed 64K
    }

    // Load key.properties and/or environment variables
    val keystoreProperties = Properties().apply {
        val file = rootProject.file("android/key.properties")
        if (file.exists()) load(FileInputStream(file))
        System.getenv("KEYSTORE_PATH")?.let { setProperty("storeFile", it) }
        System.getenv("KEYSTORE_PASSWORD")?.let { setProperty("storePassword", it) }
        System.getenv("KEY_ALIAS")?.let { setProperty("keyAlias", it) }
        System.getenv("KEY_PASSWORD")?.let { setProperty("keyPassword", it) }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null && file(storeFilePath).exists()) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                println("⚠️ Release signing not configured. APK will be unsigned.")
            }
        }
    }

    buildTypes {
        getByName("release") {
//            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}