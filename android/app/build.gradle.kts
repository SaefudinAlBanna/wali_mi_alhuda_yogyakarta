// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    // [PERHATIAN]: Pastikan namespace ini sesuai dengan aplikasi orang tua, bukan aplikasi sekolah.
    // Namespace dari aplikasi sekolah: "com.unadigital.pkbmtelagailmuyogyakarta"
    // Namespace dari aplikasi orang tua yang kita kerjakan: "com.unadigital.parent.mialhudayogyakarta"
    // Saya asumsikan namespace Anda yang benar adalah yang di komentar saya, mohon dicek ulang.
    namespace = "com.unadigital.parent.mialhudayogyakarta" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // [PERBAIKAN] Kembali ke Java 11, seperti di aplikasi sekolah yang bekerja
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // [PERBAIKAN] Kembali ke Java 11
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // [PERHATIAN]: Pastikan applicationId ini sesuai dengan aplikasi orang tua, bukan aplikasi sekolah.
        applicationId = "com.unadigital.parent.mialhudayogyakarta" 
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.android.support:multidex:1.0.3") // Perhatikan, ini versi lama
    implementation("com.google.firebase:firebase-appcheck-debug:16.0.0-beta01") 
    implementation("com.google.firebase:firebase-analytics")
}