import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Force build outputs into the Flutter project folder so `flutter run` can find the APK.
val flutterBuildDir = file("../build")
rootProject.layout.buildDirectory.set(flutterBuildDir)

subprojects {
    project.layout.buildDirectory.set(File(flutterBuildDir, project.name))
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(flutterBuildDir)
}