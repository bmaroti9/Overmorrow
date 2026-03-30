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
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.wrapContentHeight
import androidx.glance.layout.wrapContentWidth
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.marotidev.overmorrow.MainActivity
import com.marotidev.overmorrow.R
import com.marotidev.overmorrow.services.getBackColor
import com.marotidev.overmorrow.services.getFrontColor
import com.marotidev.overmorrow.services.getIconForCondition
import com.marotidev.overmorrow.services.getOnFrontColor
import es.antonborri.home_widget.actionStartActivity
import java.lang.reflect.Type

private val dfGson = Gson()
private val dfIntListType: Type    = object : TypeToken<List<Int>>() {}.type
private val dfStringListType: Type = object : TypeToken<List<String>>() {}.type

private const val DF_COL_WIDTH_DP = 52f
private const val DF_LEFT_W_DP    = 130f

// Approximate row heights (dp) for content tier thresholds
private const val DF_HEADER_H     = 92f
private const val DF_TODAY_H      = 60f
private const val DF_TOMORROW_H   = 50f
private const val DF_EXTRA_ROW_H  = 46f
private const val DF_QUOTE_H      = 28f

/**
 * DailyForecastWidget — weekly weather forecast.
 *
 * Wide layout (width >= 250dp) content tiers by height:
 *   ~110dp : Header only (today big icon + low/high, city + up to 6 day columns)
 *   ~165dp : + TODAY card    (frontColor bg — max prominence)
 *   ~220dp : + TOMORROW row  (frontColor container bg — medium prominence)
 *   ~248dp : + Quote         (appears early, at bottom)
 *   ~275dp : + Day+2 row     (subtle left accent bar, muted bg)
 *   ~321dp : + Day+3 row     (plain)
 *   ~367dp : + Day+4 row     (plain)
 *
 * Visual hierarchy (fading emphasis):
 *   TODAY    → frontColor solid card (e.g. primary)       ── highest contrast
 *   TOMORROW → frontColorContainer card (e.g. primaryContainer) ── medium
 *   Day+2    → surface-variant bg with accent left bar    ── low
 *   Day+3/4  → plain row, no background                  ── minimal
 *
 * Compact (width < 250dp): left column (icon+temp+city) + right day columns.
 */
