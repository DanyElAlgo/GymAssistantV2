package io.github.danyelalgo.gymassistant.analysis

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

/** The analysis domain runs on a plain JVM, with no Android framework on its classpath (ADR-0010). */
class JvmOnlyModuleTest {

    @Test
    fun `android framework is not on the classpath`() {
        assertThrows<ClassNotFoundException> { Class.forName("android.os.Build") }
    }
}
