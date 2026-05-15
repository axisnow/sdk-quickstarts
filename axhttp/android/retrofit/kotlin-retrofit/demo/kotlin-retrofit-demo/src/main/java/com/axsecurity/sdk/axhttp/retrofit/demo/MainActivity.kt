package com.axsecurity.sdk.axhttp.retrofit.demo

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.activity.ComponentActivity
import com.axsecurity.sdk.axhttp.retrofit.demo.DemoClientInstance.retrofitInstance
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class MainActivity : ComponentActivity() {
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
        // Make a Retrofit request to get hello text
        val service = retrofitInstance!!.create(DemoApiService::class.java)
        val call = service.hello
        call.enqueue(object : Callback<HelloModel?> {
            override fun onResponse(call: Call<HelloModel?>, response: Response<HelloModel?>) {
                var msg = "Response code = " + response.code()
                msg += "\n Response result ="
                msg += response.body()!!.result
                activity.runOnUiThread(Runnable {
                    textView.setText(msg)
                })
            }

            override fun onFailure(call: Call<HelloModel?>, t: Throwable) {
                val msg = "Request failed: " + t.message
                activity.runOnUiThread(Runnable {
                    textView.setText(msg)
                })
            }
        })
    }


}