class DailyForecastWidget : GlanceAppWidget() {

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
    private fun GlanceContent(
        context: Context,
        currentState: HomeWidgetGlanceState,
        appWidgetId: Int
    ) {
        val prefs = currentState.preferences

        val placeName     = prefs.getString("widget.place.$appWidgetId",                "—")  ?: "—"
        val location      = prefs.getString("widget.location.$appWidgetId",             "--") ?: "?"
        val latLon        = prefs.getString("widget.latLon.$appWidgetId",               "--") ?: "?"
        val backColorStr  = prefs.getString("widget.backColor.$appWidgetId", "secondary container") ?: "secondary container"
        val frontColorStr = prefs.getString("widget.frontColor.$appWidgetId", "primary") ?: "primary"
        val displayQuote  = prefs.getString("widget.quote.$appWidgetId",                "")   ?: ""

        val highsRaw  = prefs.getString("dailyForecast.dailyHighTemps.$appWidgetId",   "[]") ?: "[]"
        val lowsRaw   = prefs.getString("dailyForecast.dailyLowTemps.$appWidgetId",    "[]") ?: "[]"
        val condsRaw  = prefs.getString("dailyForecast.dailyConditions.$appWidgetId",  "[]") ?: "[]"
        val namesRaw  = prefs.getString("dailyForecast.dailyNames.$appWidgetId",       "[]") ?: "[]"
        val precipRaw = prefs.getString("dailyForecast.dailyPrecipProbs.$appWidgetId", "[]") ?: "[]"

        val dailyHighs:  List<Int>    = try { dfGson.fromJson(highsRaw,  dfIntListType)    ?: emptyList() } catch (e: Exception) { emptyList() }
        val dailyLows:   List<Int>    = try { dfGson.fromJson(lowsRaw,   dfIntListType)    ?: emptyList() } catch (e: Exception) { emptyList() }
        val dailyConds:  List<String> = try { dfGson.fromJson(condsRaw,  dfStringListType) ?: emptyList() } catch (e: Exception) { emptyList() }
        val dailyNames:  List<String> = try { dfGson.fromJson(namesRaw,  dfStringListType) ?: emptyList() } catch (e: Exception) { emptyList() }
        val dailyPrecip: List<Int>    = try { dfGson.fromJson(precipRaw, dfIntListType)    ?: emptyList() } catch (e: Exception) { emptyList() }

        val backColor    = getBackColor(backColorStr)
        val frontColor   = getFrontColor(frontColorStr)
        val onFrontColor = getOnFrontColor(frontColorStr)

        // Container color = softer version of frontColor for TOMORROW card
        val frontContainerColor = when (frontColorStr) {
            "primary"   -> GlanceTheme.colors.primaryContainer
            "secondary" -> GlanceTheme.colors.secondaryContainer
            "tertiary"  -> GlanceTheme.colors.tertiaryContainer
            else        -> GlanceTheme.colors.primaryContainer
        }
        val onFrontContainerColor = when (frontColorStr) {
            "primary"   -> GlanceTheme.colors.onPrimaryContainer
            "secondary" -> GlanceTheme.colors.onSecondaryContainer
            "tertiary"  -> GlanceTheme.colors.onTertiaryContainer
            else        -> GlanceTheme.colors.onPrimaryContainer
        }

        val size   = LocalSize.current
        val isWide = size.width >= 250.dp

        // Column count for header right side
        val rightPx      = (size.width.value - DF_LEFT_W_DP).coerceAtLeast(0f)
        val colCount     = (rightPx / DF_COL_WIDTH_DP).toInt().coerceIn(1, 6)
        val maxUpcoming  = (dailyNames.size - 1).coerceAtLeast(0)
        val upcomingCols = colCount.coerceAtMost(maxUpcoming)

        // ── Height tiers: calculate what rows fit ──
        var remaining = size.height.value - DF_HEADER_H

        val showToday = remaining >= DF_TODAY_H
        if (showToday) remaining -= DF_TODAY_H

        val showTomorrow = remaining >= DF_TOMORROW_H && dailyNames.size > 1
        if (showTomorrow) remaining -= DF_TOMORROW_H

        // Quote appears as early as possible — right after Today/Tomorrow
        val showQuote = displayQuote.isNotEmpty() && remaining >= DF_QUOTE_H
        if (showQuote) remaining -= DF_QUOTE_H

        // Extra plain rows up to Day+4 (index 2..4), max 3
        val extraDayCount = when {
            remaining >= DF_EXTRA_ROW_H * 3 -> minOf(3, (dailyNames.size - 2).coerceAtLeast(0))
            remaining >= DF_EXTRA_ROW_H * 2 -> minOf(2, (dailyNames.size - 2).coerceAtLeast(0))
            remaining >= DF_EXTRA_ROW_H     -> minOf(1, (dailyNames.size - 2).coerceAtLeast(0))
            else -> 0
        }

        val clickAction = actionStartActivity<MainActivity>(
            context, "overmorrrow://opened?location=$location&latlon=$latLon".toUri()
        )

        if (isWide) {
            WideLayout(
                frontColor, onFrontColor,
                frontContainerColor, onFrontContainerColor,
                backColor,
                placeName, dailyHighs, dailyLows, dailyConds, dailyNames, dailyPrecip,
                upcomingCols,
                showToday, showTomorrow, extraDayCount, showQuote, displayQuote,
                clickAction
            )
        } else {
            CompactLayout(
                frontColor, onFrontColor, backColor,
                placeName, dailyHighs, dailyLows, dailyConds, dailyNames, dailyPrecip,
                upcomingCols, showQuote, displayQuote, clickAction
            )
        }
    }

    // ── Wide Layout ──────────────────────────────────────────────────────────

