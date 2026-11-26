package io.github.danyelalgo.gymassistant.analysis

/**
 * What the analysis found in one frame.
 *
 * [missingJoints] lists, in the rules file's order, the required joints that are not seen;
 * every required joint when no person was detected. [measuredSide] is known while
 * [framingValid], and throughout a set once chosen. [primaryAngle], in degrees, is the
 * exercise's primary angle on the measured side from filtered coordinates; null while framing
 * is not valid.
 */
data class FrameAnalysis(
    val personDetected: Boolean,
    val framingValid: Boolean,
    val missingJoints: List<Joint>,
    val measuredSide: Side?,
    val primaryAngle: Double?,
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
 * During a set, from [startSet] to [stopSet], the measured side stays fixed (ADR-0012): losing
 * framing keeps it, and framing is valid again in the first frame where that side sees every
 * required joint. A set started before framing is valid fixes the side its window chooses.
 *
 * The primary angle is measured on coordinates smoothed by one 1€ filter per coordinate
 * ([ExerciseConfig.filter]), in normalised image units; the filters start afresh each time
 * framing becomes valid.
 *
 * Not thread-safe: call it from one thread at a time.
 */
class PoseAnalyzer(private val config: ExerciseConfig) {

    private var window: FramingWindow? = null
    private var measuredSide: Side? = null
    private var inSet = false
    private var smoother: AngleSmoother? = null

    /** Fixes the measured side until [stopSet]. */
    fun startSet() {
        inSet = true
    }

    /** Ends the set: the measured side is free again the next time framing is lost. */
    fun stopSet() {
        inSet = false
    }

    /** Analyses the next frame; [pose] is null when no person was detected in it. */
    fun analyze(pose: Pose?): FrameAnalysis {
        if (pose == null) {
            loseFraming()
            return FrameAnalysis(
                personDetected = false,
                framingValid = false,
                missingJoints = config.requiredJoints,
                measuredSide = measuredSide,
                primaryAngle = null,
            )
        }
        val candidates = measuredSide?.let(::listOf) ?: Side.entries
        val missingBySide = candidates.associateWith { side -> missingOn(pose, side) }
        val completeSides = missingBySide.filterValues { it.isEmpty() }.keys
        if (completeSides.isEmpty()) {
            loseFraming()
            val missing = missingBySide.values.minBy { it.size }
            return FrameAnalysis(personDetected = true, framingValid = false, missingJoints = missing, measuredSide = measuredSide, primaryAngle = null)
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
        val side = measuredSide
        val angle = side?.let { (smoother ?: AngleSmoother(it).also { smoother = it }).angle(pose) }
        return FrameAnalysis(personDetected = true, framingValid = side != null, missingJoints = emptyList(), measuredSide = side, primaryAngle = angle)
    }

    /** Analyses [poses] in order, one result per frame. */
    fun analyzeAll(poses: List<Pose?>): List<FrameAnalysis> = poses.map(::analyze)

    private fun loseFraming() {
        window = null
        smoother = null
        if (!inSet) measuredSide = null
    }

    private fun missingOn(pose: Pose, side: Side): List<Joint> =
        config.requiredJoints.filterNot { joint -> isSeen(pose.landmarks[joint.landmarkIndex(side)]) }

    /** Visible enough, and inside the image: the model also places landmarks it cannot see. */
    private fun isSeen(landmark: BodyLandmark): Boolean =
        landmark.visibility >= config.minVisibility && landmark.x in 0f..1f && landmark.y in 0f..1f

    /** The primary angle on [side], from its three landmarks with each coordinate filtered. */
    private inner class AngleSmoother(side: Side) {
        private val landmarks = config.exercise.primaryAngle.let { listOf(it.start, it.vertex, it.end) }
            .map { joint -> SmoothedLandmark(joint.landmarkIndex(side)) }

        fun angle(pose: Pose): Double {
            val (start, vertex, end) = landmarks.map { it.at(pose) }
            return jointAngle(start, vertex, end)
        }
    }

    /** One landmark with a 1€ filter on each normalised coordinate. */
    private inner class SmoothedLandmark(private val index: Int) {
        private val x = OneEuroFilter(config.filter)
        private val y = OneEuroFilter(config.filter)

        /** Its filtered position in [pose], in pixels. */
        fun at(pose: Pose): FramePoint {
            val landmark = pose.landmarks[index]
            return FramePoint(
                x = x.filter(landmark.x.toDouble(), pose.timestampMs) * pose.imageWidth,
                y = y.filter(landmark.y.toDouble(), pose.timestampMs) * pose.imageHeight,
            )
        }
    }

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
