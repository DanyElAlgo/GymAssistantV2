package io.github.danyelalgo.gymassistant.analysis

/** A point in the camera view, in pixels from its top-left corner. */
data class ViewPoint(val x: Float, val y: Float)

/**
 * Places landmarks from the analysed frame on the camera preview the user sees (ADR-0011).
 *
 * Analysis runs on unmirrored frames, while the front camera preview is mirrored, so the
 * horizontal axis is flipped. Sizes are in upright (portrait-rotated) pixels.
 *
 * The analysis stream (4:3) is taken to cover the whole sensor and the preview stream
 * (16:9) its centred crop, which is how the camera serves streams of different aspect
 * ratios. The preview then fills the view and its overflow is cropped evenly, as
 * PreviewView's FILL_CENTER does.
 */
class PreviewProjection(
    analysisWidth: Int,
    analysisHeight: Int,
    previewWidth: Int,
    previewHeight: Int,
    viewWidth: Float,
    viewHeight: Float,
) {
    // The preview's share of the analysed frame on each axis.
    private val previewSpanX: Float
    private val previewSpanY: Float

    // The preview, scaled to fill the view, in view pixels; it may overflow the view.
    private val shownWidth: Float
    private val shownHeight: Float
    private val offsetX: Float
    private val offsetY: Float

    init {
        val analysisAspect = analysisWidth.toFloat() / analysisHeight
        val previewAspect = previewWidth.toFloat() / previewHeight
        previewSpanX = minOf(1f, previewAspect / analysisAspect)
        previewSpanY = minOf(1f, analysisAspect / previewAspect)

        val scale = maxOf(viewWidth / previewWidth, viewHeight / previewHeight)
        shownWidth = previewWidth * scale
        shownHeight = previewHeight * scale
        offsetX = (viewWidth - shownWidth) / 2
        offsetY = (viewHeight - shownHeight) / 2
    }

    /** Maps a landmark's normalised coordinates in the analysed frame to the view. */
    fun project(x: Float, y: Float): ViewPoint {
        val previewX = (x - (1 - previewSpanX) / 2) / previewSpanX
        val previewY = (y - (1 - previewSpanY) / 2) / previewSpanY
        val mirroredX = 1 - previewX
        return ViewPoint(offsetX + mirroredX * shownWidth, offsetY + previewY * shownHeight)
    }
}
