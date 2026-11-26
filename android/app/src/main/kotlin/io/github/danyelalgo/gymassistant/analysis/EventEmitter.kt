package io.github.danyelalgo.gymassistant.analysis

import io.flutter.plugin.common.EventChannel

/**
 * Sends analysis events over EventChannel `gymassistant/analysis/events` (Diseño §11.4).
 * Every event is a map with a `type` and its emission time `t`, in wall-clock milliseconds so
 * Dart can add the delivery latency on the same clock. Events carry data, never images
 * (ADR-0005). Call from the main thread; events are dropped while Flutter isn't listening.
 */
class EventEmitter : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    /** `performance`, once per second: fps and the median capture-to-analysis latency. */
    fun emitPerformance(sample: PerformanceSample) {
        emit("performance", mapOf("fps" to sample.fps, "latency_ms" to sample.latencyMs))
    }

    /**
     * `framing`, when the result changes: whether a person is seen, whether framing is valid,
     * the missing joints by name, without side (ADR-0012), and the measured side once valid.
     */
    fun emitFraming(result: FrameAnalysis) {
        emit(
            "framing",
            mapOf(
                "person_detected" to result.personDetected,
                "is_valid" to result.framingValid,
                "missing_landmarks" to result.missingJoints.map { it.code },
                "measured_side" to result.measuredSide?.code,
            ),
        )
    }

    private fun emit(type: String, fields: Map<String, Any?>) {
        sink?.success(mapOf("type" to type, "t" to System.currentTimeMillis()) + fields)
    }
}
