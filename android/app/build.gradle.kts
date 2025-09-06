import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val props = rootProject.file("key.properties")
    if (props.exists()) load(FileInputStream(props))
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.koji.detection_game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.koji.detection_game"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
                ?: throw GradleException("storeFile missing in key.properties")
            val storePw = keystoreProperties.getProperty("storePassword")
                ?: throw GradleException("storePassword missing in key.properties")
            val alias = keystoreProperties.getProperty("keyAlias")
                ?: throw GradleException("keyAlias missing in key.properties")
            val keyPw = keystoreProperties.getProperty("keyPassword")
                ?: throw GradleException("keyPassword missing in key.properties")

            println(">>> storeFile resolves to: " + file(storeFilePath).absolutePath)
            storeFile = file(storeFilePath)           // ← File に変換
            storePassword = storePw
            keyAlias = alias
            keyPassword = keyPw
        }
    }

    buildTypes {
        getByName("debug") {
            // Debug 用設定
            // コードの最適化
            isMinifyEnabled = false
            // リソースの最適化
            isShrinkResources = false
        }
        getByName("release") {
            // いまはデバッグ鍵で署名している状態
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            // リソースの最適化
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

}

flutter {
    source = "../.."
}
