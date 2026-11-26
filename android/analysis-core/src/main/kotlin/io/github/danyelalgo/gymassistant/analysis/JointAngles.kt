package io.github.danyelalgo.gymassistant.analysis

import kotlin.math.abs
import kotlin.math.atan2

/** A point in the analysed frame, in pixels. */
internal data class FramePoint(val x: Double, val y: Double)

/**
 * The angle at [vertex] between the segments to [start] and to [end], in degrees from 0 to
 * 180, in the image plane.
 */
internal fun jointAngle(start: FramePoint, vertex: FramePoint, end: FramePoint): Double {
    val ax = start.x - vertex.x
    val ay = start.y - vertex.y
    val bx = end.x - vertex.x
    val by = end.y - vertex.y
    return Math.toDegrees(abs(atan2(ax * by - ay * bx, ax * bx + ay * by)))
}
