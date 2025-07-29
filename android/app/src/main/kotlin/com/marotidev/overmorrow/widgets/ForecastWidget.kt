package com.marotidev.overmorrow.widgets

// Standard Glance and Compose imports (as we discussed before)

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.layout.wrapContentHeight
import androidx.glance.layout.wrapContentWidth
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.marotidev.overmorrow.R
import getIconForCondition
import java.lang.reflect.Type

val gson = Gson()
val hourlyTempType: Type = object : TypeToken<List<Int>>() {}.type
val hourlyConditionType = object : TypeToken<List<String>>() {}.type
val hourlyTimeType = object : TypeToken<List<String>>() {}.type

class ForecastWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            GlanceContent(context, currentState(), appWidgetId)
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState, appWidgetId: Int) {

        val prefs = currentState.preferences

        val widgetHasFaliure = prefs.getString("widgetFailure.$appWidgetId", "unknown") ?: "?"
        val currentTemp = prefs.getInt("hourlyForecast.currentTemp.$appWidgetId", 0)
        val currentCondition = prefs.getString("hourlyForecast.currentCondition.$appWidgetId", "N/A") ?: "?"
        val placeName = prefs.getString("hourlyForecast.place.$appWidgetId", "N/A") ?: "?"
        val hourlyTempList = prefs.getString("hourlyForecast.hourlyTemps.$appWidgetId", "{}") ?: "{}"
        val hourlyConditionList = prefs.getString("hourlyForecast.hourlyConditions.$appWidgetId", "{}") ?: "{}"
        val hourlyTimeList = prefs.getString("hourlyForecast.hourlyNames.$appWidgetId", "{}") ?: "{}"

        val tempList: List<Int> = try {
            hourlyTempList.let { gson.fromJson(it, hourlyTempType) } ?: emptyList()
        } catch (e: Exception) {
            e.printStackTrace()
            Log.e("ERRRRRROR", "Failed to decode JSON list for temp $hourlyTempList", e)
            emptyList()
        }

        val conditionList: List<String> = try {
            hourlyConditionList.let { gson.fromJson(it, hourlyConditionType) } ?: emptyList()
        } catch (e: Exception) {
            e.printStackTrace()
            Log.e("ERRRRRROR", "Failed to decode JSON list for condition $hourlyConditionList", e)
            emptyList()
        }

        val timeList: List<String> = try {
            hourlyTimeList.let { gson.fromJson(it, hourlyTimeType) } ?: emptyList()
        } catch (e: Exception) {
            e.printStackTrace()
            Log.e("ERRRRRROR", "Failed to decode JSON list for time $hourlyTimeList", e)
            emptyList()
        }

        val weatherIconList = mutableListOf<Int>()
        for (item in conditionList) {
            weatherIconList.add(getIconForCondition(item))
        }

        Column (
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.secondaryContainer)
                .padding(8.dp),
            verticalAlignment = Alignment.Vertical.Top
        ) {
            Row(
                modifier = GlanceModifier
                    .wrapContentHeight()
                    .padding(start = 8.dp, end = 8.dp, top = 8.dp)
                    .fillMaxWidth(),
                verticalAlignment = Alignment.Vertical.Top
            ) {
                Text(
                    text = "$currentTemp°",
                    style = TextStyle(
                        color = GlanceTheme.colors.primary,
                        fontSize = 32.sp,
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )

                Row(
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                    modifier = GlanceModifier.padding(top = 2.dp, end = 2.dp)
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.icon_location),
                        contentDescription = "Location icon",
                        colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
                        modifier = GlanceModifier.size(18.dp).padding(end = 4.dp)
                    )
                    Text(
                        text = placeName,
                        style = TextStyle(
                            color = GlanceTheme.colors.outline,
                            fontSize = 16.sp
                        )
                    )
                }
            }

            Text(
                text = currentCondition,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 20.sp,
                ),
                modifier = GlanceModifier.padding(bottom = 8.dp, start = 8.dp)
            )

            Row (
                verticalAlignment = Alignment.Vertical.CenterVertically,
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                modifier = GlanceModifier.fillMaxWidth().fillMaxHeight()
            ) {
                timeList.forEachIndexed { index, item ->
                    Column (
                        modifier = GlanceModifier
                            .wrapContentWidth()
                            .padding(horizontal = 4.dp, vertical = 10.dp),
                        horizontalAlignment = Alignment.Horizontal.CenterHorizontally
                    ) {
                        Text(
                            text = "${tempList[index]}°",
                            style = TextStyle(
                                color = GlanceTheme.colors.primary,
                                fontSize = 16.sp,
                            ),
                            modifier = GlanceModifier.padding(bottom = 2.dp)
                        )
                        Image(
                            provider = ImageProvider(weatherIconList[index]),
                            contentDescription = "Weather Icon",
                            colorFilter = ColorFilter.tint(GlanceTheme.colors.secondary),
                            modifier = GlanceModifier
                                .size(28.dp, 28.dp)
                        )
                        Text(
                            text = item,
                            style = TextStyle(
                                color = GlanceTheme.colors.outline,
                                fontSize = 14.sp,
                            ),
                            modifier = GlanceModifier.padding(top = 2.dp)
                        )
                    }

                }
            }

        }

    }
}