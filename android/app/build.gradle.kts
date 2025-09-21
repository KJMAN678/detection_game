import java.util.Properties
import java.io.FileInputStream

val keyFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keyFile.exists()) {
        FileInputStream(keyFile).use { load(it) }
    }
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
<<<<<<< HEAD
        if (keyFile.exists()) {
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
||||||| parent of 60fc0dc (android(build): clean merge-conflict markers and keep release signing conditional (hasKeystore) to unblock Robo CI)
<<<<<<< HEAD
        if (hasKeystore) {
            create("release") {
                val storeFilePath = keystoreProperties.getProperty("storeFile")!!
                val storePw = keystoreProperties.getProperty("storePassword")!!
                val alias = keystoreProperties.getProperty("keyAlias")!!
                val keyPw = keystoreProperties.getProperty("keyPassword")!!
                storeFile = file(storeFilePath)
                storePassword = storePw
                keyAlias = alias
                keyPassword = keyPw
            }
||||||| 482057b
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
=======
        if (keyFile.exists()) {
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
>>>>>>> 62cc787f32799c586737163206b874be3caa0ee9
=======
        if (hasKeystore) {
            create("release") {
                val storeFilePath = keystoreProperties.getProperty("storeFile")!!
                val storePw = keystoreProperties.getProperty("storePassword")!!
                val alias = keystoreProperties.getProperty("keyAlias")!!
                val keyPw = keystoreProperties.getProperty("keyPassword")!!
                storeFile = file(storeFilePath)
                storePassword = storePw
                keyAlias = alias
                keyPassword = keyPw
            }
>>>>>>> 60fc0dc (android(build): clean merge-conflict markers and keep release signing conditional (hasKeystore) to unblock Robo CI)
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
            // release 署名設定が存在する場合のみ適用（CIなど key.properties 不在時の安全策）
            val releaseSigning = signingConfigs.findByName("release")
            if (releaseSigning != null) {
                signingConfig = releaseSigning
            }
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
