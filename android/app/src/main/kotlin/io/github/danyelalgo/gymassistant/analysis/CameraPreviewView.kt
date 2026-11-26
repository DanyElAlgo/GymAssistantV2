package io.github.danyelalgo.gymassistant.analysis

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import androidx.camera.view.PreviewView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * PlatformView `gymassistant/camera-view` (Diseño §11.4): the CameraX preview with the
 * skeleton on top. Flutter inserts it in P08 and P09; disposing it releases the camera.
 */
class CameraPreviewView(context: Context, private val controller: AnalysisController) : PlatformView {
    val previewView = PreviewView(context).apply {
        // TextureView-based, so it composes with Flutter's platform view layers.
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        scaleType = PreviewView.ScaleType.FILL_CENTER
    }
    val skeleton = SkeletonOverlayView(context)
    private val root = FrameLayout(context).apply {
        // Training happens away from the phone, so the screen must not time out.
        keepScreenOn = true
        addView(previewView)
        addView(skeleton)
    }

    init {
        controller.attach(this)
    }

    override fun getView(): View = root

    override fun dispose() {
        controller.detach(this)
    }

    class Factory(private val controller: AnalysisController) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView = CameraPreviewView(context, controller)
    }

    companion object {
        const val VIEW_TYPE = "gymassistant/camera-view"
    }
}
