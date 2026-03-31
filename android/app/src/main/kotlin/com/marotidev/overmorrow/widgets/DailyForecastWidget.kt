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
import com.marotidev.overmorrow.services.getIconForCondition
import com.marotidev.overmorrow.services.getOnFrontColor
import es.antonborri.home_widget.actionStartActivity
import java.lang.reflect.Type

// ── Constants ──────────────────────────────────────────────────────────────────

private val dfGson2 = Gson()
private val dfIntListType2: Type    = object : TypeToken<List<Int>>() {}.type
private val dfStrListType2: Type    = object : TypeToken<List<String>>() {}.type

/** Each grid cell is ~56dp on MDPI; used to convert widget dp size → col count. */
private const val CELL_DP = 56f

/** Max forecast days to ever display (today + 6 upcoming = 7). */
private const val MAX_DAYS = 7

// Layout dp budgets (measured from actual rendered widget)
private const val DP_PAD     = 20f   // top+bottom outer padding (10+10)
private const val DP_HEADER  = 150f  // HeaderRow height (icon 50 + temps + location + day-cols ≈ 150)
private const val DP_CARD    =  60f  // DayCard height (padding + content)
private const val DP_SPACER  =   6f  // avg gap between cards (first=8, rest=5)
private const val DP_QUOTE   =  28f  // quote text + spacer above it

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

/**
 * Color pair (background + foreground) for a card tier.
 * Tiers progress from most-prominent (today) to least-prominent (day+6).
 */
private data class DayCardColors(val bg: ColorProvider, val fg: ColorProvider)

// ── Widget ─────────────────────────────────────────────────────────────────────

