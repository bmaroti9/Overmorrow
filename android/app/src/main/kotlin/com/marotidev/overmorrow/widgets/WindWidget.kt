package com.marotidev.overmorrow.widgets

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.widget.RemoteViews
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.toArgb
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
import androidx.glance.appwidget.AndroidRemoteViews
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.wrapContentSize
import androidx.glance.layout.wrapContentWidth
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.marotidev.overmorrow.MainActivity
import com.marotidev.overmorrow.R
import es.antonborri.home_widget.actionStartActivity
import getBackColor
import getFrontColor
import getOnFrontColor


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

        val windSpeed = prefs.getInt("wind.windSpeed.$appWidgetId", 0)
        val windUnit = prefs.getString("wind.windUnit.$appWidgetId", "N/A") ?: "?"
        val windDirAngle = prefs.getInt("wind.windDirAngle.$appWidgetId", 0)

        val location = prefs.getString("widget.location.$appWidgetId", "--") ?: "?"
        val latLon = prefs.getString("widget.latLon.$appWidgetId", "--") ?: "?"

        val backColorString = prefs.getString("widget.backColor.$appWidgetId", "secondary container") ?: "secondary container"
        val frontColorString = prefs.getString("widget.frontColor.$appWidgetId", "primary") ?: "primary"

        val backColor = getBackColor(backColorString)
        val frontColor = getFrontColor(frontColorString)
        val onFrontColor = getOnFrontColor(frontColorString)

        //the bitmaps didn't work either because it was doing too much main thread work
        //i know this is depreciated but i found no other way to rotate a simple icon
        val remoteArrowView = RemoteViews(context.packageName, R.layout.rotated_arrow_layout).apply {
            setImageViewResource(R.id.rotated_arrow, R.drawable.icon_arrow_up)
            setFloat(R.id.rotated_arrow, "setRotation", windDirAngle.toFloat() + 180f)
            setInt(R.id.rotated_arrow, "setColorFilter", onFrontColor.getColor(context).toArgb())
        }

        Row(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .cornerRadius(100.dp).padding(start = 16.dp)
                .clickable(
                    onClick = actionStartActivity<MainActivity>(
                        context,
                        "overmorrrow://opened?location=$location&latlon=$latLon".toUri()
                    )
                ),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {

            //glance doesn't let you set custom line height, and the two texts were ridiculously far from each other
            //so i kind of hacked them closer together by basically having them overlap in a box
            //i have no idea how this will look with different font and screen sizes though, which is a bit concerning
            Box(
                modifier = GlanceModifier.fillMaxHeight().defaultWeight(),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "$windSpeed",
                    style = TextStyle(
                        color = GlanceTheme.colors.onSurface,
                        fontSize = 42.sp,
                    ),
                    modifier = GlanceModifier.padding(bottom = 16.dp),
                )
                Text(
                    text = windUnit,
                    style = TextStyle(
                        color = GlanceTheme.colors.outline,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    modifier = GlanceModifier.padding(top = 46.dp)
                )
            }

            Box(
                modifier = GlanceModifier.padding(start = 4.dp, end = 16.dp, top = 16.dp, bottom = 16.dp).wrapContentSize(),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    provider = ImageProvider(R.drawable.shapes_nine_sided_cookie),
                    contentDescription = null,
                    colorFilter = ColorFilter.tint(frontColor),
                    contentScale = ContentScale.Fit,
                    modifier = GlanceModifier.fillMaxHeight().wrapContentWidth()
                )

                AndroidRemoteViews(remoteArrowView)

            }
        }

    }

}