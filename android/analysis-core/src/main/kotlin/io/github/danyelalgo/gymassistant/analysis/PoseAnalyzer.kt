package io.github.danyelalgo.gymassistant.analysis

/**
 * What the analysis found in one frame.
 *
 * [missingJoints] lists, in the rules file's order, the required joints that are not seen;
 * every required joint when no person was detected. [measuredSide] is known only while
 * [framingValid].
 */
data class FrameAnalysis(
    val personDetected: Boolean,
    val framingValid: Boolean,
    val missingJoints: List<Joint>,
    val measuredSide: Side?,
)

/**
 * The analysis core's entry point: takes one exercise's configuration and its poses in
 * capture order, and analyses each frame.
 *
 * Framing (HU-10, ADR-0012): a required joint is seen on a side when its landmark there is
 * visible enough and inside the image. Framing becomes valid once one side has seen every
 * required joint for [ExerciseConfig.minValidFramingMs] without interruption; at that moment,
 * among the sides that did, the one with the higher mean visibility of its required landmarks
 * over that window becomes the measured side (the left one on a tie). From then on only the
 * measured side counts; a frame in which it misses a joint, or without a person, ends the
 * framing and the side, and the next window starts from scratch.
 *
 * Not thread-safe: feed it from one thread.
 */
class PoseAnalyzer(private val config: ExerciseConfig) {

    private var window: FramingWindow? = null
    private var measuredSide: Side? = null

    /** Analyses the next frame; [pose] is null when no person was detected in it. */
    fun analyze(pose: Pose?): FrameAnalysis {
        if (pose == null) {
            loseFraming()
            return FrameAnalysis(personDetected = false, framingValid = false, missingJoints = config.requiredJoints, measuredSide = null)
        }
        val candidates = measuredSide?.let(::listOf) ?: Side.entries
        val missingBySide = candidates.associateWith { side -> missingOn(pose, side) }
        val completeSides = missingBySide.filterValues { it.isEmpty() }.keys
        if (completeSides.isEmpty()) {
            loseFraming()
            val missing = missingBySide.values.minBy { it.size }
            return FrameAnalysis(personDetected = true, framingValid = false, missingJoints = missing, measuredSide = null)
        }

        if (measuredSide == null) {
            // A window only goes on while some side has seen everything in every one of its frames.
            val window = window?.takeIf { it.keepOnly(completeSides) }
                ?: FramingWindow(startMs = pose.timestampMs, sides = completeSides).also { window = it }
            window.add(pose)
            if (pose.timestampMs - window.startMs >= config.minValidFramingMs) {
                measuredSide = window.clearestSide()
                this.window = null
            }
        }
        return FrameAnalysis(personDetected = true, framingValid = measuredSide != null, missingJoints = emptyList(), measuredSide = measuredSide)
    }

    /** Analyses [poses] in order, one result per frame. */
    fun analyzeAll(poses: List<Pose?>): List<FrameAnalysis> = poses.map(::analyze)

    private fun loseFraming() {
        window = null
        measuredSide = null
    }

    private fun missingOn(pose: Pose, side: Side): List<Joint> =
        config.requiredJoints.filterNot { joint -> isSeen(pose.landmarks[joint.landmarkIndex(side)]) }

    /** Visible enough, and inside the image: the model also places landmarks it cannot see. */
    private fun isSeen(landmark: BodyLandmark): Boolean =
        landmark.visibility >= config.minVisibility && landmark.x in 0f..1f && landmark.y in 0f..1f

    /**
     * A framing window in progress: the sides that have seen every required joint in all its
     * frames so far, and their visibility sums.
     */
    private inner class FramingWindow(val startMs: Long, sides: Set<Side>) {
        private val sides = sides.toMutableSet()
        private val visibilitySums = DoubleArray(Side.entries.size)

        /** Drops the sides not in [complete]; false when none is left, which ends the window. */
        fun keepOnly(complete: Set<Side>): Boolean {
            sides.retainAll(complete)
            return sides.isNotEmpty()
        }

        fun add(pose: Pose) {
            for (side in sides) {
                visibilitySums[side.ordinal] += config.requiredJoints.sumOf { joint ->
                    pose.landmarks[joint.landmarkIndex(side)].visibility.toDouble()
                }
            }
        }

        // Every remaining side has the same number of frames and joints, so the higher sum is the higher mean.
        fun clearestSide(): Side = Side.entries.filter { it in sides }.maxBy { visibilitySums[it.ordinal] }
    }
}
