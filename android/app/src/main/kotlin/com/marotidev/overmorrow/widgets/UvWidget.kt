package com.marotidev.overmorrow.widgets

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.widget.RemoteViews
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.min
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.AndroidRemoteViews
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
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
import androidx.glance.layout.size
import androidx.glance.layout.wrapContentSize
import androidx.glance.layout.wrapContentWidth
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.marotidev.overmorrow.MainActivity
import com.marotidev.overmorrow.R
import es.antonborri.home_widget.actionStartActivity
import com.marotidev.overmorrow.services.getBackColor
import com.marotidev.overmorrow.services.getFrontColor
import com.marotidev.overmorrow.services.getOnFrontColor


class UvWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

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

        val uv = prefs.getInt("uv.uv.$appWidgetId", 0)

        val location = prefs.getString("widget.location.$appWidgetId", "--") ?: "?"
        val latLon = prefs.getString("widget.latLon.$appWidgetId", "--") ?: "?"

        val backColorString = prefs.getString("widget.backColor.$appWidgetId", "secondary container") ?: "secondary container"
        val frontColorString = prefs.getString("widget.frontColor.$appWidgetId", "primary") ?: "primary"

        val backColor = getBackColor(backColorString)
        val frontColor = getFrontColor(frontColorString)
        val isFrontTransparent = frontColorString == "transparent"
        val onFrontColor = getOnFrontColor(frontColorString)

        val size = LocalSize.current
        val minSize = min(size.width, size.height).value

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .clickable(
                    onClick = actionStartActivity<MainActivity>(
                        context,
                        "overmorrrow://opened?location=$location&latlon=$latLon".toUri()
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            if (backColorString != "transparent") {
                Image(
                    provider = ImageProvider(R.drawable.shapes_circle),
                    contentDescription = null,
                    colorFilter = ColorFilter.tint(backColor),
                    contentScale = ContentScale.Fit,
                )
            }

            if (!isFrontTransparent) {
                Image(
                    provider = ImageProvider(R.drawable.shapes_soft_boom),
                    contentDescription = null,
                    colorFilter = ColorFilter.tint(frontColor),
                    contentScale = ContentScale.Fit,
                    modifier = GlanceModifier.padding((minSize * 0.1f).dp)
                )
            }

            Text(
                "$uv",
                style = TextStyle(
                    color = onFrontColor,
                    fontSize = (minSize * 0.25f).sp,
                ),
            )

        }

    }

}