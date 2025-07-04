package com.marotidev.overmorrow

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
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

import GlanceText
import androidx.glance.ColorFilter
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.layout.Alignment
import androidx.glance.layout.ContentScale
import androidx.glance.layout.size
import getIconForCondition

class CurrentWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition() // This now refers to the imported class

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            GlanceContent(context, currentState(), appWidgetId)
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState, appWidgetId: Int) {

        val prefs = currentState.preferences

        val temp = prefs.getInt("current.temp.$appWidgetId", 0)
        val condition = prefs.getString("current.condition.$appWidgetId", "N/A") ?: "?"
        val place = prefs.getString("current.place.$appWidgetId", "--") ?: "?"
        val lastUpdated = prefs.getString("current.updatedTime.$appWidgetId", "N/A") ?: "?"
        val widgetHasFaliure = prefs.getString("widgetFailure.$appWidgetId", "unknown") ?: "?"

        val iconResId = getIconForCondition(condition)

        if (false) {
            Box (
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.Center // Align content within the box
            ){
                Box(
                    modifier = GlanceModifier
                        .size(160.dp, 160.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.custom_pill_shape),
                        contentDescription = null,
                        colorFilter = ColorFilter.tint(GlanceTheme.colors.secondaryContainer), // Dynamic surface color
                        contentScale = ContentScale.Fit,
                        modifier = GlanceModifier.fillMaxSize()
                    )

                    Text(
                        text = "$temp°",
                        style = TextStyle(
                            color = GlanceTheme.colors.primary,
                            fontSize = 50.sp
                        ),
                        modifier = GlanceModifier.padding(start = 49.dp, bottom = 49.dp)
                    )

                    Image(
                        provider = ImageProvider(iconResId),
                        contentDescription = "Weather Icon",
                        colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface),
                        modifier = GlanceModifier
                            .size(118.dp, 118.dp)
                            .padding(top = 52.dp, end = 52.dp)
                    )
                }
            }
        }
        else if (true) {
            Box(
                modifier = GlanceModifier.background(GlanceTheme.colors.surface).padding(16.dp).fillMaxSize()
            ) {
                Column() {
                    Row(
                        verticalAlignment = Alignment.Vertical.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.outline_location_on_24),
                            contentDescription = "Location icon",
                            colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface),
                            modifier = GlanceModifier.size(width = 19.dp, height = 19.dp).padding(end = 4.dp)
                        )
                        Text(
                            text = place,
                            style = TextStyle(
                                color = GlanceTheme.colors.onSurface,
                                fontSize = 16.sp
                            )
                        )
                    }
                    Row(
                        verticalAlignment = Alignment.Vertical.CenterVertically
                    ) {
                        Text(
                            text = "$temp°",
                            style = TextStyle(
                                color = GlanceTheme.colors.primary,
                                fontSize = 45.sp
                            ),
                        )
                        Image(
                            provider = ImageProvider(iconResId),
                            contentDescription = "Weather icon",
                            colorFilter = ColorFilter.tint(GlanceTheme.colors.tertiary),
                            modifier = GlanceModifier.size(width = 55.dp, height = 55.dp).padding(start = 2.dp)
                        )
                    }

                    Text(
                        text = condition,
                        style = TextStyle(
                            color = GlanceTheme.colors.onSurface,
                            fontSize = 20.sp
                        )
                    )
                    Text(
                        text = lastUpdated,
                        style = TextStyle(
                            color = GlanceTheme.colors.outline,
                            fontSize = 14.sp
                        )
                    )
                }
            }
        } else {
            Box(modifier = GlanceModifier.background(GlanceTheme.colors.errorContainer).padding(16.dp).fillMaxSize()) {
                Text(
                    text = widgetHasFaliure,
                    style = TextStyle(
                        color = GlanceTheme.colors.onErrorContainer,
                        fontSize = 14.sp
                    )
                )
            }
        }


    }
}