plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.danyelalgo.gymassistant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.danyelalgo.gymassistant"
        // Android 13 (RNF-15).
        minSdk = 33
        targetSdk = flutter.targetSdkVersion
        // Version code and name come from pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two builds that install side by side on the same phone (ADR-0013):
    // `play` is the public release; `research` adds landmark recording and the debug panel,
    // and overrides the launcher label in src/research/res.
    flavorDimensions += "distribution"
    productFlavors {
        create("play") {
            dimension = "distribution"
        }
        create("research") {
            dimension = "distribution"
            applicationIdSuffix = ".research"
            versionNameSuffix = "-research"
        }
    }

    buildTypes {
        release {
            // TODO: Add a release signing config before publishing to Google Play.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(project(":analysis-core"))
}

flutter {
    source = "../.."
}
