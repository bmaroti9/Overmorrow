package com.marotidev.overmorrow.widgets

// Standard Glance and Compose imports (as we discussed before)

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
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
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

class WindWidget : GlanceAppWidget() {

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
        val windSpeed = prefs.getInt("wind.windSpeed.$appWidgetId", 0)
        val windUnit = prefs.getString("wind.windUnit.$appWidgetId", "N/A") ?: "?"
        val windDirName = prefs.getString("wind.windDirName.$appWidgetId", "0") ?: "?"
        val windDirAngle = prefs.getInt("wind.windDirAngle.$appWidgetId", 0)

        Row(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.secondaryContainer)
                .cornerRadius(100.dp)
                .padding(16.dp),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Text(
                text = "$windSpeed",
                style = TextStyle(
                    color = GlanceTheme.colors.primary,
                    fontSize = 30.sp
                ),
            )
            Text(
                text = windUnit,
                style = TextStyle(
                    color = GlanceTheme.colors.outline,
                    fontSize = 16.sp
                ),
            )
            Text(
                modifier = GlanceModifier.padding(start = 10.dp),
                text = "$windDirAngle°",
                style = TextStyle(
                    color = GlanceTheme.colors.primary,
                    fontSize = 25.sp
                ),
            )
        }

    }
}