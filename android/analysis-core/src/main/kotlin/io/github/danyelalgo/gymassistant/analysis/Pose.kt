package io.github.danyelalgo.gymassistant.analysis

/**
 * One tracked body point in a [Pose]: coordinates normalised to the analysed frame
 * (unmirrored, upright), and the model's confidence that the point is visible.
 */
data class BodyLandmark(val x: Float, val y: Float, val z: Float, val visibility: Float)

/**
 * The 33 landmarks MediaPipe estimates from one frame, in MediaPipe's index order, and the
 * frame's upright size in pixels. Coordinates are normalised to each axis separately, so the
 * size is needed to measure angles.
 */
data class Pose(val landmarks: List<BodyLandmark>, val timestampMs: Long, val imageWidth: Int, val imageHeight: Int)
