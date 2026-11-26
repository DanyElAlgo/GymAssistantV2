package io.github.danyelalgo.gymassistant.analysis

// Synthetic poses and configurations shared by the core's tests.

/** A configuration for [exercise] with the provisional values of rules 0.1.0. */
internal fun config(exercise: Exercise) = ExerciseConfig(
    version = "0.1.0",
    exercise = exercise,
    requiredJoints = when (exercise) {
        Exercise.LAT_PULLDOWN -> listOf(Joint.SHOULDER, Joint.ELBOW, Joint.WRIST)
        Exercise.LEG_PRESS_45, Exercise.LEG_EXTENSION -> listOf(Joint.HIP, Joint.KNEE, Joint.ANKLE)
    },
    minVisibility = 0.5f,
    minValidFramingMs = 2_000,
    filter = OneEuroParameters(minCutoffHz = 1.0, beta = 0.0, dCutoffHz = 1.0),
)

/** One pose every 100 ms over [range], made by [poseAt] from its timestamp. */
internal fun everyTenthOfASecond(range: LongRange, poseAt: (Long) -> Pose?): List<Pose?> =
    range.step(100).map(poseAt)

/** The analysed frame, upright: CameraX's 640×480 analysis stream in portrait. */
internal const val FRAME_WIDTH = 480
internal const val FRAME_HEIGHT = 640

/**
 * A pose at [t] ms in which every landmark is inside the image with visibility [left] on the
 * left side and [right] on the right side, except [hidden] ones (visibility 0) and [outside]
 * ones (visible, but beyond the image's right edge).
 *
 * Both sides stand straight: shoulder over elbow over wrist, and hip over knee over ankle, so
 * every primary angle is 180°. [at] moves chosen landmarks to other normalised coordinates.
 */
internal fun pose(
    t: Long,
    left: Float = 0.9f,
    right: Float = 0.9f,
    hidden: Set<Pair<Joint, Side>> = emptySet(),
    outside: Set<Pair<Joint, Side>> = emptySet(),
    at: Map<Joint, Pair<Float, Float>> = emptyMap(),
): Pose {
    val landmarks = MutableList(33) { BodyLandmark(x = 0.5f, y = 0.5f, z = 0f, visibility = 0.9f) }
    for (joint in Joint.entries) {
        for (side in Side.entries) {
            val visibility = when {
                joint to side in hidden -> 0f
                side == Side.LEFT -> left
                else -> right
            }
            val (x, y) = at[joint] ?: (0.5f to STRAIGHT_Y.getValue(joint))
            landmarks[joint.landmarkIndex(side)] =
                BodyLandmark(x = if (joint to side in outside) 1.2f else x, y = y, z = 0f, visibility = visibility)
        }
    }
    return Pose(landmarks, timestampMs = t, imageWidth = FRAME_WIDTH, imageHeight = FRAME_HEIGHT)
}

private val STRAIGHT_Y = mapOf(
    Joint.SHOULDER to 0.25f,
    Joint.ELBOW to 0.4f,
    Joint.WRIST to 0.55f,
    Joint.HIP to 0.5f,
    Joint.KNEE to 0.65f,
    Joint.ANKLE to 0.8f,
)
