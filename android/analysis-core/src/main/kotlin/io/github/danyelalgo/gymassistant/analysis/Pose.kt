package io.github.danyelalgo.gymassistant.analysis

/**
 * One tracked body point in a [Pose]: coordinates normalised to the analysed frame
 * (unmirrored, upright), and the model's confidence that the point is visible.
 */
data class BodyLandmark(val x: Float, val y: Float, val z: Float, val visibility: Float)

/** The 33 landmarks MediaPipe estimates from one frame, in MediaPipe's index order. */
data class Pose(val landmarks: List<BodyLandmark>, val timestampMs: Long)
