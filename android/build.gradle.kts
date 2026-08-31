allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // FlutterFire currently declares API 34 in its Android library modules.
    // Compile those libraries with the already installed newer Android SDK so
    // local builds do not depend on downloading the older platform package.
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            compileSdk = 35
        }
    }

    // Match Kotlin targets for plugins that intentionally compile Java 11;
    // the application and newer biometric plugin remain on Java/Kotlin 17.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val java11Plugins = setOf(
            "tflite_flutter",
            "flutter_tts",
            "speech_to_text",
        )
        compilerOptions.jvmTarget.set(
            if (project.name in java11Plugins) {
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            } else {
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            },
        )
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
