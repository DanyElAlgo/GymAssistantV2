// Pure Kotlin/JVM module: the analysis domain must not depend on Android (ADR-0010),
// so its JUnit tests run on the desktop over recorded poses (RNF-18).
plugins {
    id("org.jetbrains.kotlin.jvm")
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    // The rules file is JSON (Diseño §8.5); only the element tree is used, so no compiler plugin.
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")

    testImplementation(platform("org.junit:junit-bom:5.13.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
    // Tests read the rules files the app ships, from the repository's assets/rules.
    systemProperty("rulesDir", rootProject.file("../assets/rules").absolutePath)
}
