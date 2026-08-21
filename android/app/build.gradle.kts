plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.goulgrid"   // ← نام پکیج را مطابق پروژه خود تنظیم کنید
    compileSdk = 34
    ndkVersion = "27.0.12077973"        // ✅ اضافه شد

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true   // ✅ فعال‌سازی desugaring
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.goulgrid"   // ← باید با namespace یکسان باشد
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // وابستگی‌های Flutter (معمولاً خودکار است)
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ وابستگی برای core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}