    @Composable
    private fun WideLayout(
        frontColor: androidx.glance.unit.ColorProvider,
        onFrontColor: androidx.glance.unit.ColorProvider,
        frontContainerColor: androidx.glance.unit.ColorProvider,
        onFrontContainerColor: androidx.glance.unit.ColorProvider,
        backColor: androidx.glance.unit.ColorProvider,
        placeName: String,
        dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyConds: List<String>, dailyNames: List<String>, dailyPrecip: List<Int>,
        upcomingCols: Int,
        showToday: Boolean, showTomorrow: Boolean, extraDayCount: Int,
        showQuote: Boolean, displayQuote: String,
        clickAction: androidx.glance.action.Action
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .padding(horizontal = 12.dp, vertical = 10.dp)
                .cornerRadius(24.dp)
                .clickable(onClick = clickAction)
        ) {
            // Header always at top
            HeaderRow(
                frontColor, placeName,
                dailyHighs, dailyLows, dailyConds, dailyNames, dailyPrecip,
                upcomingCols
            )

            // TODAY — full frontColor card (most prominent)
            if (showToday) {
                Spacer(modifier = GlanceModifier.size(8.dp))
                TodayCard(frontColor, onFrontColor, dailyConds, dailyHighs, dailyLows, dailyPrecip)
            }

            // TOMORROW — container color card (medium prominence)
            if (showTomorrow) {
                Spacer(modifier = GlanceModifier.size(6.dp))
                TomorrowCard(
                    frontColor, frontContainerColor, onFrontContainerColor,
                    dailyConds, dailyHighs, dailyLows, dailyNames, dailyPrecip
                )
            }

            // Extra day rows: Day+2 (subtle bg), Day+3/4 (plain)
            val safeExtra = minOf(extraDayCount, (dailyNames.size - 2).coerceAtLeast(0))
            for (dayOffset in 2 until 2 + safeExtra) {
                Spacer(modifier = GlanceModifier.size(4.dp))
                ExtraDayRow(
                    frontColor, frontContainerColor,
                    dailyConds, dailyHighs, dailyLows, dailyNames, dailyPrecip,
                    dayOffset
                )
            }

            // Quote pushed to bottom via weight spacer
            Spacer(modifier = GlanceModifier.defaultWeight())
            if (showQuote) {
                Text(
                    text = "\"$displayQuote\"",
                    style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp),
                    modifier = GlanceModifier.fillMaxWidth()
                        .padding(horizontal = 4.dp, vertical = 2.dp)
                )
            }
        }
    }

    // ── Compact Layout ───────────────────────────────────────────────────────

    @Composable
    private fun CompactLayout(
        frontColor: androidx.glance.unit.ColorProvider,
        onFrontColor: androidx.glance.unit.ColorProvider,
        backColor: androidx.glance.unit.ColorProvider,
        placeName: String,
        dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyConds: List<String>, dailyNames: List<String>, dailyPrecip: List<Int>,
        upcomingCols: Int,
        showQuote: Boolean, displayQuote: String,
        clickAction: androidx.glance.action.Action
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .padding(horizontal = 14.dp, vertical = 10.dp)
                .cornerRadius(24.dp)
                .clickable(onClick = clickAction)
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth().wrapContentHeight(),
                verticalAlignment = Alignment.Vertical.CenterVertically
            ) {
                Column(
                    modifier = GlanceModifier.wrapContentWidth(),
                    horizontalAlignment = Alignment.Horizontal.Start
                ) {
                    if (dailyConds.isNotEmpty()) {
                        Image(
                            provider = ImageProvider(getIconForCondition(dailyConds[0])),
                            contentDescription = "Today",
                            colorFilter = ColorFilter.tint(frontColor),
                            modifier = GlanceModifier.size(48.dp)
                        )
                    }
                    Spacer(modifier = GlanceModifier.size(4.dp))
                    val hi = dailyHighs.getOrElse(0) { 0 }
                    val lo = dailyLows.getOrElse(0) { 0 }
                    Text(
                        text = "$lo° / $hi°",
                        style = TextStyle(color = frontColor, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    )
                    Spacer(modifier = GlanceModifier.size(3.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Image(
                            provider = ImageProvider(R.drawable.icon_location),
                            contentDescription = "Location",
                            colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
                            modifier = GlanceModifier.size(13.dp).padding(end = 2.dp)
                        )
                        Text(text = placeName, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 12.sp))
                    }
                }

                Spacer(modifier = GlanceModifier.defaultWeight())

                Row(
                    modifier = GlanceModifier.wrapContentWidth(),
                    verticalAlignment = Alignment.Vertical.CenterVertically
                ) {
                    val safeCount = minOf(upcomingCols, (dailyNames.size - 1).coerceAtLeast(0))
                    for (i in 1..safeCount) {
                        Spacer(modifier = GlanceModifier.size(8.dp))
                        DayColumn(frontColor, dailyConds, dailyHighs, dailyLows, dailyNames, dailyPrecip, i)
                    }
                }
            }

            Spacer(modifier = GlanceModifier.defaultWeight())
            if (showQuote) {
                Text(
                    text = "\"$displayQuote\"",
                    style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp),
                    modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp)
                )
            }
        }
    }

    // ── Sub-composables ───────────────────────────────────────────────────────

    @Composable
    private fun HeaderRow(
        frontColor: androidx.glance.unit.ColorProvider,
        placeName: String,
        dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyConds: List<String>, dailyNames: List<String>, dailyPrecip: List<Int>,
        upcomingCols: Int
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().wrapContentHeight(),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.Start
            ) {
                if (dailyConds.isNotEmpty()) {
                    Image(
                        provider = ImageProvider(getIconForCondition(dailyConds[0])),
                        contentDescription = "Today weather",
                        colorFilter = ColorFilter.tint(frontColor),
                        modifier = GlanceModifier.size(60.dp)
                    )
                }
                Spacer(modifier = GlanceModifier.size(4.dp))
                val hi = dailyHighs.getOrElse(0) { 0 }
                val lo = dailyLows.getOrElse(0) { 0 }
                Text(
                    text = "$lo° / $hi°",
                    style = TextStyle(color = frontColor, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.End
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Image(
                        provider = ImageProvider(R.drawable.icon_location),
                        contentDescription = "Location",
                        colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
                        modifier = GlanceModifier.size(14.dp).padding(end = 3.dp)
                    )
                    Text(text = placeName, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 13.sp))
                }
                Spacer(modifier = GlanceModifier.size(8.dp))
                val safeCount = minOf(upcomingCols, (dailyNames.size - 1).coerceAtLeast(0))
                Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
                    for (i in 1..safeCount) {
                        DayColumn(frontColor, dailyConds, dailyHighs, dailyLows, dailyNames, dailyPrecip, i)
                        if (i < safeCount) Spacer(modifier = GlanceModifier.size(12.dp))
                    }
                }
            }
        }
    }

    @Composable
    private fun DayColumn(
        frontColor: androidx.glance.unit.ColorProvider,
        dailyConds: List<String>, dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyNames: List<String>, dailyPrecip: List<Int>,
        index: Int
    ) {
        Column(
            modifier = GlanceModifier.wrapContentWidth(),
            horizontalAlignment = Alignment.Horizontal.CenterHorizontally
        ) {
            Text(
                text = dailyNames.getOrElse(index) { "—" },
                style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 13.sp)
            )
            Spacer(modifier = GlanceModifier.size(3.dp))
            Image(
                provider = ImageProvider(getIconForCondition(dailyConds.getOrElse(index) { "" })),
                contentDescription = "Icon",
                colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface),
                modifier = GlanceModifier.size(28.dp)
            )
            Spacer(modifier = GlanceModifier.size(3.dp))
            Text(
                text = "${dailyHighs.getOrElse(index) { 0 }}°",
                style = TextStyle(color = frontColor, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            )
            Text(
                text = "${dailyLows.getOrElse(index) { 0 }}°",
                style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 13.sp)
            )
            val precip = dailyPrecip.getOrElse(index) { 0 }
            if (precip > 0) {
                Spacer(modifier = GlanceModifier.size(2.dp))
                Text(
                    text = "$precip%",
                    style = TextStyle(
                        color = if (precip >= 60) GlanceTheme.colors.error else GlanceTheme.colors.outline,
                        fontSize = 11.sp
                    )
                )
            }
        }
    }

    /**
     * TODAY card: max prominence — solid frontColor background.
     * Shows: "Today" label | condition name | icon | H° / L° | precip%
     */
    @Composable
    private fun TodayCard(
        frontColor: androidx.glance.unit.ColorProvider,
        onFrontColor: androidx.glance.unit.ColorProvider,
        dailyConds: List<String>, dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyPrecip: List<Int>
    ) {
        if (dailyConds.isEmpty()) return
        val hi     = dailyHighs.getOrElse(0) { 0 }
        val lo     = dailyLows.getOrElse(0) { 0 }
        val precip = dailyPrecip.getOrElse(0) { 0 }

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(frontColor)
                .cornerRadius(16.dp)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            // Label + condition text
            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.Start
            ) {
                Text(
                    text = "Today",
                    style = TextStyle(color = onFrontColor, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                )
                Text(
                    text = dailyConds[0].replace("_", " ").lowercase()
                        .replaceFirstChar { it.uppercase() },
                    style = TextStyle(color = onFrontColor, fontSize = 12.sp)
                )
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            Image(
                provider = ImageProvider(getIconForCondition(dailyConds[0])),
                contentDescription = "Today icon",
                colorFilter = ColorFilter.tint(onFrontColor),
                modifier = GlanceModifier.size(34.dp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Column(horizontalAlignment = Alignment.Horizontal.CenterHorizontally) {
                Text(
                    text = "$hi°",
                    style = TextStyle(color = onFrontColor, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                )
                Text(
                    text = "$lo°",
                    style = TextStyle(color = onFrontColor, fontSize = 15.sp)
                )
            }
            if (precip > 0) {
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text = "$precip%",
                    style = TextStyle(color = onFrontColor, fontSize = 14.sp)
                )
            }
        }
    }

    /**
     * TOMORROW card: medium prominence — frontContainer background (softer).
     * Slightly smaller than Today to create visual hierarchy.
     */
    @Composable
    private fun TomorrowCard(
        frontColor: androidx.glance.unit.ColorProvider,
        frontContainerColor: androidx.glance.unit.ColorProvider,
        onFrontContainerColor: androidx.glance.unit.ColorProvider,
        dailyConds: List<String>, dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyNames: List<String>, dailyPrecip: List<Int>
    ) {
        if (dailyHighs.size < 2 || dailyLows.size < 2) return
        val hi     = dailyHighs[1]
        val lo     = dailyLows[1]
        val precip = dailyPrecip.getOrElse(1) { 0 }

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(frontContainerColor)
                .cornerRadius(14.dp)
                .padding(horizontal = 16.dp, vertical = 9.dp),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.Start
            ) {
                Text(
                    text = "Tomorrow",
                    style = TextStyle(color = onFrontContainerColor, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                )
                Text(
                    text = dailyConds.getOrElse(1) { "" }.replace("_", " ").lowercase()
                        .replaceFirstChar { it.uppercase() },
                    style = TextStyle(color = onFrontContainerColor, fontSize = 11.sp)
                )
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            Image(
                provider = ImageProvider(getIconForCondition(dailyConds.getOrElse(1) { "" })),
                contentDescription = "Tomorrow icon",
                colorFilter = ColorFilter.tint(onFrontContainerColor),
                modifier = GlanceModifier.size(28.dp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Column(horizontalAlignment = Alignment.Horizontal.CenterHorizontally) {
                Text(
                    text = "$hi°",
                    style = TextStyle(color = onFrontContainerColor, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                )
                Text(
                    text = "$lo°",
                    style = TextStyle(color = onFrontContainerColor, fontSize = 13.sp)
                )
            }
            if (precip > 0) {
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text = "$precip%",
                    style = TextStyle(color = onFrontContainerColor, fontSize = 13.sp)
                )
            }
        }
    }

    /**
     * Extra day rows for Day+2..Day+4.
     * Day+2: surface variant bg for subtle distinction.
     * Day+3/4: plain, no background.
     */
    @Composable
    private fun ExtraDayRow(
        frontColor: androidx.glance.unit.ColorProvider,
        frontContainerColor: androidx.glance.unit.ColorProvider,
        dailyConds: List<String>, dailyHighs: List<Int>, dailyLows: List<Int>,
        dailyNames: List<String>, dailyPrecip: List<Int>,
        index: Int
    ) {
        if (index >= dailyHighs.size || index >= dailyLows.size) return
        val hi     = dailyHighs[index]
        val lo     = dailyLows[index]
        val precip = dailyPrecip.getOrElse(index) { 0 }

        // Day+2 gets a very subtle container bg; Day+3/4 get plain rows
        val useSubtleBg = (index == 2)

        val rowModifier = if (useSubtleBg) {
            GlanceModifier
                .fillMaxWidth()
                .background(GlanceTheme.colors.surfaceVariant)
                .cornerRadius(10.dp)
                .padding(horizontal = 14.dp, vertical = 7.dp)
        } else {
            GlanceModifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 5.dp)
        }

        Row(
            modifier = rowModifier,
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Text(
                text = dailyNames.getOrElse(index) { "—" },
                style = TextStyle(
                    color = if (useSubtleBg) GlanceTheme.colors.onSurface else GlanceTheme.colors.onSurface,
                    fontSize = 14.sp
                ),
                modifier = GlanceModifier.defaultWeight()
            )
            Image(
                provider = ImageProvider(getIconForCondition(dailyConds.getOrElse(index) { "" })),
                contentDescription = "Icon",
                colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface),
                modifier = GlanceModifier.size(22.dp)
            )
            Spacer(modifier = GlanceModifier.size(10.dp))
            Text(
                text = "$hi°",
                style = TextStyle(color = frontColor, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            )
            Spacer(modifier = GlanceModifier.size(4.dp))
            Text(
                text = "$lo°",
                style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 13.sp)
            )
            if (precip > 0) {
                Spacer(modifier = GlanceModifier.size(8.dp))
                Text(
                    text = "$precip%",
                    style = TextStyle(
                        color = if (precip >= 60) GlanceTheme.colors.error else GlanceTheme.colors.outline,
                        fontSize = 12.sp
                    )
                )
            }
        }
    }
}
