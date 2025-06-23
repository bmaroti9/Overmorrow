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
import androidx.glance.layout.Alignment
import androidx.glance.layout.size
import getIconForCondition

class CurrentWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition() // This now refers to the imported class

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent(context, currentState())
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences


        val temp = prefs.getInt("current.temp", 0)
        val condition = prefs.getString("current.condition", "N/A") ?: "?"
        val place = prefs.getString("current.place", "--") ?: "?"
        val lastUpdated = prefs.getString("current.updatedTime", "N/A") ?: "?"

        val iconResId = getIconForCondition(condition)

        Box(modifier = GlanceModifier.background(GlanceTheme.colors.surface).padding(16.dp).fillMaxSize()) {
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
                    GlanceText(
                        text = "$temp°",
                        font = R.font.outfit_light,
                        fontSize = 47.sp,
                        letterSpacing = 0.00.sp,
                        color = GlanceTheme.colors.primary
                    )
                    Image(
                        provider = ImageProvider(iconResId),
                        contentDescription = "Weather icon",
                        colorFilter = ColorFilter.tint(GlanceTheme.colors.tertiary),
                        modifier = GlanceModifier.size(width = 50.dp, height = 50.dp).padding(start = 2.dp)
                    )
                }

                GlanceText(
                    text = condition,
                    font = R.font.outfit_regular,
                    fontSize = 20.sp,
                    letterSpacing = 0.00.sp,
                    color = GlanceTheme.colors.onSurface
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

    }
}