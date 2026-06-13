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
    project.evaluationDependsOn(":app")
    extra.set("flutter", mapOf(
        "compileSdkVersion" to 36,
        "targetSdkVersion" to 36,
        "minSdkVersion" to 21,
        "ndkVersion" to "28.2.13676358"
    ))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
