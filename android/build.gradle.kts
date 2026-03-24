import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.compile.JavaCompile

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

    tasks.withType<JavaCompile>().configureEach {
        if (!options.compilerArgs.contains("-Xlint:-options")) {
            options.compilerArgs.add("-Xlint:-options")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(flutterBuildDir)
}
