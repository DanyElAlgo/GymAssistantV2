package io.github.danyelalgo.gymassistant.analysis

import android.graphics.Bitmap
import android.hardware.camera2.CameraCharacteristics
import android.os.SystemClock
import android.util.Range
import android.util.Size
import android.view.Surface
import androidx.annotation.OptIn
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import java.util.concurrent.Executor

/**
 * CameraX capture from the front camera (ADR-0011): a mirrored 1280×720 preview for the user
 * and 640×480 frames at 30 fps for analysis, keeping only the latest frame.
 *
 * Analysis frames arrive upright and unmirrored on [analysisExecutor], with their capture time
 * in milliseconds on [clockMs], and are never kept after `onFrame` returns (ADR-0005).
 */
class CameraCapture(
    private val cameraProvider: ProcessCameraProvider,
    private val analysisExecutor: Executor,
) {
    /** The clock the camera stamps frames with, in milliseconds; known once started. */
    @Volatile
    var clockMs: () -> Long = SystemClock::uptimeMillis
        private set

    /** The preview stream's size, upright; null until started. */
    var previewSize: Size? = null
        private set

    @OptIn(ExperimentalCamera2Interop::class)
    fun start(owner: LifecycleOwner, previewView: PreviewView, onFrame: (frame: Bitmap, capturedAtMs: Long) -> Unit) {
        // The view may not be on screen yet; P08 is fixed in portrait (SCRUM-45).
        val rotation = previewView.display?.rotation ?: Surface.ROTATION_0
        val preview = Preview.Builder()
            .setResolutionSelector(resolution(PREVIEW_SIZE, AspectRatioStrategy.RATIO_16_9_FALLBACK_AUTO_STRATEGY))
            .setTargetFrameRate(TARGET_FPS)
            .setTargetRotation(rotation)
            .build()
            .also { it.surfaceProvider = previewView.surfaceProvider }
        val analysis = ImageAnalysis.Builder()
            .setResolutionSelector(resolution(ANALYSIS_SIZE, AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .setOutputImageRotationEnabled(true)
            .setTargetRotation(rotation)
            .build()
        analysis.setAnalyzer(analysisExecutor) { image ->
            image.use { onFrame(it.toBitmap(), it.imageInfo.timestamp / 1_000_000) }
        }

        cameraProvider.unbindAll()
        val camera = cameraProvider.bindToLifecycle(owner, CameraSelector.DEFAULT_FRONT_CAMERA, preview, analysis)

        // Frames are stamped with the sensor's clock; latency must be measured on the same one.
        val timestampSource = Camera2CameraInfo.from(camera.cameraInfo)
            .getCameraCharacteristic(CameraCharacteristics.SENSOR_INFO_TIMESTAMP_SOURCE)
        clockMs = if (timestampSource == CameraCharacteristics.SENSOR_INFO_TIMESTAMP_SOURCE_REALTIME) {
            SystemClock::elapsedRealtime
        } else {
            SystemClock::uptimeMillis
        }
        previewSize = preview.resolutionInfo?.let { info ->
            val size = info.resolution
            if (info.rotationDegrees % 180 == 0) size else Size(size.height, size.width)
        }
    }

    fun stop() {
        cameraProvider.unbindAll()
        previewSize = null
    }

    private fun resolution(size: Size, aspectRatio: AspectRatioStrategy) = ResolutionSelector.Builder()
        .setAspectRatioStrategy(aspectRatio)
        .setResolutionStrategy(ResolutionStrategy(size, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER))
        .build()

    private companion object {
        val PREVIEW_SIZE = Size(1280, 720)
        val ANALYSIS_SIZE = Size(640, 480)
        val TARGET_FPS = Range(30, 30)
    }
}
