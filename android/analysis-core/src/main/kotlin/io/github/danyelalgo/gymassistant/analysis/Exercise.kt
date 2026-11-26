package io.github.danyelalgo.gymassistant.analysis

/** One of the three supported machines (Diseño §12.1, `exercise`). */
enum class Exercise(val code: String) {
    LEG_PRESS_45("LEG_PRESS_45"),
    LAT_PULLDOWN("LAT_PULLDOWN"),
    LEG_EXTENSION("LEG_EXTENSION");

    companion object {
        fun fromCode(code: String): Exercise? = entries.firstOrNull { it.code == code }
    }
}
