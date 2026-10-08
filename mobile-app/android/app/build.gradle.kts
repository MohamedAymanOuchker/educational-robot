import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// CI may compile an explicitly unsigned release without access to private keys.
// Normal release builds must use the owner's key; never fall back to debug signing.
val unsignedRelease = providers.environmentVariable("ROBOCODE_UNSIGNED_RELEASE")
    .orNull == "true"
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (!unsignedRelease && keystorePropertiesFile.isFile) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val validateReleaseConfiguration = tasks.register("validateReleaseConfiguration") {
    group = "verification"
    description = "Require private signing configuration for distribution builds."
    doLast {
        if (unsignedRelease) {
            logger.lifecycle("UNSIGNED RELEASE CHECK ONLY: this output cannot be installed or distributed.")
        } else {
            val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
                .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
            check(missing.isEmpty()) {
                "Release signing is not configured (missing: ${missing.joinToString()}). " +
                    "Create android/key.properties from key.properties.example. " +
                    "See docs/android-release.md. Debug builds do not require a release key."
            }
            check(rootProject.file(keystoreProperties.getProperty("storeFile")).isFile) {
                "Release keystore file does not exist. Check storeFile in android/key.properties."
            }
            check(keystoreProperties.getProperty("keyAlias") != "androiddebugkey") {
                "The Android debug key must not be used for distribution. Use a private upload key."
            }
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseConfiguration)
}

android {
    namespace = "io.github.mohamedaymanouchker.robocode"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.mohamedaymanouchker.robocode"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "RoboCode")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            storeFile = keystoreProperties.getProperty("storeFile")
                ?.takeIf { it.isNotBlank() }?.let { rootProject.file(it) }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            resValue("string", "app_name", "RoboCode (Test)")
        }
        getByName("profile") {
            applicationIdSuffix = ".profile"
            versionNameSuffix = "-profile"
            resValue("string", "app_name", "RoboCode (Profile)")
        }
        release {
            resValue("string", "app_name", "RoboCode")
            signingConfig = if (unsignedRelease) null else signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
