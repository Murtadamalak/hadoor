allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force all Kotlin dependencies to use a consistent version.
    // This fixes the "Corrupt serialized resolution result" error caused by
    // some plugins pulling kotlin-stdlib-common:1.8.22 while the project
    // uses Kotlin 2.1.0 (which merged stdlib-common into stdlib).
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
                because("Force all Kotlin artifacts to align on version 2.1.0")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
subprojects {
    plugins.withId("com.android.application") {
        configure<com.android.build.gradle.BaseExtension> {
            buildToolsVersion = "36.0.0"
        }
    }
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.BaseExtension> {
            buildToolsVersion = "36.0.0"
        }
    }
}
