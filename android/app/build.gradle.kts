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

    // The pose models live in the repo's models/ folder, shared with the desktop video tool
    // (ADR-0014). MediaPipe maps them straight from the APK, so they must stay uncompressed.
    sourceSets {
        getByName("main").assets.srcDir("../../models")
    }
    androidResources {
        noCompress += "task"
        // aapt's default ignore list, plus the models' README.
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~:!README.md"
    }

    buildTypes {
        release {
            // TODO: Add a release signing config before publishing to Google Play.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles("proguard-rules.pro")
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
    implementation("androidx.camera:camera-camera2:1.4.2")
    implementation("androidx.camera:camera-lifecycle:1.4.2")
    implementation("androidx.camera:camera-view:1.4.2")
    implementation("com.google.mediapipe:tasks-vision:0.10.26")
}

flutter {
    source = "../.."
}
