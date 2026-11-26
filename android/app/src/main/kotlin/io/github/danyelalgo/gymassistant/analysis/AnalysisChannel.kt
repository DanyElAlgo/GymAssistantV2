package io.github.danyelalgo.gymassistant.analysis

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The native side of the Flutter ↔ Kotlin contract (Diseño §11.4): MethodChannel
 * `gymassistant/analysis`, EventChannel `gymassistant/analysis/events` and the
 * `gymassistant/camera-view` PlatformView.
 */
class AnalysisChannel private constructor(private val controller: AnalysisController) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startCamera" -> controller.startCamera { errorCode, message ->
                if (errorCode == null) result.success(null) else result.error(errorCode, message, null)
            }
            "releaseCamera" -> {
                controller.releaseCamera()
                result.success(null)
            }
            "checkFraming" -> controller.checkFraming(
                exerciseCode = call.argument<String>("exercise").orEmpty(),
                rulesVersion = call.argument<String>("rulesVersion").orEmpty(),
            ) { errorCode, message ->
                if (errorCode == null) result.success(null) else result.error(errorCode, message, null)
            }
            "capabilities" -> result.success(controller.capabilities())
            // startSet and stopSet arrive with SCRUM-51.
            else -> result.notImplemented()
        }
    }

    companion object {
        /** Wires the channels and the camera view into [engine]; returns the controller to dispose. */
        fun register(engine: FlutterEngine, activity: Activity): AnalysisController {
            val messenger = engine.dartExecutor.binaryMessenger
            val emitter = EventEmitter()
            val controller = AnalysisController(activity, emitter)
            MethodChannel(messenger, "gymassistant/analysis").setMethodCallHandler(AnalysisChannel(controller))
            EventChannel(messenger, "gymassistant/analysis/events").setStreamHandler(emitter)
            engine.platformViewsController.registry
                .registerViewFactory(CameraPreviewView.VIEW_TYPE, CameraPreviewView.Factory(controller))
            return controller
        }
    }
}
