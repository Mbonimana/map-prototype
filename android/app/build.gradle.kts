import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

//  Load keys.properties (fallback)
val keysProperties = Properties()
val keysFile = rootProject.file("keys.properties")

if (keysFile.exists()) {
    keysProperties.load(keysFile.inputStream())
}

//  Function to decode --dart-define values
fun getDartDefine(key: String): String {
    val dartDefines = project.findProperty("dart-defines") as String? ?: return ""

    val defines = dartDefines.split(",")
        .map { String(Base64.getDecoder().decode(it)) }

    val map = defines.mapNotNull {
        val parts = it.split("=")
        if (parts.size == 2) parts[0] to parts[1] else null
    }.toMap()

    return map[key] ?: ""
}

// Priority: dart-define → fallback: keys.properties
val googleMapsKey = getDartDefine("GOOGLE_MAPS_API_KEY")
    .ifEmpty { keysProperties.getProperty("GOOGLE_MAPS_API_KEY", "") }

android {
    namespace = "com.example.map_prototype_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.map_prototype_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        //  Inject API key into manifest
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsKey
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