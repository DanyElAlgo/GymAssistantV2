package io.github.danyelalgo.gymassistant.analysis

/**
 * One of the three supported machines (Diseño §12.1, `exercise`), with the joint angle that
 * governs its movement (Diseño §4.1).
 */
enum class Exercise(val code: String, val primaryAngle: JointAngle) {
    LEG_PRESS_45("LEG_PRESS_45", JointAngle(Joint.HIP, Joint.KNEE, Joint.ANKLE)),
    LAT_PULLDOWN("LAT_PULLDOWN", JointAngle(Joint.SHOULDER, Joint.ELBOW, Joint.WRIST)),
    LEG_EXTENSION("LEG_EXTENSION", JointAngle(Joint.HIP, Joint.KNEE, Joint.ANKLE));

    companion object {
        fun fromCode(code: String): Exercise? = entries.firstOrNull { it.code == code }
    }
}

/** The angle at [vertex] between the segments to [start] and to [end], on the measured side. */
data class JointAngle(val start: Joint, val vertex: Joint, val end: Joint)
