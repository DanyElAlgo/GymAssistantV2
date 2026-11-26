package io.github.danyelalgo.gymassistant.analysis

/** A side of the body, from the user's point of view, as MediaPipe names it. */
enum class Side(val code: String) {
    LEFT("left"),
    RIGHT("right"),
}

/**
 * A body joint named without its side (ADR-0012): the rules file and the `framing` event
 * name joints this way, and the measured side picks which of its two landmarks is used.
 * [code] is the name in the rules file and the channel.
 */
enum class Joint(val code: String, private val leftIndex: Int, private val rightIndex: Int) {
    SHOULDER("shoulder", 11, 12),
    ELBOW("elbow", 13, 14),
    WRIST("wrist", 15, 16),
    HIP("hip", 23, 24),
    KNEE("knee", 25, 26),
    ANKLE("ankle", 27, 28);

    /** This joint's landmark on [side], as an index into [Pose.landmarks]. */
    fun landmarkIndex(side: Side): Int = when (side) {
        Side.LEFT -> leftIndex
        Side.RIGHT -> rightIndex
    }

    companion object {
        fun fromCode(code: String): Joint? = entries.firstOrNull { it.code == code }
    }
}
