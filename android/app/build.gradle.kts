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
    // NDK version - only set if Flutter provides it (allows automatic download if missing)
    if (flutter.ndkVersion != null) {
        ndkVersion = flutter.ndkVersion
    }
    
    // Use a stable build tools version (34.0.0 is widely available and compatible)
    // This prevents download failures with newer versions that may not be available yet
    // If 34.0.0 is not available, Gradle will try to download it automatically
    //buildToolsVersion = "34.0.0"

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
        // Only create release signing config if key.properties exists AND keystore file exists
        // This allows debug builds to work without a keystore
        if (keystorePropertiesFile.exists()) {
            val keyAlias = keystoreProperties["keyAlias"] as String?
            val keyPassword = keystoreProperties["keyPassword"] as String?
            val storeFile = keystoreProperties["storeFile"] as String?
            val storePassword = keystoreProperties["storePassword"] as String?
            
            // Only proceed if all properties are present
            if (keyAlias != null && keyPassword != null && storeFile != null && storePassword != null) {
                // Resolve keystore file path - try relative to app module first, then root
                var keystoreFile = file(storeFile)
                if (!keystoreFile.exists()) {
                    keystoreFile = rootProject.file("app/$storeFile")
                }
                
                // Only create release signing config if keystore file actually exists
                // This prevents errors during debug builds when keystore is missing
                if (keystoreFile.exists()) {
                    create("release") {
                        this.keyAlias = keyAlias
                        this.keyPassword = keyPassword
                        this.storeFile = keystoreFile
                        this.storePassword = storePassword
                    }
                }
                // If keystore file doesn't exist, we silently skip creating the config
                // The release buildType will catch this and throw a helpful error
            }
        }
    }

    buildTypes {
        release {
            // Only set signing config if it exists (don't throw during configuration phase)
            // Validation will happen when release tasks are actually executed
            signingConfigs.findByName("release")?.let {
                signingConfig = it
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Debug builds use auto-generated debug keystore (no configuration needed)
            // Android automatically uses ~/.android/debug.keystore if no signing config is set
        }
    }
}

// Validate release signing config only when release tasks are executed (not during configuration)
afterEvaluate {
    tasks.matching { 
        it.name.contains("Release", ignoreCase = true) && 
        (it.name.contains("Bundle") || it.name.contains("Apk") || it.name.contains("Assemble"))
    }.configureEach {
        doFirst {
            val releaseSigningConfig = android.signingConfigs.findByName("release")
            if (releaseSigningConfig == null) {
                throw GradleException(
                    """
                    Release signing configuration not found!
                    
                    To build a release APK/AAB, you need:
                    1. Create a keystore file: android/app/upload-keystore.jks
                    2. Ensure android/key.properties exists with:
                       - storeFile=upload-keystore.jks
                       - keyAlias=upload
                       - storePassword=<your-password>
                       - keyPassword=<your-password>
                    
                    For debug builds, this is not required (uses auto-generated debug keystore).
                    
                    To create the keystore, run:
                    keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
                    """.trimIndent()
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    
    // FCM for push notifications
    implementation("com.google.firebase:firebase-messaging")
    
    // Note: Play Core libraries removed - they are incompatible with Android 14 (SDK 34)
    // They were only needed for Flutter deferred components, which this app doesn't use
    
    // Core library desugaring for Java 8+ features on older Android versions
    // flutter_local_notifications 19.5.0 requires version 2.1.4 or above
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    
    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}
