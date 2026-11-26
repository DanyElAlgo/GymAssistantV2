package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertDoesNotThrow
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.io.File

class RulesLoaderTest {

    private val rulesDir = File(System.getProperty("rulesDir"))

    @Test
    fun `every rules file the app ships is valid and declares the version in its name`() {
        val shipped = rulesDir.listFiles { file -> file.name.endsWith(".json") }.orEmpty()
        assertTrue(shipped.isNotEmpty(), "No rules files in $rulesDir")

        for (file in shipped) {
            val version = Regex("""rules_v(.+)\.json""").matchEntire(file.name)?.groupValues?.get(1)
            assertNotNull(version, "${file.name} is not named rules_v<version>.json")
            assertDoesNotThrow({ RulesLoader.parse(file.readText(), expectedVersion = version!!) }, file.name)
        }
    }

    @Test
    fun `the shipped provisional rules file loads with side-less joints, the 2 s framing window and the 1€ filter`() {
        val json = File(rulesDir, "rules_v0.1.0.json").readText()

        val rules = RulesLoader.parse(json, expectedVersion = "0.1.0")

        assertEquals("0.1.0", rules.version)
        assertEquals(
            ExerciseConfig(
                version = "0.1.0",
                exercise = Exercise.LAT_PULLDOWN,
                requiredJoints = listOf(Joint.SHOULDER, Joint.ELBOW, Joint.WRIST),
                minVisibility = 0.5f,
                minValidFramingMs = 2_000,
                // The starting values Casiez et al. (2012) suggest, until F4 calibrates them.
                filter = OneEuroParameters(minCutoffHz = 1.0, beta = 0.0, dCutoffHz = 1.0),
            ),
            rules.forExercise(Exercise.LAT_PULLDOWN),
        )
        assertEquals(listOf(Joint.HIP, Joint.KNEE, Joint.ANKLE), rules.forExercise(Exercise.LEG_PRESS_45).requiredJoints)
        assertEquals(listOf(Joint.HIP, Joint.KNEE, Joint.ANKLE), rules.forExercise(Exercise.LEG_EXTENSION).requiredJoints)
    }

    @Test
    fun `the example the rejection tests alter is itself valid`() {
        RulesLoader.parse(validRules, expectedVersion = "0.1.0")
    }

    @Test
    fun `a file that declares another version than the one asked for is rejected`() {
        assertThrows<InvalidRulesException> { RulesLoader.parse(validRules, expectedVersion = "0.2.0") }
    }

    @Test
    fun `a value left null is rejected, since every version has concrete values`() {
        assertRejected(validRules.replace("\"min_visibility\": 0.5", "\"min_visibility\": null"))
    }

    @Test
    fun `an unknown exercise is rejected`() {
        assertRejected(validRules.replace("\"LEG_EXTENSION\"", "\"BENCH_PRESS\""))
    }

    @Test
    fun `a missing field is rejected`() {
        assertRejected(validRules.replace("\"min_valid_framing_ms\": 2000,", ""))
    }

    @Test
    fun `a joint named with its side, or unknown, is rejected`() {
        assertRejected(validRules.replace("\"wrist\"", "\"left_wrist\""))
    }

    @Test
    fun `a file without one of the three exercises is rejected`() {
        val withoutLegExtension = validRules.substringBefore(",\n    {\n      \"code\": \"LEG_EXTENSION\"") + "\n  ]\n}"

        assertRejected(withoutLegExtension)
    }

    @Test
    fun `a visibility outside 0 to 1 is rejected`() {
        assertRejected(validRules.replace("\"min_visibility\": 0.5", "\"min_visibility\": 1.5"))
    }

    @Test
    fun `a framing duration that is not positive is rejected`() {
        assertRejected(validRules.replace("\"min_valid_framing_ms\": 2000", "\"min_valid_framing_ms\": 0"))
    }

    @Test
    fun `an exercise that appears twice is rejected`() {
        assertRejected(validRules.replace("\"LEG_EXTENSION\"", "\"LEG_PRESS_45\""))
    }

    @Test
    fun `an exercise without required joints is rejected`() {
        assertRejected(validRules.replace("[\"shoulder\", \"elbow\", \"wrist\"]", "[]"))
    }

    @Test
    fun `a file without the 1€ filter parameters is rejected`() {
        assertRejected(validRules.replace(Regex(""""one_euro_filter": \{[^}]*},"""), ""))
    }

    @Test
    fun `a filter parameter left null is rejected`() {
        assertRejected(validRules.replace("\"beta\": 0.0", "\"beta\": null"))
    }

    @Test
    fun `a filter cutoff that is not positive is rejected`() {
        assertRejected(validRules.replace("\"min_cutoff_hz\": 1.0", "\"min_cutoff_hz\": 0"))
        assertRejected(validRules.replace("\"d_cutoff_hz\": 1.0", "\"d_cutoff_hz\": -1"))
    }

    @Test
    fun `a negative filter beta is rejected`() {
        assertRejected(validRules.replace("\"beta\": 0.0", "\"beta\": -0.1"))
    }

    @Test
    fun `text that is not JSON is rejected`() {
        assertRejected("{ \"version\": ")
    }

    private fun assertRejected(json: String) {
        assertThrows<InvalidRulesException> { RulesLoader.parse(json, expectedVersion = "0.1.0") }
    }

    private val validRules = """
        {
          "version": "0.1.0",
          "min_visibility": 0.5,
          "min_valid_framing_ms": 2000,
          "one_euro_filter": {
            "min_cutoff_hz": 1.0,
            "beta": 0.0,
            "d_cutoff_hz": 1.0
          },
          "exercises": [
            {
              "code": "LEG_PRESS_45",
              "required_joints": ["hip", "knee", "ankle"]
            },
            {
              "code": "LAT_PULLDOWN",
              "required_joints": ["shoulder", "elbow", "wrist"]
            },
            {
              "code": "LEG_EXTENSION",
              "required_joints": ["hip", "knee", "ankle"]
            }
          ]
        }
    """.trimIndent()
}
