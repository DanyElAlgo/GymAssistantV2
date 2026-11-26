package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.io.File

class RulesLoaderTest {

    @Test
    fun `the shipped provisional rules file loads with side-less joints and the 2 s framing window`() {
        val json = File(System.getProperty("rulesDir"), "rules_v0.1.0.json").readText()

        val rules = RulesLoader.parse(json)

        assertEquals("0.1.0", rules.version)
        assertEquals(
            ExerciseConfig(
                version = "0.1.0",
                exercise = Exercise.LAT_PULLDOWN,
                requiredJoints = listOf(Joint.SHOULDER, Joint.ELBOW, Joint.WRIST),
                minVisibility = 0.5f,
                minValidFramingMs = 2_000,
            ),
            rules.forExercise(Exercise.LAT_PULLDOWN),
        )
        assertEquals(listOf(Joint.HIP, Joint.KNEE, Joint.ANKLE), rules.forExercise(Exercise.LEG_PRESS_45).requiredJoints)
        assertEquals(listOf(Joint.HIP, Joint.KNEE, Joint.ANKLE), rules.forExercise(Exercise.LEG_EXTENSION).requiredJoints)
    }

    @Test
    fun `the example the rejection tests alter is itself valid`() {
        RulesLoader.parse(validRules)
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
    fun `text that is not JSON is rejected`() {
        assertRejected("{ \"version\": ")
    }

    private fun assertRejected(json: String) {
        assertThrows<InvalidRulesException> { RulesLoader.parse(json) }
    }

    private val validRules = """
        {
          "version": "0.1.0",
          "min_visibility": 0.5,
          "min_valid_framing_ms": 2000,
          "exercises": [
            {
              "code": "LEG_PRESS_45",
              "required_landmarks": ["hip", "knee", "ankle"]
            },
            {
              "code": "LAT_PULLDOWN",
              "required_landmarks": ["shoulder", "elbow", "wrist"]
            },
            {
              "code": "LEG_EXTENSION",
              "required_landmarks": ["hip", "knee", "ankle"]
            }
          ]
        }
    """.trimIndent()
}
