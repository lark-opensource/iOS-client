package tt.lark.imagemagick

import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.larksuite.tool.image.JPEGTool

class MainActivity : AppCompatActivity() {
    companion object {
        const val TAG: String = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Example of a call to a native method
        var bytes = resources.openRawResource(R.raw.quality_80).readBytes()
        Log.i(TAG, "is jpeg: " + JPEGTool.isJPEG(bytes))
        Log.i(TAG, "jpeg quality : " + JPEGTool.getJpegQuality(bytes))
    }
}
