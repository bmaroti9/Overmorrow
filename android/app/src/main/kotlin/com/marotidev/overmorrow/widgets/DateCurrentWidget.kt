package com.marotidev.overmorrow.widgets

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.Text

import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.cornerRadius
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.size
import androidx.glance.layout.wrapContentSize
import androidx.glance.layout.wrapContentWidth
import androidx.glance.text.TextStyle
import com.marotidev.overmorrow.MainActivity
import com.marotidev.overmorrow.R
import es.antonborri.home_widget.actionStartActivity
import getBackColor
import getFrontColor
import getIconForCondition
import getOnFrontColor

class DateCurrentWidget : GlanceAppWidget() {

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
        val place = prefs.getString("widget.place.$appWidgetId", "--") ?: "?"
        val dateString = prefs.getString("current.date.$appWidgetId", "N/A") ?: "?"

        val location = prefs.getString("widget.location.$appWidgetId", "--") ?: "?"
        val latLon = prefs.getString("widget.latLon.$appWidgetId", "--") ?: "?"

        val backColorString = prefs.getString("widget.backColor.$appWidgetId", "secondary container") ?: "secondary container"
        val frontColorString = prefs.getString("widget.frontColor.$appWidgetId", "primary") ?: "primary"

        val backColor = getBackColor(backColorString)
        val frontColor = getFrontColor(frontColorString)
        val onFrontColor = getOnFrontColor(frontColorString)

        val iconResId = getIconForCondition(condition)

        Row(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .cornerRadius(100.dp)
                .padding(16.dp)
                .clickable(
                    onClick = actionStartActivity<MainActivity>(
                        context,
                        "overmorrrow://opened?location=$location&latlon=$latLon".toUri()
                    )
                ),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Box(
                modifier = GlanceModifier.padding(start = 2.dp).wrapContentSize(),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    provider = ImageProvider(R.drawable.shapes_four_sided_cookie),
                    contentDescription = null,
                    colorFilter = ColorFilter.tint(frontColor),
                    contentScale = ContentScale.Fit,
                    modifier = GlanceModifier.fillMaxHeight().wrapContentWidth()
                )

                Image(
                    provider = ImageProvider(iconResId),
                    contentDescription = "Weather icon",
                    colorFilter = ColorFilter.tint(onFrontColor),
                    modifier = GlanceModifier.size(width = 40.dp, height = 40.dp)
                )
            }

            Column (
                modifier = GlanceModifier.defaultWeight().padding(start = 16.dp)
            ){
                Text(
                    text = place,
                    style = TextStyle(fontSize = 22.sp, color = GlanceTheme.colors.onSurface),
                    maxLines = 1
                )
                Text(
                    text = dateString,
                    style = TextStyle(fontSize = 16.sp, color = GlanceTheme.colors.outline),
                )
            }

            Text(
                text = "$temp°",
                style = TextStyle(fontSize = 40.sp, color = frontColor),
            )

        }

    }
}