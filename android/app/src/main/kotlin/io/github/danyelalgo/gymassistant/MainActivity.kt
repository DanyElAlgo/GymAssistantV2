package io.github.danyelalgo.gymassistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.github.danyelalgo.gymassistant.analysis.AnalysisChannel
import io.github.danyelalgo.gymassistant.analysis.AnalysisController

class MainActivity : FlutterActivity() {
    private var analysis: AnalysisController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        analysis = AnalysisChannel.register(flutterEngine, this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        analysis?.dispose()
        analysis = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
