package com.marotidev.overmorrow.widgets

// Standard Glance and Compose imports (as we discussed before)

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
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

        Column (
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.secondaryContainer)
                .padding(start = 16.dp),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {

            Text(
                text = placeName,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 20.sp,
                ),
            )

            Text(
                text = currentCondition,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 20.sp,
                ),
            )

            Text(
                text = "$currentTemp°",
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 20.sp,
                ),
            )

            Row (

            ) {
                tempList.forEachIndexed { index, item ->
                    Text(text = "$item°", modifier = GlanceModifier.padding(horizontal = 10.dp))
                }
            }

            Row (

            ) {
                conditionList.forEachIndexed { index, item ->
                    Text(text = item, modifier = GlanceModifier.padding(horizontal = 10.dp))
                }
            }

            Row (

            ) {
                timeList.forEachIndexed { index, item ->
                    Text(text = item, modifier = GlanceModifier.padding(horizontal = 10.dp))
                }
            }

        }

    }
}