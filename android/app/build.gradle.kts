plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.safety_app"
    ndkVersion = "27.0.12077973"

    // Usaremos 34 para máxima estabilidad
    compileSdk = 35

    compileOptions {
        // SINTAXIS KOTLIN CORREGIDA
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.safety_app"
        minSdk = 23
        // El targetSdk debe coincidir con compileSdk
        targetSdk = 35
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
    // ... tus otras dependencias ...

    // SINTAXIS KOTLIN CORREGIDA: Se usa como una función con paréntesis
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}