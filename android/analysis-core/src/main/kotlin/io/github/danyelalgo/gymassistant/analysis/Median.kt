package io.github.danyelalgo.gymassistant.analysis

/** The median of [values], or null if there are none; an even count gives the mean of the middle two. */
internal fun median(values: Collection<Double>): Double? {
    if (values.isEmpty()) return null
    val sorted = values.sorted()
    val middle = sorted.size / 2
    return if (sorted.size % 2 == 1) sorted[middle] else (sorted[middle - 1] + sorted[middle]) / 2
}
