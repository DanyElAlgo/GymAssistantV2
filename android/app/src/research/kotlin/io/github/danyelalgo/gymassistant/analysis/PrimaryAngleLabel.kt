package io.github.danyelalgo.gymassistant.analysis

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.TypedValue
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Research build only (ADR-0013): the filtered primary angle in whole degrees, drawn beside
 * its joint so the researcher can check that it follows the movement (SCRUM-51). The Play
 * build has a version of this class that draws nothing.
 */
class PrimaryAngleLabel(context: Context) {
    private val metrics = context.resources.displayMetrics
    private val density = metrics.density
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, 18f, metrics)
    }
    private val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(0xB3, 0, 0, 0) }
    private val box = RectF()

    /** Draws [degrees] to the right of [at], the joint's position in the view. */
    fun draw(canvas: Canvas, at: ViewPoint, degrees: Double) {
        val text = String.format(Locale.ROOT, "%d°", degrees.roundToInt())
        val padding = 6 * density
        val left = at.x + 14 * density
        // Centres the text vertically on the joint.
        val baseline = at.y - (textPaint.ascent() + textPaint.descent()) / 2
        box.set(
            left - padding,
            baseline + textPaint.ascent() - padding,
            left + textPaint.measureText(text) + padding,
            baseline + textPaint.descent() + padding,
        )
        canvas.drawRoundRect(box, 6 * density, 6 * density, backgroundPaint)
        canvas.drawText(text, left, baseline, textPaint)
    }
}
