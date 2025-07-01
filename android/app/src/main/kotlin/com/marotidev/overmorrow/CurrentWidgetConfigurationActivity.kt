package com.marotidev.overmorrow

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonColors
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import es.antonborri.home_widget.HomeWidgetPlugin
import androidx.core.content.edit
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.lifecycle.lifecycleScope
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import kotlinx.coroutines.launch

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.net.toUri
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

data class FavoriteItem(
    val id: Int,
    val name: String,
    val region: String,
    val country : String,
    val lat: Double,
    val lon: Double,
    val url: String
)

class CurrentWidgetConfigurationActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    private fun exitWithOk() {

        lifecycleScope.launch {

            //Sync changes to android side (the widget itself)

            val glanceAppWidgetManager = GlanceAppWidgetManager(this@CurrentWidgetConfigurationActivity)
            val glanceId = glanceAppWidgetManager.getGlanceIdBy(appWidgetId)

            CurrentWidget().update(this@CurrentWidgetConfigurationActivity, glanceId)

            //Sync changes to the flutter side

            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                applicationContext,
                "overmorrow://update".toUri())
            backgroundIntent.send()

            // Close it
            val resultIntent = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(Activity.RESULT_OK, resultIntent)
            finish()
        }
    }

    private fun saveLocationPref(context: Context, appWidgetId: Int, location: String?, latLon: String?) {
        HomeWidgetPlugin.getData(context).edit {
            putString("current.location.$appWidgetId", location)
            putString("current.latLon.$appWidgetId", latLon)
        }
    }

    private  fun getFavoritePlaces(context: Context): List<FavoriteItem> {

        Log.i("Got here", "got here")

        val data = HomeWidgetPlugin.getData(context)
        val ifnot = "[\"{\\n        \\\"id\\\": 2651922,\\n        \\\"name\\\": \\\"Nashville\\\",\\n        \\\"region\\\": \\\"Tennessee\\\",\\n        \\\"country\\\": \\\"United States of America\\\",\\n        \\\"lat\\\": 36.17,\\n        \\\"lon\\\": -86.78,\\n        \\\"url\\\": \\\"nashville-tennessee-united-states-of-america\\\"\\n    }\"]"
        val item = data.getString("favorites", ifnot) ?: ifnot

        val gson = Gson()
        val favorites : MutableList<FavoriteItem> = mutableListOf()

        val type = object : TypeToken<List<String>>() {}.type
        val stringList: List<String> = gson.fromJson(item, type)

        for (str in stringList) {
            val x = Gson().fromJson(str, FavoriteItem::class.java)
            favorites.add(x)
            Log.d("Favorite added", "${x.name}, ${x.country}")
        }

        return favorites
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        // Set the result to CANCELED in case the user backs out without adding
        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(Activity.RESULT_CANCELED, resultValue)

        val favorites : List<FavoriteItem> = getFavoritePlaces(applicationContext)

        Log.i("Favorite len", favorites.size.toString())

        setContent {
            MaterialTheme {

                Column (
                    modifier = Modifier.fillMaxSize().padding(16.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        "favorites you add in the app appear here",
                        style = TextStyle(
                            fontSize = 13.sp
                        ),
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    favorites.forEach { favorite ->
                        Button(
                            onClick = {
                                saveLocationPref(applicationContext, appWidgetId, favorite.name, "${favorite.lat}, ${favorite.lon}")
                            },
                        ) {
                            Text("${favorite.name}, ${favorite.country}")
                        }
                    }

                    Text(
                        "Hello World",
                        modifier = Modifier.padding(bottom = 16.dp, top = 30.dp)
                    )

                    Button(
                        onClick = {
                            saveLocationPref(applicationContext, appWidgetId, "Oslo", "59.91, 10.75")
                        },
                    ) {
                        Text("Oslo")
                    }
                    Button(
                        onClick = {
                            saveLocationPref(applicationContext, appWidgetId, "New York", "40.73, -73.94")
                        },
                    ) {
                        Text("New York")
                    }
                    Button(
                        onClick = {
                            saveLocationPref(applicationContext, appWidgetId, "Nashville", "36.17, -86.77")
                        },
                    ) {
                        Text("Nashville")
                    }


                    Button(
                        onClick = {
                            exitWithOk()
                        },
                    ) {
                        Text("Place Widget")
                    }
                }
            }
        }
    }
}