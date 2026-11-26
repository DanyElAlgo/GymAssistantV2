package io.github.danyelalgo.gymassistant.analysis

/**
 * Measures the pose pipeline for RNF-01 and RNF-02, one window at a time.
 *
 * Every analysed frame is recorded with its capture time and the time its pose became
 * available; [sample] closes the current window and starts the next. All times are in
 * milliseconds on one monotonic clock.
 */
class PerformanceMonitor(startMs: Long) {
    private var windowStartMs = startMs
    private val latenciesMs = mutableListOf<Double>()

    fun recordFrame(capturedAtMs: Long, analyzedAtMs: Long) {
        latenciesMs += (analyzedAtMs - capturedAtMs).toDouble()
    }

    /** The window from the previous sample (or the start) until [nowMs]. */
    fun sample(nowMs: Long): PerformanceSample {
        val elapsedMs = nowMs - windowStartMs
        val sample = PerformanceSample(
            fps = latenciesMs.size * 1000.0 / elapsedMs,
            latencyMs = median(latenciesMs)?.let(Math::round)?.toInt(),
        )
        windowStartMs = nowMs
        latenciesMs.clear()
        return sample
    }
}

/**
 * What the pipeline achieved during one window: frames analysed per second and the median
 * capture-to-analysis latency, which is null when no frame was analysed.
 */
data class PerformanceSample(val fps: Double, val latencyMs: Int?)
