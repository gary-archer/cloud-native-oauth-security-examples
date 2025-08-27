plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    compileSdk = 36
    namespace = "com.example.demoapp"

    defaultConfig {
        applicationId = "com.example.demoapp"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {

    // Kotlin extensions
    implementation("androidx.core:core-ktx:1.17.0")

    // Jetpack compose
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation(platform("androidx.compose:compose-bom:2025.08.00"))

    // UI elements
    implementation("androidx.compose.ui:ui:1.9.0")
    implementation("androidx.compose.ui:ui-graphics:1.9.0")
    implementation("androidx.compose.material3:material3:1.3.2")

    // Custom tabs support
    implementation ("androidx.browser:browser:1.9.0")

    // ID token validation
    implementation ("org.bitbucket.b_c:jose4j:0.9.6")

    // API requests and JSON handling
    implementation ("com.squareup.okhttp3:okhttp:5.1.0")
    implementation ("com.google.code.gson:gson:2.13.1")
}