package com.marotidev.overmorrow

// Standard Glance and Compose imports (as we discussed before)
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
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
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

import GlanceText

class CurrentWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*>?
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

        GlanceTheme {
            Box(modifier = GlanceModifier.background(GlanceTheme.colors.surface).padding(16.dp).fillMaxSize()) {
                Column() {
                    Text(
                        text = place,
                        style = TextStyle(
                            color = GlanceTheme.colors.primary,
                            fontSize = 20.sp
                        )
                    )
                    Text(
                        text = lastUpdated,
                    )
                    GlanceText(
                        text = temp.toString(),
                        font = R.font.outfit_regular,
                        fontSize = 50.sp,
                        color = GlanceTheme.colors.primary
                    )
                }
            }
        }

    }
}