package com.marotidev.overmorrow.configurators

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.Keep
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import com.marotidev.overmorrow.OvermorrowTheme
import com.marotidev.overmorrow.R
import com.marotidev.overmorrow.services.getBackColor
import com.marotidev.overmorrow.services.getFrontColor
import com.marotidev.overmorrow.widgets.CurrentWidget
import com.marotidev.overmorrow.widgets.DateCurrentWidget
import com.marotidev.overmorrow.widgets.ForecastWidget
import com.marotidev.overmorrow.widgets.OneHourlyWidget
import com.marotidev.overmorrow.widgets.WindWidget

//this is to stop proguard from messing up the structure
//https://stackoverflow.com/questions/42282261/gson-not-mapping-data-in-production-mode-apk-android
@Keep
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
                    "com.marotidev.overmorrow.receivers.WindWidgetReceiver" -> WindWidget()
                    "com.marotidev.overmorrow.receivers.ForecastWidgetReceiver" -> ForecastWidget()
                    "com.marotidev.overmorrow.receivers.OneHourlyWidgetReceiver" -> OneHourlyWidget()
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
            setResult(RESULT_OK, resultIntent)
            finish()
        }
    }

    private fun saveLocationPref(context: Context, appWidgetId: Int, location: String?, latLon: String?) {
        HomeWidgetPlugin.getData(context).edit {
            putString("widget.location.$appWidgetId", location)
            if (!latLon.isNullOrBlank()) {
                putString("widget.place.$appWidgetId", location)
                putString("widget.latLon.$appWidgetId", latLon)
            }
        }
    }

    private fun saveProviderPref(context: Context, appWidgetId: Int, provider: String) {
        HomeWidgetPlugin.getData(context).edit {
            putString("widget.provider.$appWidgetId", provider)
        }
    }

    private fun saveBackColorPref(context: Context, appWidgetId: Int, backColor: String) {
        HomeWidgetPlugin.getData(context).edit {
            putString("widget.backColor.$appWidgetId", backColor)
        }
    }

    private fun saveFrontColorPref(context: Context, appWidgetId: Int, frontColor: String) {
        HomeWidgetPlugin.getData(context).edit {
            putString("widget.frontColor.$appWidgetId", frontColor)
        }
    }

    private fun getFavoritePlaces(data: SharedPreferences): List<FavoriteItem> {
        val ifnot = "[\"{\\n        \\\"id\\\": 2651922,\\n        \\\"name\\\": \\\"Nashville\\\",\\n        \\\"region\\\": \\\"Tennessee\\\",\\n        \\\"country\\\": \\\"United States of America\\\",\\n        \\\"lat\\\": 36.17,\\n        \\\"lon\\\": -86.78,\\n        \\\"url\\\": \\\"nashville-tennessee-united-states-of-america\\\"\\n    }\"]"
        val item = data.getString("widget.favorites", ifnot) ?: ifnot
        val gson = Gson()
        val favorites: MutableList<FavoriteItem> = mutableListOf()

        try {
            val type = object : TypeToken<List<String>>() {}.type
            val stringList: List<String> = gson.fromJson(item, type)

            for (str in stringList) {
                try {
                    val x = Gson().fromJson(str, FavoriteItem::class.java)
                    favorites.add(x)
                } catch (e: Exception) {
                    Log.e("WidgetConfig", "Failed to parse single FavoriteItem from string: $str", e)
                }
            }
        } catch (e: Exception) {
            Log.e("WidgetConfig", "Failed to parse 'favorites' as a list of strings.", e)
        }

        return favorites
    }

    private fun getCurrentUsedPlace(data: SharedPreferences, appWidgetId: Int) : String {
        val item = data.getString("widget.location.$appWidgetId", "unknown") ?: "unknown"
        Log.d("Location fetch", item)
        return item
    }

    private fun getLastKnownLocation(data: SharedPreferences) : String {
        val item = data.getString("widget.lastKnownPlace", "unknown") ?: "unknown"
        Log.d("Last known", item)
        return item
    }

    private fun getCurrentUsedProvider(data: SharedPreferences, appWidgetId: Int) : String {
        val item = data.getString("widget.provider.$appWidgetId", "open-meteo") ?: "open-meteo"
        Log.d("Provider fetch", item)
        return item
    }

    private fun getBackgroundColor(data: SharedPreferences, appWidgetId: Int) : String {
        val item = data.getString("widget.backColor.$appWidgetId", "secondary container") ?: "secondary container"
        Log.d("BackgroundColor fetch", item)
        return item
    }

    private fun getForegroundColor(data: SharedPreferences, appWidgetId: Int) : String {
        val item = data.getString("widget.frontColor.$appWidgetId", "primary") ?: "primary"
        Log.d("ForegroundColor fetch", item)
        return item
    }

    @Composable
    fun CurrentLocationUnavailableText(lastKnownLocation : String) {
        val infoText : String = if (lastKnownLocation == "unknown") {
            "you have to enable current location from the app first"
        } else {
            "updates when opening the app"
        }
        Row (
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(top = 12.dp, end = 4.dp, bottom = 16.dp)
        ){
            Icon(
                painter = painterResource(R.drawable.icon_info),
                tint = MaterialTheme.colorScheme.outline,
                contentDescription = "info icon",
                modifier = Modifier.padding(end = 4.dp).size(16.dp)
            )
            Text(
                infoText,
                style = TextStyle(
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.outline
                ),
            )
        }
    }

    fun isColorDark(color: Color): Boolean {
        val luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue)
        return luminance < 0.5
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
        setResult(RESULT_CANCELED, resultValue)

        val data = HomeWidgetPlugin.getData(applicationContext)

        val favorites : List<FavoriteItem> = getFavoritePlaces(data)

        val selectedPlaceOnStartup : String = getCurrentUsedPlace(data, appWidgetId)
        val selectedProviderOnStartup : String = getCurrentUsedProvider(data, appWidgetId)
        val selectedBackgroundOnStartup : String = getBackgroundColor(data, appWidgetId)
        val selectedForegroundOnStartup : String = getForegroundColor(data, appWidgetId)

        val lastKnownLocation : String = getLastKnownLocation(data)

        Log.i("LastKnownLocation", lastKnownLocation)
        Log.i("selectedBackground", selectedBackgroundOnStartup)

        val providers : List<String> = listOf("open-meteo", "weatherapi", "met-norway")
        val backColors : List<String> = listOf("secondary container", "primary container", "tertiary container", "surface", "transparent")
        val frontColors : List<String> = listOf("primary", "secondary", "tertiary", "transparent")

        Log.i("Favorite len", favorites.size.toString())

        setContent {
            OvermorrowTheme {

                val selectedFavorite : MutableState<String?> = remember { mutableStateOf(selectedPlaceOnStartup) }
                val selectedProvider : MutableState<String?> = remember { mutableStateOf(selectedProviderOnStartup) }
                val selectedBackground : MutableState<String?> = remember { mutableStateOf(selectedBackgroundOnStartup) }
                val selectedForeground : MutableState<String?> = remember { mutableStateOf(selectedForegroundOnStartup) }

                Column (
                    modifier = Modifier.fillMaxSize()
                        .background(MaterialTheme.colorScheme.surface)
                        .padding(24.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.Start
                ) {

                    Text(
                        text = "Location",
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.primary
                        ),
                        modifier = Modifier.padding(top = 50.dp, bottom = 8.dp)
                    )

                    Card(
                        onClick = {
                            selectedFavorite.value = "CurrentLocation"
                            saveLocationPref(applicationContext, appWidgetId,  "CurrentLocation", null)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = if ("CurrentLocation" == selectedFavorite.value) MaterialTheme.colorScheme.primaryContainer
                            else MaterialTheme.colorScheme.surfaceContainer
                        ),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Row(
                            Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Spacer(Modifier.width(12.dp))
                            Text(
                                text = "Current Location ($lastKnownLocation)",
                                modifier = Modifier.weight(1f),
                                style = MaterialTheme.typography.bodyLarge
                            )
                            if ("CurrentLocation" == selectedFavorite.value) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }

                    CurrentLocationUnavailableText(lastKnownLocation)

                    favorites.forEach { favorite ->
                        val isSelected = (favorite.name == selectedFavorite.value)
                        Card(
                            onClick = {
                                selectedFavorite.value = favorite.name
                                saveLocationPref(applicationContext, appWidgetId,  favorite.name, "${favorite.lat}, ${favorite.lon}")
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 2.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer
                                else MaterialTheme.colorScheme.surfaceContainer
                            ),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Row(
                                Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Spacer(Modifier.width(12.dp))
                                Text(
                                    text = favorite.name,
                                    modifier = Modifier.weight(1f),
                                    style = MaterialTheme.typography.bodyLarge
                                )
                                if (isSelected) {
                                    Icon(
                                        Icons.Default.Check,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        }
                    }

                    Row (
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 12.dp, end = 4.dp)
                    ){
                        Icon(
                            painter = painterResource(R.drawable.icon_info),
                            tint = MaterialTheme.colorScheme.outline,
                            contentDescription = "info icon",
                            modifier = Modifier.padding(end = 4.dp).size(16.dp)
                        )
                        Text(
                            "favorites you add in the app appear here",
                            style = TextStyle(
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.outline
                            ),
                        )
                    }

                    Text(
                        text = "Weather provider",
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.primary
                        ),
                        modifier = Modifier.padding(top = 32.dp, bottom = 8.dp)
                    )

                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        SingleChoiceSegmentedButtonRow {
                            providers.forEachIndexed { index, provider ->
                                SegmentedButton(
                                    shape = SegmentedButtonDefaults.itemShape(
                                        index = index,
                                        count = providers.size
                                    ),
                                    onClick = {
                                        selectedProvider.value = provider
                                        saveProviderPref(applicationContext, appWidgetId, provider)
                                    },
                                    selected = provider == selectedProvider.value,
                                    label = { Text(provider) },
                                )
                            }
                        }
                    }

                    Text(
                        text = "Background color",
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.primary
                        ),
                        modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                    )

                    Row(
                        Modifier.horizontalScroll(rememberScrollState())
                            .height(IntrinsicSize.Max)
                    ) {
                        backColors.forEach { backColor ->
                            val isSelected = backColor == selectedBackground.value
                            val colorValue = getBackColor(backColor).getColor(context = applicationContext)

                            Column(
                                Modifier
                                    .width(80.dp)
                                    .fillMaxHeight()
                                    .padding(vertical = 8.dp)
                                    .clip(RoundedCornerShape(12.dp))
                                    .selectable(
                                        selected = isSelected,
                                        onClick = {
                                            selectedBackground.value = backColor
                                            saveBackColorPref(applicationContext, appWidgetId, backColor)
                                        },
                                        role = Role.RadioButton
                                    )
                                    .background(
                                        if (isSelected) MaterialTheme.colorScheme.surfaceVariant
                                        else Color.Transparent
                                    ),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Box(
                                    contentAlignment = Alignment.Center, // Centers the Checkmark
                                    modifier = Modifier
                                        .padding(top = 12.dp)
                                        .size(48.dp)
                                        .clip(CircleShape)
                                        .background(colorValue)
                                        .border(
                                            width = 2.dp,
                                            color = if (isSelected) MaterialTheme.colorScheme.primary
                                            else MaterialTheme.colorScheme.outlineVariant,
                                            shape = CircleShape
                                        )
                                ) {
                                    if (backColor == "transparent") {
                                        Icon(
                                            painter = painterResource(R.drawable.icon_block),
                                            tint = MaterialTheme.colorScheme.error,
                                            contentDescription = "transparent",
                                            modifier = Modifier.size(30.dp)
                                        )
                                    } else if (isSelected) {
                                        Icon(
                                            imageVector = Icons.Default.Check,
                                            contentDescription = "Selected",
                                            tint = if (isColorDark(colorValue)) Color.White else Color.Black,
                                            modifier = Modifier.size(24.dp)
                                        )
                                    }
                                }

                                Text(
                                    text = backColor,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.padding(vertical = 8.dp, horizontal = 4.dp),
                                    textAlign = TextAlign.Center
                                )
                            }
                        }
                    }

                    Text(
                        text = "Foreground color",
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.primary
                        ),
                        modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                    )

                    Row(
                        Modifier.horizontalScroll(rememberScrollState())
                            .height(IntrinsicSize.Max)
                    ) {
                        frontColors.forEach { frontColor ->
                            val isSelected = frontColor == selectedForeground.value
                            val colorValue = getFrontColor(frontColor).getColor(context = applicationContext)

                            Column(
                                Modifier
                                    .width(80.dp)
                                    .fillMaxHeight()
                                    .padding(vertical = 8.dp)
                                    .clip(RoundedCornerShape(12.dp))
                                    .selectable(
                                        selected = isSelected,
                                        onClick = {
                                            selectedForeground.value = frontColor
                                            saveFrontColorPref(applicationContext, appWidgetId, frontColor)
                                        },
                                        role = Role.RadioButton
                                    )
                                    .background(
                                        if (isSelected) MaterialTheme.colorScheme.surfaceVariant
                                        else Color.Transparent
                                    ),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Box(
                                    contentAlignment = Alignment.Center,
                                    modifier = Modifier
                                        .padding(top = 12.dp)
                                        .size(48.dp)
                                        .clip(CircleShape)
                                        .then(if(frontColor == "transparent")
                                            Modifier.background(color = Color.Transparent)
                                            else Modifier.background(colorValue))
                                        .border(
                                            width = 2.dp,
                                            color = if (isSelected) MaterialTheme.colorScheme.primary
                                            else MaterialTheme.colorScheme.outlineVariant,
                                            shape = CircleShape
                                        )
                                ) {
                                    if (frontColor == "transparent") {
                                        Icon(
                                            painter = painterResource(R.drawable.icon_block),
                                            tint = MaterialTheme.colorScheme.error,
                                            contentDescription = "transparent",
                                            modifier = Modifier.size(30.dp)
                                        )
                                    } else if (isSelected) {
                                        Icon(
                                            imageVector = Icons.Default.Check,
                                            contentDescription = "Selected",
                                            tint = if (isColorDark(colorValue)) Color.White else Color.Black,
                                            modifier = Modifier.size(24.dp)
                                        )
                                    }
                                }

                                Text(
                                    text = frontColor,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.padding(vertical = 8.dp, horizontal = 4.dp),
                                    textAlign = TextAlign.Center
                                )
                            }
                        }
                    }

                    Button(
                        onClick = {
                            exitWithOk()
                        },
                        modifier = Modifier.align(alignment = Alignment.CenterHorizontally)
                            .padding(top = 40.dp, bottom = 50.dp)
                    ) {
                        Text("Place Widget")
                    }
                }
            }
        }
    }

}