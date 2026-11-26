package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class PerformanceMonitorTest {

    @Test
    fun `fps counts the frames analysed in the window`() {
        val monitor = PerformanceMonitor(startMs = 10_000)
        repeat(20) { frame -> monitor.recordFrame(capturedAtMs = 10_000L + frame * 50, analyzedAtMs = 10_040L + frame * 50) }

        val sample = monitor.sample(nowMs = 11_000)

        assertEquals(20.0, sample.fps, 1e-9)
    }

    @Test
    fun `latency is the median from capture to analysis, so one slow frame does not move it`() {
        val monitor = PerformanceMonitor(startMs = 0)
        for ((captured, analyzed) in listOf(0L to 60L, 100L to 170L, 200L to 900L, 300L to 365L)) {
            monitor.recordFrame(capturedAtMs = captured, analyzedAtMs = analyzed)
        }

        // Latencies 60, 70, 700 and 65 ms: the median of an even count is the mean of the middle two.
        assertEquals(68, monitor.sample(nowMs = 1_000).latencyMs)
    }

    @Test
    fun `each sample covers only the frames since the previous one`() {
        val monitor = PerformanceMonitor(startMs = 0)
        repeat(30) { frame -> monitor.recordFrame(capturedAtMs = frame * 33L, analyzedAtMs = frame * 33L + 100) }
        monitor.sample(nowMs = 1_000)
        repeat(10) { frame -> monitor.recordFrame(capturedAtMs = 1_000L + frame * 100, analyzedAtMs = 1_040L + frame * 100) }

        assertEquals(PerformanceSample(fps = 5.0, latencyMs = 40), monitor.sample(nowMs = 3_000))
    }

    @Test
    fun `a window without analysed frames has zero fps and no latency`() {
        val monitor = PerformanceMonitor(startMs = 0)

        assertEquals(PerformanceSample(fps = 0.0, latencyMs = null), monitor.sample(nowMs = 1_000))
    }
}
