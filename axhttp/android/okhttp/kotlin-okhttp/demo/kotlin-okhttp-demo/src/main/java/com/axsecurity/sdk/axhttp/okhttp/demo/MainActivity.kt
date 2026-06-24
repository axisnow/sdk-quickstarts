package com.axsecurity.sdk.axhttp.okhttp.demo
import android.app.Activity
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import androidx.activity.ComponentActivity
import com.axsecurity.sdk.axhttp.okhttp.AXHTTPService
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import java.util.concurrent.TimeUnit


class MainActivity : ComponentActivity() {
    // Using your request url here
    private val  url: String = "https://example.com"
    private lateinit var textView: TextView
    private lateinit var apiButton: Button
    private lateinit var activity: Activity

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activity = this
        setContentView(R.layout.activity_main)
        apiButton = findViewById(R.id.run_test_button)
        textView = findViewById(R.id.textView)

        apiButton.setOnClickListener {
            onRequestApi()
        }
    }

    fun onRequestApi() {
        // *** COMMENT THE LINE BELOW FOR SDK ***
        val client = OkHttpClient.Builder().build()

        // *** UNCOMMENT THE LINE BELOW FOR SDK ***
        // val okBuilder = OkHttpClient.Builder()
        // okBuilder.callTimeout(30, TimeUnit.SECONDS)
        // AXHTTPService.setOkHttpClientBuilder(okBuilder)
        // val client = AXHTTPService.getOkHttpClient()


        val builder = Request.Builder().url(url).build()

        client.newCall(builder).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                val msg = "Http response failed: " + e.message
                Log.d(TAG, msg)
                activity.runOnUiThread {
                    textView.setText(msg)
                }
            }
            @Throws(IOException::class)
            override fun onResponse(call: Call, response: Response) {
                val msg = "Http status code " + response.code
                Log.d(TAG, msg)
                activity.runOnUiThread {
                    textView.setText( msg)
                }
            }
        })
    }

    companion object {
        private val TAG = MainActivity::class.java.simpleName
    }
}
