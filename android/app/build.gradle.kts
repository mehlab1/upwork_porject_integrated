import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

// Load key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kobi.pal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kobi.pal"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            val keyAlias = keystoreProperties["keyAlias"] as String?
            val keyPassword = keystoreProperties["keyPassword"] as String?
            val storeFile = keystoreProperties["storeFile"] as String?
            val storePassword = keystoreProperties["storePassword"] as String?
            
            if (keyAlias != null && keyPassword != null && storeFile != null && storePassword != null) {
                create("release") {
                    this.keyAlias = keyAlias
                    this.keyPassword = keyPassword
                    // Resolve keystore file path - try relative to app module first, then root
                    var keystoreFile = file(storeFile)
                    if (!keystoreFile.exists()) {
                        keystoreFile = rootProject.file("app/$storeFile")
                    }
                    if (!keystoreFile.exists()) {
                        throw GradleException("Keystore file not found. Tried:\n  - ${file(storeFile).absolutePath}\n  - ${rootProject.file("app/$storeFile").absolutePath}\n\nMake sure upload-keystore.jks exists in android/app/ directory.")
                    }
                    this.storeFile = keystoreFile
                    this.storePassword = storePassword
                }
            } else {
                throw GradleException("Missing keystore properties in key.properties. Required: keyAlias, keyPassword, storeFile, storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if it exists (when key.properties is present)
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig != null) {
                signingConfig = releaseSigningConfig
            } else {
                throw GradleException("Release signing config not found! Make sure android/key.properties exists with valid keystore information.")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // FCM for push notifications
    implementation("com.google.firebase:firebase-messaging")
    
    // Note: Play Core libraries removed - they are incompatible with Android 14 (SDK 34)
    // They were only needed for Flutter deferred components, which this app doesn't use
    
    // Core library desugaring for Java 8+ features on older Android versions
    // flutter_local_notifications 19.5.0 requires version 2.1.4 or above
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}