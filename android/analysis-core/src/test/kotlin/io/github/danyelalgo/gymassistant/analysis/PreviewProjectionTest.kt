package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class PreviewProjectionTest {

    private fun assertPoint(expectedX: Float, expectedY: Float, actual: ViewPoint) {
        assertEquals(expectedX, actual.x, 1e-3f, "x")
        assertEquals(expectedY, actual.y, 1e-3f, "y")
    }

    @Test
    fun `mirrors the unmirrored analysis frame to match the front camera preview`() {
        // Same aspect ratio everywhere, so nothing is cropped.
        val projection = PreviewProjection(
            analysisWidth = 480, analysisHeight = 640,
            previewWidth = 720, previewHeight = 960,
            viewWidth = 300f, viewHeight = 400f,
        )

        // A landmark on the left of the analysed frame appears on the right of the mirror.
        assertPoint(225f, 40f, projection.project(x = 0.25f, y = 0.1f))
        assertPoint(150f, 200f, projection.project(x = 0.5f, y = 0.5f))
    }

    @Test
    fun `the 16 by 9 preview shows only the middle of the 4 by 3 analysed frame`() {
        // Portrait: the 3:4 analysis frame is the full sensor; the 9:16 preview keeps its middle 75 % of the width.
        val projection = PreviewProjection(
            analysisWidth = 480, analysisHeight = 640,
            previewWidth = 720, previewHeight = 1280,
            viewWidth = 900f, viewHeight = 1600f,
        )

        assertPoint(900f, 800f, projection.project(x = 0.125f, y = 0.5f))
        assertPoint(0f, 1600f, projection.project(x = 0.875f, y = 1f))
        assertPoint(600f, 400f, projection.project(x = 0.375f, y = 0.25f))
    }

    @Test
    fun `a preview wider than the analysed frame keeps the middle of its height`() {
        val projection = PreviewProjection(
            analysisWidth = 480, analysisHeight = 640,
            previewWidth = 640, previewHeight = 640,
            viewWidth = 100f, viewHeight = 100f,
        )

        // The square preview spans analysis y from 1/8 to 7/8.
        assertPoint(50f, 0f, projection.project(x = 0.5f, y = 0.125f))
        assertPoint(100f, 50f, projection.project(x = 0f, y = 0.5f))
    }

    @Test
    fun `the preview fills the view and its overflow is cropped evenly, like PreviewView FILL_CENTER`() {
        // A 9:16 preview on a 1080 x 2400 screen is scaled to 1350 x 2400 and loses 135 px on each side.
        val projection = PreviewProjection(
            analysisWidth = 720, analysisHeight = 1280,
            previewWidth = 720, previewHeight = 1280,
            viewWidth = 1080f, viewHeight = 2400f,
        )

        assertPoint(540f, 1200f, projection.project(x = 0.5f, y = 0.5f))
        assertPoint(945f, 600f, projection.project(x = 0.2f, y = 0.25f))
    }
}
