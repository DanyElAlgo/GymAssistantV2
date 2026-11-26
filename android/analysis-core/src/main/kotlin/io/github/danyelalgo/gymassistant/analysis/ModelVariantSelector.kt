package io.github.danyelalgo.gymassistant.analysis

/** The MediaPipe Pose Landmarker models the app ships; Heavy is not included (SCRUM-45). */
enum class ModelVariant { LITE, FULL }

/**
 * Chooses the pose model from the measured frame rate (RNF-02).
 *
 * Full is the default. The first [warmUpSamples] one-second samples are ignored while the
 * model loads; after that, samples are grouped into consecutive windows of [windowSize], and
 * if a window's median fps is below [MIN_FPS] the selector switches to Lite for good.
 */
class ModelVariantSelector(
    private val warmUpSamples: Int = 2,
    private val windowSize: Int = 5,
) {
    var variant: ModelVariant = ModelVariant.FULL
        private set

    private var samplesSeen = 0
    private val window = mutableListOf<Double>()

    /** Takes one per-second fps sample and returns the variant to use from now on. */
    fun onSample(fps: Double): ModelVariant {
        samplesSeen++
        if (variant == ModelVariant.LITE || samplesSeen <= warmUpSamples) return variant
        window += fps
        if (window.size == windowSize) {
            if (median(window)!! < MIN_FPS) variant = ModelVariant.LITE
            window.clear()
        }
        return variant
    }

    companion object {
        /** RNF-02: at least 15 frames processed per second during a set. */
        const val MIN_FPS = 15.0
    }
}
