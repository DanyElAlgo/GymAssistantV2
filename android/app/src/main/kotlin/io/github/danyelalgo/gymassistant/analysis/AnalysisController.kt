package io.github.danyelalgo.gymassistant.analysis

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.FlutterInjector
import java.io.IOException
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Coordinates the camera, the pose model and the measurements, and emits the channel events
 * (Diseño §4.1). Commands arrive on the main thread.
 *
 * Threads: CameraX hands frames to [analysisExecutor], which also owns the [PoseEstimator];
 * MediaPipe returns poses on its own thread, which also runs the [PoseAnalyzer]; the overlay
 * and the events go out on the main thread. No frame outlives its analysis (ADR-0005).
 */
class AnalysisController(
    private val activity: Activity,
    private val emitter: EventEmitter,
) : DefaultLifecycleObserver {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val analysisExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val estimator = PoseEstimator(activity, ::onPose)
    private val variantSelector = ModelVariantSelector()

    private var view: CameraPreviewView? = null
    @Volatile private var capture: CameraCapture? = null

    // Main thread only. Each start and release begins a new generation, so callbacks from a
    // start that was since released do nothing.
    private var cameraGeneration = 0
    private var requestedVariant: ModelVariant? = null
    private var measuring = false

    private val measurementLock = Any()
    private var monitor: PerformanceMonitor? = null

    // The last rules file read, on the main thread; thresholds come only from it (ADR-0006).
    private var rules: Rules? = null

    // Replaced on the main thread, used on MediaPipe's thread.
    @Volatile private var session: AnalysisSession? = null

    // The session whose set is running, between startSet and stopSet; set on the main thread.
    @Volatile private var activeSet: AnalysisSession? = null

    @Volatile private var analysisSize: Size? = null
    @Volatile private var lastFps: Double? = null

    init {
        (activity as LifecycleOwner).lifecycle.addObserver(this)
    }

    fun attach(view: CameraPreviewView) {
        this.view = view
    }

    /**
     * The camera view went away. Leaving P08 or P09 releases the camera, except while a set is
     * running: P08 starts the set before handing over to P09, whose own view may attach before
     * or after P08's leaves, and P09 releases the camera when it closes.
     */
    fun detach(view: CameraPreviewView) {
        if (this.view !== view) return
        if (activeSet == null) releaseCamera()
        this.view = null
    }

    /**
     * Starts capture into the attached camera view; fails with a channel error code. When the
     * camera is already running, as when P09 takes over from P08, the preview moves into the
     * attached view, and the framing and its measured side carry on; CameraX reconfigures its
     * streams, so a few frames may be skipped.
     */
    fun startCamera(onDone: (errorCode: String?, message: String?) -> Unit) {
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return onDone(CAMERA_PERMISSION, "Camera permission not granted")
        }
        val view = view ?: return onDone(CAMERA_IN_USE, "No camera view is attached")
        capture?.takeIf { it.isRunning }?.let { running ->
            running.showIn(view.previewView)
            return onDone(null, null)
        }
        val generation = ++cameraGeneration
        val providerFuture = ProcessCameraProvider.getInstance(activity)
        providerFuture.addListener({
            // The user left P08, or the app closed, while CameraX was getting ready.
            if (generation != cameraGeneration || this.view !== view) return@addListener onDone(null, null)
            try {
                val capture = capture ?: CameraCapture(providerFuture.get(), analysisExecutor).also { capture = it }
                capture.start(activity as LifecycleOwner, view.previewView, ::onFrame)
                openModel(variantSelector.variant) {
                    // Measure from the moment the model can analyse, so its loading time is not counted.
                    if (generation == cameraGeneration) startMeasuring()
                }
                onDone(null, null)
            } catch (exception: Exception) {
                Log.e(TAG, "Could not start the camera", exception)
                onDone(CAMERA_IN_USE, exception.message)
            }
        }, ContextCompat.getMainExecutor(activity))
    }

    /**
     * Diseño §11.4 `checkFraming`: from now on, analyses each pose for [exerciseCode] with the
     * thresholds of [rulesVersion], and emits `framing` whenever the result changes. Fails with
     * `UNKNOWN_EXERCISE`, or `INVALID_CONFIG` when that rules file is missing or invalid; it is
     * refused, never replaced by other values (ADR-0006).
     */
    fun checkFraming(exerciseCode: String, rulesVersion: String, onDone: (errorCode: String?, message: String?) -> Unit) {
        val config = configFor(exerciseCode, rulesVersion, onDone) ?: return
        activeSet = null
        session = AnalysisSession(config)
        onDone(null, null)
    }

    /**
     * Diseño §11.4 `startSet`: fixes the measured side until [stopSet] (ADR-0012), and keeps the
     * camera running while P09 takes over from P08 (see [detach]). The set goes on with the
     * framing check P08 started when it is for the same exercise and rules, so the side chosen
     * there is the one measured; otherwise it starts its own. Fails like [checkFraming]. F1 has
     * no alerts yet, so silent mode changes nothing.
     */
    fun startSet(exerciseCode: String, rulesVersion: String, onDone: (errorCode: String?, message: String?) -> Unit) {
        val config = configFor(exerciseCode, rulesVersion, onDone) ?: return
        val session = this.session?.takeIf { it.config == config } ?: AnalysisSession(config).also { this.session = it }
        synchronized(session) { session.analyzer.startSet() }
        activeSet = session
        onDone(null, null)
    }

    /**
     * Diseño §11.4 `stopSet`: ends the set and returns its repetition counts, which stay at
     * zero until the repetition state machine arrives in F2. Fails with `NO_ACTIVE_SET`.
     */
    fun stopSet(onDone: (summary: Map<String, Int>?, errorCode: String?, message: String?) -> Unit) {
        val session = activeSet ?: return onDone(null, NO_ACTIVE_SET, "No set is running")
        synchronized(session) { session.analyzer.stopSet() }
        activeSet = null
        onDone(mapOf("total_repetitions" to 0, "correct_repetitions" to 0), null, null)
    }

    fun releaseCamera() {
        cameraGeneration++
        activeSet = null
        session = null
        stopMeasuring()
        measuring = false
        capture?.stop()
        requestedVariant = null
        analysisExecutor.execute { estimator.close() }
        view?.skeleton?.show(null, null, null, null)
        analysisSize = null
    }

    /** Diseño §11.4 `capabilities`: model variant in use, analysis resolution and measured fps. */
    fun capabilities(): Map<String, Any?> = mapOf(
        "model_variant" to estimator.variant?.name,
        "analysis_width" to analysisSize?.width,
        "analysis_height" to analysisSize?.height,
        "fps" to lastFps,
    )

    fun dispose() {
        releaseCamera()
        (activity as LifecycleOwner).lifecycle.removeObserver(this)
        analysisExecutor.shutdown()
    }

    // CameraX stops delivering frames while the activity is stopped; seconds without the camera
    // would read as 0 fps and wrongly push the model to Lite.
    override fun onStop(owner: LifecycleOwner) {
        stopMeasuring()
    }

    override fun onStart(owner: LifecycleOwner) {
        if (measuring) startMeasuring()
    }

    // On analysisExecutor.
    private fun onFrame(frame: Bitmap, capturedAtMs: Long) {
        analysisSize = Size(frame.width, frame.height)
        estimator.process(frame, capturedAtMs)
    }

    // On MediaPipe's thread.
    private fun onPose(capturedAtMs: Long, pose: Pose?) {
        val clock = capture?.clockMs ?: return
        synchronized(measurementLock) { monitor?.recordFrame(capturedAtMs, analyzedAtMs = clock()) }
        val size = analysisSize
        val session = this.session
        val result = session?.let { synchronized(it) { it.analyzer.analyze(pose) } }
        // The primary angle never crosses the channel (ADR-0004): during a set, the camera view
        // draws it beside its joint, in the research build only.
        val angle = if (session != null && session === activeSet) result?.let { primaryAngleOf(session, it) } else null
        mainHandler.post { view?.skeleton?.show(pose, size, capture?.previewSize, angle) }

        if (session == null || result == null) return
        // The angle changes every frame; framing is reported only when it changes.
        val framingResult = result.copy(primaryAngle = null)
        if (framingResult != session.lastResult) {
            session.lastResult = framingResult
            // A session replaced or released meanwhile no longer speaks for P08 or P09.
            mainHandler.post { if (this.session === session) emitter.emitFraming(framingResult) }
        }
    }

    private fun primaryAngleOf(session: AnalysisSession, result: FrameAnalysis): PrimaryAngleReading? {
        val degrees = result.primaryAngle ?: return null
        val side = result.measuredSide ?: return null
        return PrimaryAngleReading(degrees, session.config.exercise.primaryAngle.vertex.landmarkIndex(side))
    }

    /**
     * The configuration of [exerciseCode] in the rules file of [rulesVersion], or null after
     * failing [onDone] with `UNKNOWN_EXERCISE` or `INVALID_CONFIG`. A missing or invalid file is
     * refused, never replaced by other values (ADR-0006).
     */
    private fun configFor(exerciseCode: String, rulesVersion: String, onDone: (errorCode: String?, message: String?) -> Unit): ExerciseConfig? {
        val exercise = Exercise.fromCode(exerciseCode)
        if (exercise == null) {
            onDone(UNKNOWN_EXERCISE, "Unknown exercise $exerciseCode")
            return null
        }
        val rules = try {
            rules?.takeIf { it.version == rulesVersion } ?: loadRules(rulesVersion).also { rules = it }
        } catch (exception: InvalidRulesException) {
            Log.e(TAG, "Invalid rules file for version $rulesVersion", exception)
            onDone(INVALID_CONFIG, exception.message)
            return null
        } catch (exception: IOException) {
            Log.e(TAG, "Could not read the rules file for version $rulesVersion", exception)
            onDone(INVALID_CONFIG, exception.message)
            return null
        }
        return rules.forExercise(exercise)
    }

    /** The shipped rules file of [version], from the Flutter assets. */
    private fun loadRules(version: String): Rules {
        val assetKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/rules/rules_v$version.json")
        val json = activity.assets.open(assetKey).bufferedReader().use { it.readText() }
        return RulesLoader.parse(json, expectedVersion = version)
    }

    /** Loads [variant] on the analysis thread, then runs [onReady] on the main thread. */
    private fun openModel(variant: ModelVariant, onReady: () -> Unit = {}) {
        requestedVariant = variant
        analysisExecutor.execute {
            try {
                estimator.open(variant)
                mainHandler.post(onReady)
            } catch (exception: Exception) {
                Log.e(TAG, "Could not load the $variant pose model", exception)
            }
        }
    }

    private fun startMeasuring() {
        val capture = capture ?: return
        measuring = true
        synchronized(measurementLock) { monitor = PerformanceMonitor(startMs = capture.clockMs()) }
        mainHandler.removeCallbacks(performanceTick)
        mainHandler.postDelayed(performanceTick, SAMPLE_PERIOD_MS)
    }

    private fun stopMeasuring() {
        mainHandler.removeCallbacks(performanceTick)
        synchronized(measurementLock) { monitor = null }
    }

    private val performanceTick = object : Runnable {
        override fun run() {
            val clock = capture?.clockMs ?: return
            val sample = synchronized(measurementLock) { monitor?.sample(clock()) } ?: return
            lastFps = sample.fps
            // The performance log of HU-08: numbers only, never images.
            Log.i(TAG, "performance fps=%.1f latency_ms=%s variant=%s".format(Locale.ROOT, sample.fps, sample.latencyMs, requestedVariant))
            emitter.emitPerformance(sample)
            val variant = variantSelector.onSample(sample.fps)
            if (variant != requestedVariant) {
                Log.i(TAG, "Median fps below ${ModelVariantSelector.MIN_FPS}: switching to $variant")
                openModel(variant)
            }
            mainHandler.postDelayed(this, SAMPLE_PERIOD_MS)
        }
    }

    /**
     * The analysis of one exercise, from the framing check through its sets. The analyzer is
     * locked on the session, since sets start and stop on the main thread; only MediaPipe's
     * thread touches [lastResult].
     */
    private class AnalysisSession(val config: ExerciseConfig) {
        val analyzer = PoseAnalyzer(config)
        var lastResult: FrameAnalysis? = null
    }

    companion object {
        const val CAMERA_PERMISSION = "CAMERA_PERMISSION"
        const val CAMERA_IN_USE = "CAMERA_IN_USE"
        const val UNKNOWN_EXERCISE = "UNKNOWN_EXERCISE"
        const val INVALID_CONFIG = "INVALID_CONFIG"
        const val NO_ACTIVE_SET = "NO_ACTIVE_SET"
        private const val TAG = "AnalysisController"
        private const val SAMPLE_PERIOD_MS = 1_000L
    }
}
