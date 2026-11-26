package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/** The core's entry point over synthetic poses, for the lat pulldown (shoulder, elbow, wrist). */
class PoseAnalyzerTest {

    private val config = ExerciseConfig(
        version = "0.1.0",
        exercise = Exercise.LAT_PULLDOWN,
        requiredJoints = listOf(Joint.SHOULDER, Joint.ELBOW, Joint.WRIST),
        minVisibility = 0.5f,
        minValidFramingMs = 2_000,
    )

    @Test
    fun `a frame without a person reports no person and every required joint as missing`() {
        val result = PoseAnalyzer(config).analyze(null)

        assertEquals(
            FrameAnalysis(
                personDetected = false,
                framingValid = false,
                missingJoints = listOf(Joint.SHOULDER, Joint.ELBOW, Joint.WRIST),
                measuredSide = null,
            ),
            result,
        )
    }

    @Test
    fun `a required joint seen on neither side is named as missing, and framing is not valid`() {
        val result = PoseAnalyzer(config).analyze(pose(t = 0, hidden = setOf(Joint.WRIST to Side.LEFT, Joint.WRIST to Side.RIGHT)))

        assertEquals(
            FrameAnalysis(personDetected = true, framingValid = false, missingJoints = listOf(Joint.WRIST), measuredSide = null),
            result,
        )
    }

    @Test
    fun `a landmark outside the image is not seen, however visible the model thinks it is`() {
        val elbowsOut = pose(t = 0, outside = setOf(Joint.ELBOW to Side.LEFT, Joint.ELBOW to Side.RIGHT))

        assertEquals(listOf(Joint.ELBOW), PoseAnalyzer(config).analyze(elbowsOut).missingJoints)
    }

    @Test
    fun `missing joints are those of the side that sees more of them`() {
        // The left side lacks only the wrist; the right side lacks the elbow and the wrist.
        val pose = pose(
            t = 0,
            hidden = setOf(Joint.WRIST to Side.LEFT, Joint.ELBOW to Side.RIGHT, Joint.WRIST to Side.RIGHT),
        )

        assertEquals(listOf(Joint.WRIST), PoseAnalyzer(config).analyze(pose).missingJoints)
    }

    @Test
    fun `framing becomes valid once every required joint has been seen for 2 s in a row`() {
        val results = PoseAnalyzer(config).analyzeAll(everyTenthOfASecond(0L..2_000L) { t -> pose(t) })

        assertEquals(List(20) { false } + true, results.map { it.framingValid })
        assertEquals(emptyList<Joint>(), results.first().missingJoints)
    }

    @Test
    fun `a frame with a joint missing interrupts the window, which starts again`() {
        val poses = everyTenthOfASecond(0L..4_000L) { t ->
            if (t == 1_500L) pose(t, hidden = setOf(Joint.ELBOW to Side.LEFT, Joint.ELBOW to Side.RIGHT)) else pose(t)
        }

        val validFrom = PoseAnalyzer(config).analyzeAll(poses).zip(poses).first { (result, _) -> result.framingValid }.second

        assertEquals(3_600L, validFrom!!.timestampMs)
    }

    @Test
    fun `losing the person interrupts the window too`() {
        val poses = everyTenthOfASecond(0L..4_000L) { t -> if (t == 1_000L) null else pose(t) }

        val results = PoseAnalyzer(config).analyzeAll(poses)

        // The window starts again at 1 100 ms, so it completes at 3 100 ms.
        assertEquals(false, results[20].framingValid)
        assertEquals(31, results.indexOfFirst { it.framingValid })
    }

    @Test
    fun `framing stops being valid as soon as a joint goes missing`() {
        val poses = everyTenthOfASecond(0L..2_000L) { t -> pose(t) } +
            pose(2_100, hidden = setOf(Joint.WRIST to Side.LEFT, Joint.WRIST to Side.RIGHT))

        val last = PoseAnalyzer(config).analyzeAll(poses).last()

        assertEquals(FrameAnalysis(personDetected = true, framingValid = false, missingJoints = listOf(Joint.WRIST), measuredSide = null), last)
    }

    @Test
    fun `when framing becomes valid, the side seen with the higher mean visibility over the window is measured`() {
        // The right side starts clearer and the left one ends clearer; over the window, the right wins.
        val poses = everyTenthOfASecond(0L..2_000L) { t ->
            if (t <= 1_000L) pose(t, left = 0.6f, right = 0.95f) else pose(t, left = 0.8f, right = 0.7f)
        }

        val results = PoseAnalyzer(config).analyzeAll(poses)

        assertEquals(List(20) { null } + Side.RIGHT, results.map { it.measuredSide })
    }

