package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ModelVariantSelectorTest {

    private fun ModelVariantSelector.feed(vararg fps: Double): ModelVariant = fps.fold(variant) { _, sample -> onSample(sample) }

    @Test
    fun `starts with the Full model`() {
        assertEquals(ModelVariant.FULL, ModelVariantSelector().variant)
    }

    @Test
    fun `switches to Lite when the median fps of a measurement window is below 15`() {
        val selector = ModelVariantSelector()

        // Warm-up seconds are ignored, then a window of five one-second samples.
        val variant = selector.feed(3.0, 8.0, 14.0, 16.0, 12.0, 14.5, 20.0)

        assertEquals(ModelVariant.LITE, variant)
    }

    @Test
    fun `keeps Full while each window's median reaches 15 fps, even with slow seconds inside`() {
        val selector = ModelVariantSelector()

        val variant = selector.feed(1.0, 2.0, 15.0, 9.0, 18.0, 10.0, 16.0, 22.0, 21.0, 4.0, 15.0, 19.0)

        assertEquals(ModelVariant.FULL, variant)
    }

    @Test
    fun `an incomplete window does not decide`() {
        val selector = ModelVariantSelector()

        assertEquals(ModelVariant.FULL, selector.feed(20.0, 20.0, 5.0, 5.0, 5.0, 5.0))
    }

    @Test
    fun `stays on Lite once it switched`() {
        val selector = ModelVariantSelector()
        selector.feed(0.0, 0.0, 10.0, 10.0, 10.0, 10.0, 10.0)

        assertEquals(ModelVariant.LITE, selector.feed(30.0, 30.0, 30.0, 30.0, 30.0))
    }
}
