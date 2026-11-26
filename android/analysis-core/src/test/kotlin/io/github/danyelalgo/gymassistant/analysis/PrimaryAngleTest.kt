package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The filtered primary angle the core's entry point reports per frame, over synthetic poses.
 * Framing becomes valid at 2 000 ms, so each test holds its pose from 0 ms.
 *
 * Distances are planned in pixels of the 480×640 frame: 96 px is 0.2 of its width and 0.15
 * of its height.
 */
class PrimaryAngleTest {

    @Test
    fun `the lat pulldown is measured at the elbow, between shoulder and wrist`() {
        // The forearm points sideways from the elbow, the upper arm straight up.
        val rightAngle = mapOf(Joint.WRIST to (0.7f to 0.4f))

        assertEquals(90.0, angleOnceFramed(Exercise.LAT_PULLDOWN, rightAngle), TOLERANCE)
        assertEquals(180.0, angleOnceFramed(Exercise.LAT_PULLDOWN, emptyMap()), TOLERANCE)
    }

    @Test
    fun `the leg press and the leg extension are measured at the knee, between hip and ankle`() {
        val rightAngle = mapOf(Joint.ANKLE to (0.7f to 0.65f))

        assertEquals(90.0, angleOnceFramed(Exercise.LEG_PRESS_45, rightAngle), TOLERANCE)
        assertEquals(90.0, angleOnceFramed(Exercise.LEG_EXTENSION, rightAngle), TOLERANCE)
        assertEquals(180.0, angleOnceFramed(Exercise.LEG_EXTENSION, emptyMap()), TOLERANCE)
    }

    @Test
    fun `angles are measured in image pixels, not in coordinates normalised to each axis`() {
        // The wrist is 96 px right of and 96 px above the elbow: 45° from the upper arm. In
        // normalised coordinates (0.2 across, 0.15 up) it would read as 53°.
        val diagonal = mapOf(Joint.WRIST to (0.7f to 0.25f))

        assertEquals(45.0, angleOnceFramed(Exercise.LAT_PULLDOWN, diagonal), TOLERANCE)
    }

    @Test
    fun `there is no angle until framing is valid`() {
        val results = PoseAnalyzer(config(Exercise.LAT_PULLDOWN)).analyzeAll(everyTenthOfASecond(0L..2_000L) { t -> pose(t) })

        assertEquals(List(20) { null }, results.dropLast(1).map { it.primaryAngle })
        assertEquals(180.0, results.last().primaryAngle!!, TOLERANCE)
    }

    @Test
    fun `a still pose keeps its angle through the filter`() {
        val still = mapOf(Joint.WRIST to (0.7f to 0.4f))

        val angles = PoseAnalyzer(config(Exercise.LAT_PULLDOWN))
            .analyzeAll(everyTenthOfASecond(0L..5_000L) { t -> pose(t, at = still) })
            .mapNotNull { it.primaryAngle }

        assertEquals(31, angles.size)
        angles.forEach { assertEquals(90.0, it, TOLERANCE) }
    }

    @Test
    fun `a sudden change of pose is smoothed, and the angle converges to the new one`() {
        // Straight arm until 2 000 ms, then the forearm jumps sideways.
        val poses = everyTenthOfASecond(0L..2_000L) { t -> pose(t) } +
            everyTenthOfASecond(2_100L..3_500L) { t -> pose(t, at = mapOf(Joint.WRIST to (0.7f to 0.4f))) }

        val angles = PoseAnalyzer(config(Exercise.LAT_PULLDOWN)).analyzeAll(poses).drop(20).map { it.primaryAngle!! }

        assertEquals(180.0, angles.first(), TOLERANCE)
        val afterJump = angles[1]
        assertTrue(afterJump > 100.0 && afterJump < 170.0, "The first frame after the jump reads $afterJump°")
        assertTrue(angles.zipWithNext().all { (before, after) -> after <= before + 1e-9 }, "The angle goes back: $angles")
        assertEquals(90.0, angles.last(), 0.5)
    }

    private fun angleOnceFramed(exercise: Exercise, at: Map<Joint, Pair<Float, Float>>): Double =
        PoseAnalyzer(config(exercise)).analyzeAll(everyTenthOfASecond(0L..2_000L) { t -> pose(t, at = at) }).last().primaryAngle!!

    private companion object {
        const val TOLERANCE = 1e-3
    }
}
