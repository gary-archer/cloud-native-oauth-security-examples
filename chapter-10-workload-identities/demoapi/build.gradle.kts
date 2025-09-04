plugins {
    kotlin("jvm") version "2.2.10"
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

group = "com.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    // Application depenencies
    implementation("com.sparkjava:spark-core:2.9.4")
    implementation("com.google.code.gson:gson:2.13.1")
    implementation("org.slf4j:slf4j-simple:2.0.17")
    
    // Postgres and SPIFFE dependencies
    runtimeOnly("org.postgresql:postgresql:42.7.7")
    runtimeOnly("io.spiffe:java-spiffe-provider:0.8.12")
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

tasks.shadowJar {
    mergeServiceFiles()
    manifest {
        attributes["Main-Class"] = "com.example.demoapi.Main"
    }
}
