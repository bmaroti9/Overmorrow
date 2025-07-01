package com.marotidev.overmorrow

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.selectable
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.edit
import androidx.core.net.toUri
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.lifecycle.lifecycleScope
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.launch

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

    private fun getFavoritePlaces(context: Context): List<FavoriteItem> {

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

    private fun getCurrentUsedPlace(context: Context, appWidgetId: Int) : String {
        val data = HomeWidgetPlugin.getData(context)
        val item = data.getString("current.location.$appWidgetId", "unknown") ?: "unknown"
        Log.d("Location fetch", item)
        return item
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

        val selectedPlaceOnStartup : String = getCurrentUsedPlace(applicationContext, appWidgetId)

        Log.i("Favorite len", favorites.size.toString())

        setContent {
            OvermorrowTheme {

                val selectedFavorite : MutableState<String?> = remember { mutableStateOf(selectedPlaceOnStartup) }

                Column (
                    modifier = Modifier.fillMaxSize().padding(16.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.Start
                ) {
                    favorites.forEach { favorite ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .height(46.dp)
                                .selectable(
                                    selected = (favorite.name == selectedFavorite.value),
                                    onClick = {
                                        selectedFavorite.value = favorite.name
                                        saveLocationPref(applicationContext, appWidgetId,  favorite.name, "${favorite.lat}, ${favorite.lon}")
                                    },
                                    role = Role.RadioButton
                                )
                                .padding(horizontal = 16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = (favorite.name == selectedFavorite.value),
                                onClick = null // null recommended for accessibility with screen readers
                            )
                            Text(
                                text = favorite.name,
                                style = TextStyle(
                                    fontSize = 18.sp
                                ),
                                modifier = Modifier.padding(start = 16.dp)
                            )
                        }
                    }

                    Row (
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 16.dp, bottom = 24.dp)
                    ){
                        Icon(
                            painter = painterResource(R.drawable.baseline_info_outline_24),
                            contentDescription = "info icon",
                            modifier = Modifier.padding(start = 16.dp, end = 8.dp).size(18.dp)
                        )
                        Text(
                            "favorites you add in the app appear here",
                            style = TextStyle(
                                fontSize = 13.sp
                            ),
                        )
                    }

                    Button(
                        onClick = {
                            exitWithOk()
                        },
                        modifier = Modifier.align(alignment = Alignment.CenterHorizontally)
                    ) {
                        Text("Place Widget")
                    }
                }
            }
        }
    }
}