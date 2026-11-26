package io.github.danyelalgo.gymassistant.analysis

import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/**
 * What one exercise is analysed with, taken from one rules file (Diseño §8.5, ADR-0006).
 *
 * [requiredJoints] are named without a side (ADR-0012). A landmark counts as seen when its
 * visibility is at least [minVisibility], and framing is valid once every required joint has
 * been seen for [minValidFramingMs] without interruption.
 */
data class ExerciseConfig(
    val version: String,
    val exercise: Exercise,
    val requiredJoints: List<Joint>,
    val minVisibility: Float,
    val minValidFramingMs: Long,
)

/** One rules file: its version and the configuration of every exercise. */
class Rules(val version: String, private val exercises: Map<Exercise, ExerciseConfig>) {
    fun forExercise(exercise: Exercise): ExerciseConfig = exercises.getValue(exercise)
}

/** A rules file the analysis must not use; the channel reports it as `INVALID_CONFIG`. */
class InvalidRulesException(message: String) : Exception(message)

/**
 * Reads and validates a rules file (Diseño §8.5, format of version 0.1.0).
 *
 * Every field is required and none may be `null`, since every version has concrete values
 * (ADR-0006). Each exercise must appear exactly once, and unknown exercises or joints are
 * rejected. Fields the format does not define are ignored.
 */
object RulesLoader {

    fun parse(json: String): Rules {
        val root = try {
            Json.parseToJsonElement(json)
        } catch (exception: SerializationException) {
            throw InvalidRulesException("Not valid JSON: ${exception.message}")
        }.asObject("the rules file")

        val version = root.string("version")
        val minVisibility = root.number("min_visibility")
        if (minVisibility !in 0.0..1.0) throw InvalidRulesException("min_visibility must be between 0 and 1")
        val minValidFramingMs = root.integer("min_valid_framing_ms")
        if (minValidFramingMs <= 0) throw InvalidRulesException("min_valid_framing_ms must be positive")

        val exercises = mutableMapOf<Exercise, ExerciseConfig>()
        for (element in root.array("exercises")) {
            val entry = element.asObject("an exercise")
            val code = entry.string("code")
            val exercise = Exercise.fromCode(code) ?: throw InvalidRulesException("Unknown exercise $code")
            if (exercise in exercises) throw InvalidRulesException("Exercise $code appears twice")
            val joints = entry.array("required_landmarks").map { joint ->
                val name = joint.asString("a required landmark of $code")
                Joint.fromCode(name) ?: throw InvalidRulesException("Unknown joint $name in $code")
            }
            if (joints.isEmpty()) throw InvalidRulesException("$code requires no landmarks")
            exercises[exercise] = ExerciseConfig(
                version = version,
                exercise = exercise,
                requiredJoints = joints,
                minVisibility = minVisibility.toFloat(),
                minValidFramingMs = minValidFramingMs,
            )
        }
        val absent = Exercise.entries - exercises.keys
        if (absent.isNotEmpty()) throw InvalidRulesException("Missing exercises: ${absent.joinToString { it.code }}")
        return Rules(version, exercises)
    }

    private fun JsonObject.field(name: String): JsonElement {
        val value = get(name) ?: throw InvalidRulesException("Missing field $name")
        if (value is JsonNull) throw InvalidRulesException("Field $name is null")
        return value
    }

    private fun JsonObject.string(name: String) = field(name).asString(name)

    private fun JsonObject.number(name: String): Double =
        (field(name) as? JsonPrimitive)?.takeUnless { it.isString }?.doubleOrNull
            ?: throw InvalidRulesException("Field $name must be a number")

    private fun JsonObject.integer(name: String): Long =
        (field(name) as? JsonPrimitive)?.takeUnless { it.isString }?.longOrNull
            ?: throw InvalidRulesException("Field $name must be an integer")

    private fun JsonObject.array(name: String): JsonArray =
        field(name) as? JsonArray ?: throw InvalidRulesException("Field $name must be a list")

    private fun JsonElement.asObject(what: String): JsonObject =
        this as? JsonObject ?: throw InvalidRulesException("Expected an object for $what")

    private fun JsonElement.asString(what: String): String =
        (this as? JsonPrimitive)?.takeIf { it.isString }?.content
            ?: throw InvalidRulesException("Expected text for $what")
}
