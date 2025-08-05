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

import androidx.glance.ColorFilter
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.layout.Alignment
import androidx.glance.layout.ContentScale
import androidx.glance.layout.size
import com.marotidev.overmorrow.R
import getIconForCondition

class CurrentWidget : GlanceAppWidget() {

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

        val temp = prefs.getInt("current.temp.$appWidgetId", 0)
        val condition = prefs.getString("current.condition.$appWidgetId", "N/A") ?: "?"

        val iconResId = getIconForCondition(condition)

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
                    provider = ImageProvider(R.drawable.shapes_custom_pill_shape),
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
}