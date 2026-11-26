package io.github.danyelalgo.gymassistant.analysis

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * MediaPipe Pose Landmarker in live-stream mode. Frames are processed in memory and
 * dropped; nothing is stored (ADR-0005).
 *
 * Not thread-safe: call [open], [process] and [close] from one thread.
 * [onPose] runs on MediaPipe's thread with the frame's capture timestamp and the pose,
 * or null when no person was found.
 */
class PoseEstimator(
    private val context: Context,
    private val onPose: (timestampMs: Long, pose: Pose?) -> Unit,
) {
    private var landmarker: PoseLandmarker? = null

    /** The model loaded now; null while none is. */
    @Volatile
    var variant: ModelVariant? = null
        private set

    /**
     * Loads [variant] on the GPU, which measured faster on the reference phone, or on the CPU
     * if this phone can't create the GPU delegate.
     */
    fun open(variant: ModelVariant) {
        close()
        landmarker = try {
            create(variant, Delegate.GPU)
        } catch (exception: RuntimeException) {
            Log.w(TAG, "GPU delegate unavailable, using the CPU", exception)
            create(variant, Delegate.CPU)
        }
        this.variant = variant
    }

    private fun create(variant: ModelVariant, delegate: Delegate): PoseLandmarker {
        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(
                BaseOptions.builder()
                    .setModelAssetPath(variant.assetName)
                    .setDelegate(delegate)
                    .build(),
            )
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumPoses(1)
            .setResultListener(::onResult)
            .setErrorListener { error -> Log.e(TAG, "Pose estimation failed", error) }
            .build()
        return PoseLandmarker.createFromOptions(context, options)
    }

    /** Sends one upright, unmirrored frame; [timestampMs] must increase from frame to frame. */
    fun process(frame: Bitmap, timestampMs: Long) {
        landmarker?.detectAsync(BitmapImageBuilder(frame).build(), timestampMs)
    }

    fun close() {
        landmarker?.close()
        landmarker = null
        variant = null
    }

    private fun onResult(result: PoseLandmarkerResult, @Suppress("UNUSED_PARAMETER") input: MPImage) {
        val landmarks = result.landmarks().firstOrNull()
        val pose = landmarks?.let {
            Pose(
                landmarks = it.map { landmark ->
                    BodyLandmark(
                        x = landmark.x(),
                        y = landmark.y(),
                        z = landmark.z(),
                        visibility = landmark.visibility().orElse(0f),
                    )
                },
                timestampMs = result.timestampMs(),
            )
        }
        onPose(result.timestampMs(), pose)
    }

    private val ModelVariant.assetName: String
        get() = when (this) {
            ModelVariant.LITE -> "pose_landmarker_lite.task"
            ModelVariant.FULL -> "pose_landmarker_full.task"
        }

    private companion object {
        const val TAG = "PoseEstimator"
    }
}
