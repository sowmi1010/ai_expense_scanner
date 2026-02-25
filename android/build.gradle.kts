import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep Android build outputs on the same drive as pub cache (usually C:) to
// avoid Gradle path-relativize failures on Windows when project is on another drive.
val localAppData =
    System.getenv("LOCALAPPDATA")
        ?: "${System.getProperty("user.home")}\\AppData\\Local"
val newBuildDir = File(localAppData, "ai_expense_scanner\\build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = File(newBuildDir, project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
