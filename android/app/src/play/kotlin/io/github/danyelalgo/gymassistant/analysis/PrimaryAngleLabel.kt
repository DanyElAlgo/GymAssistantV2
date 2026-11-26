package io.github.danyelalgo.gymassistant.analysis

import android.content.Context
import android.graphics.Canvas

/**
 * The Play build shows no angle (SCRUM-51). The label exists only in the research build
 * (ADR-0013), so this version draws nothing.
 */
@Suppress("UNUSED_PARAMETER")
class PrimaryAngleLabel(context: Context) {
    fun draw(canvas: Canvas, at: ViewPoint, degrees: Double) = Unit
}
