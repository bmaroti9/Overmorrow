package com.marotidev.overmorrow.configurators

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
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
import androidx.compose.material3.MaterialTheme
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import com.marotidev.overmorrow.OvermorrowTheme
import com.marotidev.overmorrow.R
import com.marotidev.overmorrow.widgets.CurrentWidget
import com.marotidev.overmorrow.widgets.DateCurrentWidget

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
            val appWidgetManager = AppWidgetManager.getInstance(this@CurrentWidgetConfigurationActivity)

            val appWidgetInfo: AppWidgetProviderInfo? = appWidgetManager.getAppWidgetInfo(appWidgetId)

            if (appWidgetInfo != null) {
                val providerClassName = appWidgetInfo.provider.className

                val glanceAppWidget: GlanceAppWidget? = when (providerClassName) {
                    "com.marotidev.overmorrow.receivers.CurrentWidgetReceiver" -> CurrentWidget()
                    "com.marotidev.overmorrow.receivers.DateCurrentWidgetReceiver" -> DateCurrentWidget()
                    else -> {
                        Log.w("WidgetConfig", "Unknown widget provider: $providerClassName for appWidgetId: $appWidgetId")
                        null
                    }
                }

                if (glanceAppWidget != null) {
                    val glanceId: GlanceId = glanceAppWidgetManager.getGlanceIdBy(appWidgetId)

                    glanceAppWidget.update(this@CurrentWidgetConfigurationActivity, glanceId)
                    Log.d("WidgetConfig", "Successfully updated widget type: ${glanceAppWidget.javaClass.simpleName} for ID: $appWidgetId")

                } else {
                    Log.e("WidgetConfig", "Could not find a matching GlanceAppWidget for provider: $providerClassName")
                }

            } else {
                Log.e("WidgetConfig", "Could not retrieve AppWidgetInfo for appWidgetId: $appWidgetId")
            }

            //Sync changes to the flutter side

            Log.i("Got Here", "got here")

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
            if (!latLon.isNullOrBlank()) {
                putString("current.place.$appWidgetId", location)
                putString("current.latLon.$appWidgetId", latLon)
            }
        }
    }

    private fun saveProviderPref(context: Context, appWidgetId: Int, provider: String) {
        HomeWidgetPlugin.getData(context).edit {
            putString("current.provider.$appWidgetId", provider)
        }
    }

    private fun getFavoritePlaces(data: SharedPreferences): List<FavoriteItem> {

        Log.i("Got here", "got here")

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

    private fun getCurrentUsedPlace(data: SharedPreferences, appWidgetId: Int) : String {
        val item = data.getString("current.location.$appWidgetId", "unknown") ?: "unknown"
        Log.d("Location fetch", item)
        return item
    }

    private fun getCurrentUsedProvider(data: SharedPreferences, appWidgetId: Int) : String {
        val item = data.getString("current.provider.$appWidgetId", "open-meteo") ?: "open-meteo"
        Log.d("Provider fetch", item)
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

        val data = HomeWidgetPlugin.getData(applicationContext)

        val favorites : List<FavoriteItem> = getFavoritePlaces(data)
        val selectedPlaceOnStartup : String = getCurrentUsedPlace(data, appWidgetId)
        val selectedProviderOnStartup : String = getCurrentUsedProvider(data, appWidgetId)

        val providers : List<String> = listOf("open-meteo", "weatherapi", "met-norway")

        Log.i("Favorite len", favorites.size.toString())

        setContent {
            OvermorrowTheme {

                val selectedFavorite : MutableState<String?> = remember { mutableStateOf(selectedPlaceOnStartup) }
                val selectedProvider : MutableState<String?> = remember { mutableStateOf(selectedProviderOnStartup) }

                Column (
                    modifier = Modifier.fillMaxSize().padding(16.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.Start
                ) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .height(46.dp)
                            .selectable(
                                selected = ("currentLocation" == selectedFavorite.value),
                                onClick = {
                                    selectedFavorite.value = "currentLocation"
                                    saveLocationPref(applicationContext, appWidgetId,  "currentLocation", null)
                                },
                                role = Role.RadioButton
                            )
                            .padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = ("currentLocation" == selectedFavorite.value),
                            onClick = null // null recommended for accessibility with screen readers
                        )
                        Text(
                            text = "Current Location",
                            style = TextStyle(
                                fontSize = 18.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            ),
                            modifier = Modifier.padding(start = 16.dp)
                        )
                    }

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
                                    fontSize = 18.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                ),
                                modifier = Modifier.padding(start = 16.dp)
                            )
                        }
                    }

                    Row (
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 16.dp, bottom = 40.dp)
                    ){
                        Icon(
                            painter = painterResource(R.drawable.icon_info),
                            tint = MaterialTheme.colorScheme.onSurface,
                            contentDescription = "info icon",
                            modifier = Modifier.padding(start = 16.dp, end = 8.dp).size(18.dp)
                        )
                        Text(
                            "favorites you add in the app appear here",
                            style = TextStyle(
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            ),
                        )
                    }

                    providers.forEach { provider ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .height(46.dp)
                                .selectable(
                                    selected = (provider == selectedProvider.value),
                                    onClick = {
                                        selectedProvider.value = provider
                                        saveProviderPref(applicationContext, appWidgetId, provider)
                                    },
                                    role = Role.RadioButton
                                )
                                .padding(horizontal = 16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = (provider == selectedProvider.value),
                                onClick = null // null recommended for accessibility with screen readers
                            )
                            Text(
                                text = provider,
                                style = TextStyle(
                                    fontSize = 18.sp,
                                    color = MaterialTheme.colorScheme.onSurface
                                ),
                                modifier = Modifier.padding(start = 16.dp)
                            )
                        }
                    }

                    Button(
                        onClick = {
                            exitWithOk()
                        },
                        modifier = Modifier.align(alignment = Alignment.CenterHorizontally)
                            .padding(top = 40.dp)
                    ) {
                        Text("Place Widget")
                    }
                }
            }
        }
    }
}