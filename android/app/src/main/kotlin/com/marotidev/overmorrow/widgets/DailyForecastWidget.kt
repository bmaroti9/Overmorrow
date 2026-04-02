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
import androidx.glance.unit.ColorProvider
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.marotidev.overmorrow.MainActivity
import com.marotidev.overmorrow.R
import com.marotidev.overmorrow.services.getBackColor
import com.marotidev.overmorrow.services.getFrontColor
import com.marotidev.overmorrow.services.getOnFrontColor
import com.marotidev.overmorrow.services.getIconForCondition
import es.antonborri.home_widget.actionStartActivity
import java.lang.reflect.Type

// ── Constants ──────────────────────────────────────────────────────────────────

private val dfGson = Gson()
private val dfIntListType: Type    = object : TypeToken<List<Int>>() {}.type
private val dfStrListType: Type    = object : TypeToken<List<String>>() {}.type

/** Each grid cell is ~56dp on MDPI; used to convert widget dp size → col count. */
private const val CELL_DP = 56f

/** Max forecast days to ever display (today + 6 upcoming = 7). */
private const val MAX_DAYS = 7

// Layout constants
private val OUTER_V_PAD   = 10.dp
private val OUTER_H_PAD   = 12.dp
private val CARD_GAP      = 4.dp

// ── Data Models ────────────────────────────────────────────────────────────────

/**
 * Immutable snapshot of a single day's forecast data.
 * Index 0 = today, index 1 = tomorrow, … up to MAX_DAYS-1.
 */
private data class ForecastDay(
    val label: String,       // e.g. "Mon", "Tue" — overridden to "Today"/"Tomorrow" for index 0/1
    val condition: String,   // raw condition string, e.g. "partly_cloudy"
    val hi: Int,
    val lo: Int,
    val precipPct: Int,      // 0 if unknown/zero
    val displayCondition: String = condition.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() },
)

/**
 * All daily forecast widget data parsed from SharedPreferences.
 * Separating parsing from rendering makes both independently testable.
 */
private data class DailyForecastData(
    val placeName: String,
    val location: String,
    val latLon: String,
    val backColorStr: String,
    val frontColorStr: String,
    val quote: String,
    val currentTemp: Int,
    val todayDate: String,
    /** Up to MAX_DAYS entries; may be empty if data not yet synced. */
    val days: List<ForecastDay>,
)

// ── Widget ─────────────────────────────────────────────────────────────────────

/**
 * DailyForecastWidget — up to 7-day weather forecast as an Android Glance widget.
 *
 * Layout strategy (Glance/RemoteViews constraints):
 *   - SizeMode.Exact gives us the rendered dp size via LocalSize.
 *   - Glance is built on RemoteViews; `defaultWeight()` fills ALL remaining space.
 *     Any child placed AFTER defaultWeight is rendered at 0px height and clipped.
 *   - Quote must therefore be placed BEFORE the defaultWeight Spacer.
 *   - Quote space is reserved first; remaining budget is divided among cards.
 *   - Card height is clamped between MIN_CARD and MAX_CARD; cards are dropped
 *     one at a time until they fit.
 */
class DailyForecastWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent { GlanceContent(context, currentState(), appWidgetId) }
    }

    // ── Data parsing ──────────────────────────────────────────────────────────

    private fun parseWidgetData(state: HomeWidgetGlanceState, id: Int): DailyForecastData {
        val p = state.preferences

        fun str(key: String, default: String = "") = p.getString("$key.$id", default) ?: default
        fun int(key: String, default: Int = 0)    = p.getInt("$key.$id", default)
        fun <T> json(raw: String, type: Type): List<T> =
            try { dfGson.fromJson<List<T>>(raw, type) ?: emptyList() } catch (_: Exception) { emptyList() }

        val highs:  List<Int>    = json(str("dailyForecast.dailyHighTemps",   "[]"), dfIntListType)
        val lows:   List<Int>    = json(str("dailyForecast.dailyLowTemps",    "[]"), dfIntListType)
        val conds:  List<String> = json(str("dailyForecast.dailyConditions",  "[]"), dfStrListType)
        val names:  List<String> = json(str("dailyForecast.dailyNames",       "[]"), dfStrListType)
        val precip: List<Int>    = json(str("dailyForecast.dailyPrecipProbs", "[]"), dfIntListType)

        val count = minOf(names.size, highs.size, lows.size, MAX_DAYS)
        val days = (0 until count).map { i ->
            ForecastDay(
                label     = names.getOrElse(i) { "" },
                condition = conds.getOrElse(i) { "" },
                hi        = highs[i],
                lo        = lows[i],
                precipPct = precip.getOrElse(i) { 0 },
            )
        }

        return DailyForecastData(
            placeName    = str("widget.place",      "—"),
            location     = str("widget.location",   "--"),
            latLon       = str("widget.latLon",     "--"),
            backColorStr = str("widget.backColor",  "secondary container"),
            frontColorStr= str("widget.frontColor", "primary"),
            quote        = str("widget.quote",      ""),
            currentTemp  = int("dailyForecast.currentTemp"),
            todayDate    = str("dailyForecast.todayDate", ""),
            days         = days,
        )
    }

    // ── Entry point ───────────────────────────────────────────────────────────

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState, appWidgetId: Int) {
        val data = parseWidgetData(state, appWidgetId)

        val backColor    = getBackColor(data.backColorStr)
        val frontColor   = getFrontColor(data.frontColorStr)
        val onFrontColor = getOnFrontColor(data.frontColorStr)

        val size   = LocalSize.current
        val cols   = (size.width.value / CELL_DP).toInt().coerceIn(1, 8)
        val rows   = (size.height.value / CELL_DP).toInt().coerceIn(1, 12)

        val futureDays = (data.days.size - 1).coerceAtLeast(0)
        val hasQuote = data.quote.isNotEmpty()

        val clickAction = actionStartActivity<MainActivity>(
            context,
            "overmorrrow://opened?location=${data.location}&latlon=${data.latLon}".toUri()
        )

        // ── Layout selection based on grid rows/cols ──────────────────────────
        // No dp budget estimation — use grid rows to decide content amount.
        // Header ~2 rows, each card ~1 row, quote ~0.5 row.
        // This matches how other widgets in the project work (ForecastWidget etc.)
        val isCompact = cols < 4 || rows < 4
        if (isCompact) {
            val dayCols = (cols - 1).coerceIn(0, 3).coerceAtMost(futureDays)
            CompactLayout(data, frontColor, backColor, rows, dayCols, hasQuote, clickAction)
        } else {
            // Card count: each card gets equal share of remaining space via defaultWeight
            // Header ~2 rows, quote ~0.5 row — cards fill the rest, no truncation possible
            val maxCards = (rows - 3).coerceIn(0, MAX_DAYS - 1)
            val visibleCards = minOf(maxCards, futureDays)
            // DayColumns in header: show days not covered by cards
            val headerStart = visibleCards + 1
            val headerDayCols = if (rows >= 4) {
                (cols - 3).coerceIn(0, 6).coerceAtMost((data.days.size - headerStart).coerceAtLeast(0))
            } else 0
            WideLayout(data, frontColor, backColor, onFrontColor, visibleCards, hasQuote, headerDayCols, headerStart, clickAction)
        }
    }

    // ── Wide Layout ───────────────────────────────────────────────────────────

    @Composable
    private fun WideLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        onFrontColor: ColorProvider,
        visibleCards: Int,
        showQuote: Boolean,
        headerDayCols: Int,
        headerStartIndex: Int,
        clickAction: androidx.glance.action.Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .padding(horizontal = OUTER_H_PAD, vertical = OUTER_V_PAD)
                .cornerRadius(24.dp)
                .clickable(onClick = clickAction),
        ) {
            // Header: wrapContent — Glance determines actual height
            HeaderRow(frontColor, data, headerDayCols, headerStartIndex)

            // Cards fill remaining space between header and quote.
            // Each card uses defaultWeight to equally share the available space — no truncation, no gaps.
            Column(
                modifier = GlanceModifier.fillMaxWidth().defaultWeight(),
                verticalAlignment = Alignment.Vertical.CenterVertically,
            ) {
                data.days.drop(1).take(visibleCards).forEachIndexed { i, day ->
                    if (i > 0) Spacer(modifier = GlanceModifier.size(CARD_GAP))
                    DayCard(frontColor, onFrontColor, day, modifier = GlanceModifier.fillMaxWidth().defaultWeight())
                }
            }

            // Quote at bottom — wrapContent, measured before defaultWeight, never clipped
            if (showQuote) {
                Spacer(modifier = GlanceModifier.size(4.dp))
                QuoteText(data.quote, fontSize = 11)
            }
        }
    }

    // ── Compact Layout ────────────────────────────────────────────────────────

    @Composable
    private fun CompactLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        rows: Int,
        headerDayCols: Int,
        showQuote: Boolean,
        clickAction: androidx.glance.action.Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .padding(horizontal = 14.dp, vertical = 12.dp)
                .cornerRadius(24.dp)
                .clickable(onClick = clickAction),
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth().defaultWeight(),
                verticalAlignment = Alignment.Vertical.CenterVertically,
            ) {
                CompactLeftPanel(data, frontColor, rows, showQuote)

                Spacer(modifier = GlanceModifier.defaultWeight())

                val safeCount = minOf(headerDayCols, (data.days.size - 1).coerceAtLeast(0))
                Row(
                    modifier = GlanceModifier.wrapContentWidth(),
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                ) {
                    for (i in 1..safeCount) {
                        if (i > 1) Spacer(modifier = GlanceModifier.size(8.dp))
                        DayColumn(frontColor, data.days, i)
                    }
                }
            }
        }
    }

    // ── Sub-composables ───────────────────────────────────────────────────────

    @Composable
    private fun QuoteText(quote: String, fontSize: Int) {
        Text(
            text  = "\"$quote\"",
            style = TextStyle(color = GlanceTheme.colors.outline, fontSize = fontSize.sp),
            modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp),
        )
    }

    @Composable
    private fun HeaderRow(
        frontColor: ColorProvider,
        data: DailyForecastData,
        headerDayCols: Int,
        startIndex: Int = 1,
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().wrapContentHeight(),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            // Left: weather icon + current / hi-lo temp
            Column(modifier = GlanceModifier.wrapContentWidth(), horizontalAlignment = Alignment.Horizontal.Start) {
                val today = data.days.firstOrNull()
                if (today != null) {
                    Image(
                        provider    = ImageProvider(getIconForCondition(today.condition)),
                        contentDescription = "Today",
                        colorFilter = ColorFilter.tint(frontColor),
                        modifier    = GlanceModifier.size(50.dp),
                    )
                }
                Spacer(modifier = GlanceModifier.size(4.dp))
                Text("${data.currentTemp}°", style = TextStyle(color = frontColor, fontSize = 28.sp, fontWeight = FontWeight.Bold))
                val hi = today?.hi ?: 0; val lo = today?.lo ?: 0
                Text("$hi° / $lo°", style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 12.sp))
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            // Right: date + location + upcoming mini-columns
            Column(modifier = GlanceModifier.wrapContentWidth(), horizontalAlignment = Alignment.Horizontal.End) {
                if (data.todayDate.isNotEmpty()) {
                    Text(data.todayDate, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp))
                    Spacer(modifier = GlanceModifier.size(2.dp))
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Image(
                        provider    = ImageProvider(R.drawable.icon_location),
                        contentDescription = "Location",
                        colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
                        modifier    = GlanceModifier.size(12.dp).padding(end = 3.dp),
                    )
                    Text(data.placeName, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 12.sp))
                }
                if (headerDayCols > 0) {
                    Spacer(modifier = GlanceModifier.size(6.dp))
                    Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
                        val safeCount = minOf(headerDayCols, (data.days.size - startIndex).coerceAtLeast(0))
                        for (i in 0 until safeCount) {
                            if (i > 0) Spacer(modifier = GlanceModifier.size(10.dp))
                            DayColumn(frontColor, data.days, startIndex + i)
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun CompactLeftPanel(data: DailyForecastData, frontColor: ColorProvider, rows: Int, showQuote: Boolean) {
        val today = data.days.firstOrNull()
        Column(
            modifier = GlanceModifier.wrapContentWidth(),
            horizontalAlignment = Alignment.Horizontal.Start,
        ) {
            val iconSize = if (rows >= 3) 48.dp else 40.dp
            if (today != null) {
                Image(
                    provider    = ImageProvider(getIconForCondition(today.condition)),
                    contentDescription = "Today",
                    colorFilter = ColorFilter.tint(frontColor),
                    modifier    = GlanceModifier.size(iconSize),
                )
            }
            Spacer(modifier = GlanceModifier.size(4.dp))
            Text("${data.currentTemp}°", style = TextStyle(color = frontColor, fontSize = 20.sp, fontWeight = FontWeight.Bold))
            Text("${today?.hi ?: 0}° / ${today?.lo ?: 0}°", style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp))
            // Always show place name so user knows which city
            Spacer(modifier = GlanceModifier.size(2.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Image(
                    provider    = ImageProvider(R.drawable.icon_location),
                    contentDescription = "Location",
                    colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
                    modifier    = GlanceModifier.size(11.dp).padding(end = 2.dp),
                )
                Text(data.placeName, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp))
            }
            // Only show condition, precip, date when there's enough vertical space
            if (rows >= 3) {
                val condText = today?.displayCondition ?: ""
                if (condText.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.size(2.dp))
                    Text(condText, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp))
                }
                if ((today?.precipPct ?: 0) > 0) {
                    Text(
                        "${today!!.precipPct}%",
                        style = TextStyle(
                            color    = if (today.precipPct >= 60) GlanceTheme.colors.error else GlanceTheme.colors.outline,
                            fontSize = 10.sp,
                        )
                    )
                }
                Spacer(modifier = GlanceModifier.size(3.dp))
                if (data.todayDate.isNotEmpty()) {
                    Text(data.todayDate, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp))
                }
            }
        }
    }

    /** Vertical mini-column shown in header strip (wide) or compact right panel. */
    @Composable
    private fun DayColumn(frontColor: ColorProvider, days: List<ForecastDay>, index: Int) {
        val day = days.getOrNull(index) ?: return
        Column(
            modifier = GlanceModifier.wrapContentWidth(),
            horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
        ) {
            Text(day.label, style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp))
            Spacer(modifier = GlanceModifier.size(3.dp))
            Image(
                provider    = ImageProvider(getIconForCondition(day.condition)),
                contentDescription = day.label,
                colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface),
                modifier    = GlanceModifier.size(24.dp),
            )
            Spacer(modifier = GlanceModifier.size(2.dp))
            Text("${day.hi}°", style = TextStyle(color = frontColor, fontSize = 13.sp, fontWeight = FontWeight.Bold))
            Text("${day.lo}°", style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp))
            if (day.precipPct > 0) {
                Text(
                    "${day.precipPct}%",
                    style = TextStyle(
                        color    = if (day.precipPct >= 60) GlanceTheme.colors.error else GlanceTheme.colors.outline,
                        fontSize = 10.sp,
                    )
                )
            }
        }
    }

    /**
     * Full-width horizontal day card shown in wide layout rows.
     * Background uses [frontColor], text/icons use [onFrontColor].
     */
    @Composable
    private fun DayCard(frontColor: ColorProvider, onFrontColor: ColorProvider, day: ForecastDay, modifier: GlanceModifier = GlanceModifier) {
        val condText = day.displayCondition
        Row(
            modifier = modifier
                .background(frontColor)
                .cornerRadius(14.dp)
                .padding(horizontal = 16.dp, vertical = 6.dp),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            Column(modifier = GlanceModifier.wrapContentWidth(), horizontalAlignment = Alignment.Horizontal.Start) {
                Text(day.label, style = TextStyle(color = onFrontColor, fontSize = 15.sp, fontWeight = FontWeight.Bold))
                Spacer(modifier = GlanceModifier.size(1.dp))
                Text(condText, style = TextStyle(color = onFrontColor, fontSize = 11.sp))
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            Image(
                provider    = ImageProvider(getIconForCondition(day.condition)),
                contentDescription = day.label,
                colorFilter = ColorFilter.tint(onFrontColor),
                modifier    = GlanceModifier.size(30.dp),
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Column(horizontalAlignment = Alignment.Horizontal.CenterHorizontally) {
                Text("${day.hi}°", style = TextStyle(color = onFrontColor, fontSize = 19.sp, fontWeight = FontWeight.Bold))
                Text("${day.lo}°", style = TextStyle(color = onFrontColor, fontSize = 13.sp))
            }
            if (day.precipPct > 0) {
                Spacer(modifier = GlanceModifier.size(10.dp))
                Text(
                    "${day.precipPct}%",
                    style = TextStyle(
                        color    = if (day.precipPct >= 60) GlanceTheme.colors.error else onFrontColor,
                        fontSize = 12.sp,
                    )
                )
            }
        }
    }
}
