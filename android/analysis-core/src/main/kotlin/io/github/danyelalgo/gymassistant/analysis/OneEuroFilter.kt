package io.github.danyelalgo.gymassistant.analysis

import kotlin.math.PI
import kotlin.math.abs

/**
 * The 1€ filter's parameters (Casiez et al., 2012), from the rules file (ADR-0006): the cutoff
 * frequency at rest, how much it rises with speed, and the cutoff used for the speed itself.
 */
data class OneEuroParameters(val minCutoffHz: Double, val beta: Double, val dCutoffHz: Double)

/**
 * A 1€ filter for one signal (MT 1.4): a low-pass filter whose cutoff rises with the signal's
 * speed, so it removes jitter at rest without lagging behind fast movement.
 */
class OneEuroFilter(private val parameters: OneEuroParameters) {
    private var lastTimestampMs: Long? = null
    private var lastValue = 0.0
    private var lastSpeed = 0.0

    /** Smooths [value], measured at [timestampMs]; timestamps must increase. */
    fun filter(value: Double, timestampMs: Long): Double {
        val previousMs = lastTimestampMs
        if (previousMs == null) {
            lastTimestampMs = timestampMs
            lastValue = value
            return value
        }
        val elapsedS = (timestampMs - previousMs) / 1_000.0
        // A repeated timestamp carries no new information about speed.
        if (elapsedS <= 0) return lastValue
        val speed = smooth((value - lastValue) / elapsedS, lastSpeed, parameters.dCutoffHz, elapsedS)
        val cutoffHz = parameters.minCutoffHz + parameters.beta * abs(speed)
        lastValue = smooth(value, lastValue, cutoffHz, elapsedS)
        lastSpeed = speed
        lastTimestampMs = timestampMs
        return lastValue
    }

    /** Exponential smoothing with the weight of a first-order low-pass filter at [cutoffHz]. */
    private fun smooth(value: Double, previous: Double, cutoffHz: Double, elapsedS: Double): Double {
        val timeConstantS = 1 / (2 * PI * cutoffHz)
        val alpha = 1 / (1 + timeConstantS / elapsedS)
        return previous + alpha * (value - previous)
    }
}
