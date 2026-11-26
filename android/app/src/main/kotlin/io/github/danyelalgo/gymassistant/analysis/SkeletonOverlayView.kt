package io.github.danyelalgo.gymassistant.analysis

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.Size
import android.view.View
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker

/**
 * Draws the latest pose over the mirrored camera preview, mirrored so it lines up with the
 * user's image (ADR-0011). Each segment fades with its landmarks' visibility; no visibility
 * threshold is applied here, since thresholds belong in the rules file (ADR-0006).
 */
class SkeletonOverlayView(context: Context) : View(context) {
    private var pose: Pose? = null
    private var analysisSize: Size? = null
    private var previewSize: Size? = null

    private val density = resources.displayMetrics.density
    private val bonePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        strokeWidth = 4 * density
        strokeCap = Paint.Cap.ROUND
    }
    private val landmarkPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    /** Call on the main thread; a null [pose] clears the skeleton. */
    fun show(pose: Pose?, analysisSize: Size?, previewSize: Size?) {
        this.pose = pose
        this.analysisSize = analysisSize
        this.previewSize = previewSize
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val landmarks = pose?.landmarks ?: return
        val analysis = analysisSize ?: return
        val preview = previewSize ?: return
        val projection = PreviewProjection(
            analysisWidth = analysis.width,
            analysisHeight = analysis.height,
            previewWidth = preview.width,
            previewHeight = preview.height,
            viewWidth = width.toFloat(),
            viewHeight = height.toFloat(),
        )
        val points = landmarks.map { projection.project(it.x, it.y) }

        for (connection in PoseLandmarker.POSE_LANDMARKS) {
            val start = connection.start()
            val end = connection.end()
            bonePaint.alpha = alphaOf(minOf(landmarks[start].visibility, landmarks[end].visibility))
            canvas.drawLine(points[start].x, points[start].y, points[end].x, points[end].y, bonePaint)
        }
        for ((landmark, point) in landmarks.zip(points)) {
            landmarkPaint.color = LANDMARK_COLOR
            landmarkPaint.alpha = alphaOf(landmark.visibility)
            canvas.drawCircle(point.x, point.y, 5 * density, landmarkPaint)
        }
    }

    private fun alphaOf(visibility: Float) = (visibility.coerceIn(0f, 1f) * 255).toInt()

    private companion object {
        val LANDMARK_COLOR = Color.rgb(0x26, 0xA6, 0x9A)
    }
}