/**
 * DailyForecastWidget — up to 7-day weather forecast as an Android Glance widget.
 *
 * Layout strategy (Glance/RemoteViews constraints):
 *   - SizeMode.Exact gives us the rendered dp size via LocalSize.
 *   - Grid cells: cols = width/56, rows = height/56.
 *   - Quote is rendered as the FIRST child in the Column → it can never be
 *     pushed out of frame by content below it.
 *   - A single `defaultWeight()` Spacer at the bottom absorbs leftover space.
 *   - Day cards rendered via loop over DayEntry list — no more showDay0..showDay6.
 *
 * Visible card count (wide layout):
 *   rows <= 2  → 0 cards  (header only)
 *   rows == 3  → 1 card   (today)
 *   rows == 4  → 2 cards  (+ tomorrow)
 *   …
 *   rows >= 9  → 7 cards  (today … day+6)
 *   Quote shown when rows >= 2 and quote non-empty.
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
            try { dfGson2.fromJson<List<T>>(raw, type) ?: emptyList() } catch (_: Exception) { emptyList() }

        val highs:  List<Int>    = json(str("dailyForecast.dailyHighTemps",   "[]"), dfIntListType2)
        val lows:   List<Int>    = json(str("dailyForecast.dailyLowTemps",    "[]"), dfIntListType2)
        val conds:  List<String> = json(str("dailyForecast.dailyConditions",  "[]"), dfStrListType2)
        val names:  List<String> = json(str("dailyForecast.dailyNames",       "[]"), dfStrListType2)
        val precip: List<Int>    = json(str("dailyForecast.dailyPrecipProbs", "[]"), dfIntListType2)

        val count = minOf(names.size, highs.size, lows.size, MAX_DAYS)
        val days = (0 until count).map { i ->
            ForecastDay(
                label     = when (i) { 0 -> "Today"; 1 -> "Tomorrow"; else -> names[i] },
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

    // ── Theme helpers ─────────────────────────────────────────────────────────

    /**
     * Returns card color tiers in order from most-prominent (index 0 = today)
     * to least-prominent (index 6 = day+6).  Always 7 entries regardless of data.
     */
    @Composable
    private fun buildCardTiers(frontColorStr: String): List<DayCardColors> {
        val tier1 = DayCardColors(
            bg = when (frontColorStr) {
                "secondary" -> GlanceTheme.colors.secondary
                "tertiary"  -> GlanceTheme.colors.tertiary
                else        -> GlanceTheme.colors.primary
            },
            fg = when (frontColorStr) {
                "secondary" -> GlanceTheme.colors.onSecondary
                "tertiary"  -> GlanceTheme.colors.onTertiary
                else        -> GlanceTheme.colors.onPrimary
            },
        )
        val tier2 = DayCardColors(
            bg = when (frontColorStr) {
                "secondary" -> GlanceTheme.colors.secondaryContainer
                "tertiary"  -> GlanceTheme.colors.tertiaryContainer
                else        -> GlanceTheme.colors.primaryContainer
            },
            fg = when (frontColorStr) {
                "secondary" -> GlanceTheme.colors.onSecondaryContainer
                "tertiary"  -> GlanceTheme.colors.onTertiaryContainer
                else        -> GlanceTheme.colors.onPrimaryContainer
            },
        )
        return listOf(
            tier1,                                                                           // 0 Today
            tier2,                                                                           // 1 Tomorrow
            DayCardColors(GlanceTheme.colors.surfaceVariant,      GlanceTheme.colors.onSurface),            // 2
            DayCardColors(GlanceTheme.colors.tertiaryContainer,   GlanceTheme.colors.onTertiaryContainer),  // 3
            DayCardColors(GlanceTheme.colors.secondaryContainer,  GlanceTheme.colors.onSecondaryContainer), // 4
            DayCardColors(GlanceTheme.colors.inverseSurface,      GlanceTheme.colors.inverseOnSurface),     // 5
            DayCardColors(GlanceTheme.colors.primaryContainer,    GlanceTheme.colors.onPrimaryContainer),   // 6
        )
    }

    // ── Entry point ───────────────────────────────────────────────────────────

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState, appWidgetId: Int) {
        val data = parseWidgetData(state, appWidgetId)

        val backColor    = getBackColor(data.backColorStr)
        val frontColor   = getFrontColor(data.frontColorStr)
        val cardTiers    = buildCardTiers(data.frontColorStr)

        val size   = LocalSize.current
        val heightDp = size.height.value
        val cols = (size.width.value / CELL_DP).toInt().coerceIn(1, 8)
        val rows = (heightDp         / CELL_DP).toInt().coerceIn(1, 12)

        // How many day-columns to show in the header strip (wide only)
        val headerDayCols = (cols - 3).coerceIn(0, 6)
            .coerceAtMost((data.days.size - 1).coerceAtLeast(0))

        val hasQuote = data.quote.isNotEmpty()

        // Budget-based card count: space allows cards first, quote is squeezed in if possible.
        // visibleCards = min((availableHeight - headerHeight) / cardHeight, MAX_DAYS, dataSize)
        val budgetForCards = heightDp - DP_PAD - DP_HEADER
        val visibleCards   = (budgetForCards / (DP_CARD + DP_SPACER))
            .toInt().coerceIn(0, minOf(MAX_DAYS, data.days.size))
        // Only show quote if after rendering cards there's still 28dp of height left.
        // This ensures quote never breaks the layout.
        val cardsHeight = (visibleCards * (DP_CARD + DP_SPACER)) - DP_SPACER + DP_HEADER
        val remainingHeight = heightDp - cardsHeight
        val showQuote = hasQuote && remainingHeight >= DP_QUOTE

        val clickAction = actionStartActivity<MainActivity>(
            context,
            "overmorrrow://opened?location=${data.location}&latlon=${data.latLon}".toUri()
        )

        val isCompact = cols < 4
        if (isCompact) {
            CompactLayout(data, frontColor, backColor, rows, headerDayCols, showQuote, clickAction)
        } else {
            WideLayout(data, frontColor, backColor, cardTiers, visibleCards, showQuote, headerDayCols, clickAction)
        }
    }

    // ── Wide Layout ───────────────────────────────────────────────────────────

    @Composable
    private fun WideLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        cardTiers: List<DayCardColors>,
        visibleCards: Int,
        showQuote: Boolean,
        headerDayCols: Int,
        clickAction: androidx.glance.action.Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .padding(horizontal = 12.dp, vertical = 10.dp)
                .cornerRadius(24.dp)
                .clickable(onClick = clickAction),
        ) {
            HeaderRow(frontColor, data, headerDayCols)

            // Loop: space allows exactly visibleCards cards (budget-calculated in GlanceContent)
            data.days.take(visibleCards).forEachIndexed { i, day ->
                Spacer(modifier = GlanceModifier.size(if (i == 0) 8.dp else 5.dp))
                DayCard(
                    colors = cardTiers.getOrElse(i) { cardTiers.last() },
                    day    = day,
                )
            }

            // defaultWeight pushes quote to bottom-left; quote is always BEFORE container end
            Spacer(modifier = GlanceModifier.defaultWeight())
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
                modifier = GlanceModifier.fillMaxWidth().wrapContentHeight(),
                verticalAlignment = Alignment.Vertical.CenterVertically,
            ) {
                CompactLeftPanel(data, frontColor, rows)

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

            // defaultWeight absorbs middle space; quote is last and safe before container end
            Spacer(modifier = GlanceModifier.defaultWeight())
            if (showQuote) {
                Spacer(modifier = GlanceModifier.size(4.dp))
                QuoteText(data.quote, fontSize = 10)
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
                Spacer(modifier = GlanceModifier.size(3.dp))
                if (data.currentTemp != 0) {
                    Text("${data.currentTemp}°", style = TextStyle(color = frontColor, fontSize = 24.sp, fontWeight = FontWeight.Bold))
                    val hi = today?.hi ?: 0; val lo = today?.lo ?: 0
                    Text("$hi° / $lo°", style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 12.sp))
                } else {
                    val hi = today?.hi ?: 0; val lo = today?.lo ?: 0
                    Text("$hi° / $lo°", style = TextStyle(color = frontColor, fontSize = 20.sp, fontWeight = FontWeight.Bold))
                }
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
                        val safeCount = minOf(headerDayCols, (data.days.size - 1).coerceAtLeast(0))
                        for (i in 1..safeCount) {
                            if (i > 1) Spacer(modifier = GlanceModifier.size(10.dp))
                            DayColumn(frontColor, data.days, i)
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun CompactLeftPanel(data: DailyForecastData, frontColor: ColorProvider, rows: Int) {
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
            if (data.currentTemp != 0) {
                Text("${data.currentTemp}°", style = TextStyle(color = frontColor, fontSize = 20.sp, fontWeight = FontWeight.Bold))
                Text("${today?.hi ?: 0}° / ${today?.lo ?: 0}°", style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp))
            } else {
                Text("${today?.hi ?: 0}° / ${today?.lo ?: 0}°", style = TextStyle(color = frontColor, fontSize = 17.sp, fontWeight = FontWeight.Bold))
            }
            val condText = today?.condition?.replace("_", " ")?.lowercase()?.replaceFirstChar { it.uppercase() } ?: ""
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
                Spacer(modifier = GlanceModifier.size(1.dp))
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Image(
                    provider    = ImageProvider(R.drawable.icon_location),
                    contentDescription = "Location",
                    colorFilter = ColorFilter.tint(GlanceTheme.colors.outline),
                    modifier    = GlanceModifier.size(11.dp).padding(end = 2.dp),
                )
                Text(data.placeName, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp))
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
     * All tiers identical in structure — only [colors] differ.
     */
    @Composable
    private fun DayCard(colors: DayCardColors, day: ForecastDay) {
        val condText = day.condition.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() }
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(colors.bg)
                .cornerRadius(14.dp)
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            Column(modifier = GlanceModifier.wrapContentWidth(), horizontalAlignment = Alignment.Horizontal.Start) {
                Text(day.label, style = TextStyle(color = colors.fg, fontSize = 15.sp, fontWeight = FontWeight.Bold))
                Spacer(modifier = GlanceModifier.size(1.dp))
                Text(condText, style = TextStyle(color = colors.fg, fontSize = 11.sp))
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            Image(
                provider    = ImageProvider(getIconForCondition(day.condition)),
                contentDescription = day.label,
                colorFilter = ColorFilter.tint(colors.fg),
                modifier    = GlanceModifier.size(30.dp),
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Column(horizontalAlignment = Alignment.Horizontal.CenterHorizontally) {
                Text("${day.hi}°", style = TextStyle(color = colors.fg, fontSize = 19.sp, fontWeight = FontWeight.Bold))
                Text("${day.lo}°", style = TextStyle(color = colors.fg, fontSize = 13.sp))
            }
            if (day.precipPct > 0) {
                Spacer(modifier = GlanceModifier.size(10.dp))
                Text(
                    "${day.precipPct}%",
                    style = TextStyle(
                        color    = if (day.precipPct >= 60) GlanceTheme.colors.error else colors.fg,
                        fontSize = 12.sp,
                    )
                )
            }
        }
    }
}