    @Test
    fun `a side that sees every required joint is enough, and becomes the measured side`() {
        val rightArmHidden = setOf(Joint.SHOULDER to Side.RIGHT, Joint.ELBOW to Side.RIGHT, Joint.WRIST to Side.RIGHT)

        val last = PoseAnalyzer(config).analyzeAll(everyTenthOfASecond(0L..2_000L) { t -> pose(t, hidden = rightArmHidden) }).last()

        assertEquals(FrameAnalysis(personDetected = true, framingValid = true, missingJoints = emptyList(), measuredSide = Side.LEFT), last)
    }

    @Test
    fun `the measured side stays while framing is valid, even if the other side becomes clearer`() {
        val poses = everyTenthOfASecond(0L..2_000L) { t -> pose(t, left = 0.6f, right = 0.9f) } +
            everyTenthOfASecond(2_100L..4_000L) { t -> pose(t, left = 0.95f, right = 0.7f) }

        val results = PoseAnalyzer(config).analyzeAll(poses)

        assertEquals(setOf(Side.RIGHT), results.drop(20).map { it.measuredSide }.toSet())
    }

    @Test
    fun `once measured, framing is judged on the measured side alone`() {
        val poses = everyTenthOfASecond(0L..2_000L) { t -> pose(t, left = 0.6f, right = 0.9f) } +
            pose(2_100, hidden = setOf(Joint.WRIST to Side.RIGHT))

        val last = PoseAnalyzer(config).analyzeAll(poses).last()

        assertEquals(FrameAnalysis(personDetected = true, framingValid = false, missingJoints = listOf(Joint.WRIST), measuredSide = null), last)
    }

    @Test
    fun `after framing is lost, the side is chosen again when the next window completes`() {
        val poses = everyTenthOfASecond(0L..2_000L) { t -> pose(t, left = 0.6f, right = 0.9f) } +
            pose(2_100, hidden = setOf(Joint.WRIST to Side.RIGHT)) +
            everyTenthOfASecond(2_200L..4_200L) { t -> pose(t, left = 0.9f, right = 0.6f) }

        val last = PoseAnalyzer(config).analyzeAll(poses).last()

        assertEquals(Side.LEFT, last.measuredSide)
    }

    @Test
    fun `a side that misses a joint cannot be measured, however visible its other joints are`() {
        // The right side's shoulder and elbow are clearer, but it never sees the wrist.
        val poses = everyTenthOfASecond(0L..2_100L) { t -> pose(t, left = 0.55f, right = 0.95f, hidden = setOf(Joint.WRIST to Side.RIGHT)) }

        val results = PoseAnalyzer(config).analyzeAll(poses)

        assertEquals(listOf(Side.LEFT, Side.LEFT), results.takeLast(2).map { it.measuredSide })
    }

    @Test
    fun `when no side has seen every joint for the whole window, the window starts again`() {
        // Until 1 000 ms only the left side sees everything; from then on only the right side does.
        val poses = everyTenthOfASecond(0L..3_000L) { t ->
            if (t < 1_000L) pose(t, hidden = setOf(Joint.WRIST to Side.RIGHT)) else pose(t, hidden = setOf(Joint.WRIST to Side.LEFT))
        }

        val results = PoseAnalyzer(config).analyzeAll(poses)

        assertEquals(30, results.indexOfFirst { it.framingValid })
        assertEquals(Side.RIGHT, results.last().measuredSide)
    }

    /** One pose every 100 ms over [range], made by [poseAt] from its timestamp. */
    private fun everyTenthOfASecond(range: LongRange, poseAt: (Long) -> Pose?): List<Pose?> =
        range.step(100).map(poseAt)
}

/**
 * A pose at [t] ms in which every landmark is inside the image with visibility [left] on the
 * left side and [right] on the right side, except [hidden] ones (visibility 0) and [outside]
 * ones (visible, but beyond the image's right edge).
 */
internal fun pose(
    t: Long,
    left: Float = 0.9f,
    right: Float = 0.9f,
    hidden: Set<Pair<Joint, Side>> = emptySet(),
    outside: Set<Pair<Joint, Side>> = emptySet(),
): Pose {
    val landmarks = MutableList(33) { BodyLandmark(x = 0.5f, y = 0.5f, z = 0f, visibility = 0.9f) }
    for (joint in Joint.entries) {
        for (side in Side.entries) {
            val visibility = when {
                joint to side in hidden -> 0f
                side == Side.LEFT -> left
                else -> right
            }
            val x = if (joint to side in outside) 1.2f else 0.5f
            landmarks[joint.landmarkIndex(side)] = BodyLandmark(x = x, y = 0.5f, z = 0f, visibility = visibility)
        }
    }
    return Pose(landmarks, timestampMs = t)
}
