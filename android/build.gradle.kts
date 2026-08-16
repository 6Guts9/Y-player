import com.android.build.gradle.BaseExtension
import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByType(BaseExtension::class.java)

        if (androidExtension != null) {
            if (androidExtension.namespace == null) {
                androidExtension.namespace = "dev.flutter.plugins.${project.name.replace("-", "_")}"
            }
            androidExtension.compileSdkVersion(36)
            androidExtension.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            androidExtension.compileOptions.targetCompatibility = JavaVersion.VERSION_17
        }

        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(JvmTarget.JVM_17)
            }
        }
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}