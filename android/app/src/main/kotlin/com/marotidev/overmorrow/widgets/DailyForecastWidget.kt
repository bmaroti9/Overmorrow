package com.marotidev.overmorrow.widgets

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
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
import androidx.glance.layout.Box
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

// ── JSON helpers ──────────────────────────────────────────────────────────────

private val dfGson = Gson()
private val dfIntListType: Type    = object : TypeToken<List<Int>>() {}.type
private val dfStrListType: Type    = object : TypeToken<List<String>>() {}.type

// ── Constants ─────────────────────────────────────────────────────────────────

private const val MAX_DAYS = 7

// Layout thresholds — all decisions use raw dp from LocalSize, no grid-cell conversion
private val MINIMAL_WIDTH_THRESHOLD  = 160.dp
private val MINIMAL_HEIGHT_THRESHOLD = 130.dp
private val COMPACT_WIDTH_THRESHOLD  = 240.dp
private val COMPACT_QUOTE_MIN_HEIGHT = 240.dp

// Dp-budget estimation for FullLayout card count
private val HEADER_BUDGET   = 92.dp   // icon 50dp + temp ~28dp + hi/lo ~14dp + spacing
private val QUOTE_BUDGET    = 20.dp   // text ~13dp + spacing
private val FRAME_BUDGET    = 26.dp   // outer padding 20dp + header-card gap 6dp
private val CARD_MIN_HEIGHT = 52.dp   // label + condition + vertical padding
private val CARD_GAP        = 4.dp

private val OUTER_V_PAD = 10.dp
private val OUTER_H_PAD = 12.dp

// DayColumn approximate width for compact layout column count
private val DAY_COL_WIDTH = 52.dp

// ── Data Models ───────────────────────────────────────────────────────────────

private data class ForecastDay(
    val label: String,
    val condition: String,
    val hi: Int,
    val lo: Int,
    val precipPct: Int,
    val displayCondition: String = condition.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() },
)

private data class DailyForecastData(
    val placeName: String,
    val location: String,
    val latLon: String,
    val backColorStr: String,
    val frontColorStr: String,
    val quote: String,
    val currentTemp: Int,
    val todayDate: String,
    val days: List<ForecastDay>,
)

// ── Widget ────────────────────────────────────────────────────────────────────

class DailyForecastWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent { GlanceContent(context, currentState(), appWidgetId) }
    }

    // ── Data parsing ─────────────────────────────────────────────────────────

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

    // ── Entry point ──────────────────────────────────────────────────────────

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState, appWidgetId: Int) {
        val data = parseWidgetData(state, appWidgetId)

        val backColor    = getBackColor(data.backColorStr)
        val frontColor   = getFrontColor(data.frontColorStr)
        val onFrontColor = getOnFrontColor(data.frontColorStr)

        val size   = LocalSize.current
        val width  = size.width
        val height = size.height

        val futureDays = (data.days.size - 1).coerceAtLeast(0)
        val hasQuote = data.quote.isNotEmpty()

        val clickAction = actionStartActivity<MainActivity>(
            context,
            "overmorrrow://opened?location=${data.location}&latlon=${data.latLon}".toUri()
        )

        when {
            width < MINIMAL_WIDTH_THRESHOLD || height < MINIMAL_HEIGHT_THRESHOLD -> {
                MinimalLayout(data, frontColor, backColor, height, clickAction)
            }
            width < COMPACT_WIDTH_THRESHOLD -> {
                val availableW = width - 28.dp  // 14dp padding each side
                val dayColCount = (availableW.value / DAY_COL_WIDTH.value).toInt()
                    .coerceIn(0, 5)
                    .coerceAtMost(futureDays)
                val showQuote = hasQuote && height >= COMPACT_QUOTE_MIN_HEIGHT
                CompactLayout(data, frontColor, backColor, dayColCount, showQuote, clickAction)
            }
            else -> {
                val reserved = HEADER_BUDGET + FRAME_BUDGET +
                    (if (hasQuote) QUOTE_BUDGET else 0.dp)
                val availableH = (height - reserved).coerceAtLeast(0.dp)
                val maxCards = (availableH.value / (CARD_MIN_HEIGHT.value + CARD_GAP.value)).toInt()
                    .coerceIn(0, futureDays)
                    .coerceAtMost(MAX_DAYS - 1)
                FullLayout(data, frontColor, backColor, onFrontColor, maxCards, hasQuote, clickAction)
            }
        }
    }

    // ── MinimalLayout ────────────────────────────────────────────────────────

    @Composable
    private fun MinimalLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        height: Dp,
        clickAction: androidx.glance.action.Action,
    ) {
        val today = data.days.firstOrNull()
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .cornerRadius(24.dp)
                .padding(8.dp)
                .clickable(onClick = clickAction),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.Horizontal.CenterHorizontally) {
                if (today != null) {
                    Image(
                        provider    = ImageProvider(getIconForCondition(today.condition)),
                        contentDescription = "Today",
                        colorFilter = ColorFilter.tint(frontColor),
                        modifier    = GlanceModifier.size(40.dp),
                    )
                }
                Spacer(modifier = GlanceModifier.size(4.dp))
                Text(
                    "${data.currentTemp}°",
                    style = TextStyle(color = frontColor, fontSize = 24.sp, fontWeight = FontWeight.Bold),
                )
                Text(
                    "${today?.hi ?: 0}° / ${today?.lo ?: 0}°",
                    style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp),
                )
                if (height >= 100.dp) {
                    Spacer(modifier = GlanceModifier.size(2.dp))
                    Text(
                        data.placeName,
                        style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp),
                    )
                }
            }
        }
    }

    // ── CompactLayout ────────────────────────────────────────────────────────

    @Composable
    private fun CompactLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        dayColCount: Int,
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
            val today = data.days.firstOrNull()

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.Vertical.CenterVertically,
            ) {
                if (today != null) {
                    Image(
                        provider    = ImageProvider(getIconForCondition(today.condition)),
                        contentDescription = "Today",
                        colorFilter = ColorFilter.tint(frontColor),
                        modifier    = GlanceModifier.size(44.dp),
                    )
                }
                Spacer(modifier = GlanceModifier.size(8.dp))
                Column(modifier = GlanceModifier.wrapContentWidth()) {
                    Text(
                        "${data.currentTemp}°",
                        style = TextStyle(color = frontColor, fontSize = 22.sp, fontWeight = FontWeight.Bold),
                    )
                    Text(
                        "${today?.hi ?: 0}° / ${today?.lo ?: 0}°",
                        style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp),
                    )
                }
                Spacer(modifier = GlanceModifier.defaultWeight())
                Column(
                    modifier = GlanceModifier.wrapContentWidth(),
                    horizontalAlignment = Alignment.Horizontal.End,
                ) {
                    if (data.todayDate.isNotEmpty()) {
                        Text(data.todayDate, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp))
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

            if (dayColCount > 0) {
                Spacer(modifier = GlanceModifier.size(8.dp))
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                ) {
                    val safeCount = minOf(dayColCount, (data.days.size - 1).coerceAtLeast(0))
                    for (i in 1..safeCount) {
                        if (i > 1) Spacer(modifier = GlanceModifier.size(8.dp))
                        DayColumn(frontColor, data.days, i)
                    }
                }
            }

            if (showQuote) {
                Spacer(modifier = GlanceModifier.size(4.dp))
                QuoteText(data.quote, fontSize = 10)
            }
        }
    }

    // ── FullLayout ───────────────────────────────────────────────────────────

    @Composable
    private fun FullLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        onFrontColor: ColorProvider,
        maxCards: Int,
        showQuote: Boolean,
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
            HeaderRow(frontColor, data)

            Spacer(modifier = GlanceModifier.size(6.dp))

            data.days.drop(1).take(maxCards).forEachIndexed { i, day ->
                if (i > 0) Spacer(modifier = GlanceModifier.size(CARD_GAP))
                DayCard(frontColor, onFrontColor, day, modifier = GlanceModifier.fillMaxWidth())
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            if (showQuote) {
                Spacer(modifier = GlanceModifier.size(4.dp))
                QuoteText(data.quote, fontSize = 11)
            }
        }
    }

    // ── Sub-composables ──────────────────────────────────────────────────────

    @Composable
    private fun QuoteText(quote: String, fontSize: Int) {
        Text(
            text  = "\"$quote\"",
            style = TextStyle(color = GlanceTheme.colors.outline, fontSize = fontSize.sp),
            modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp),
        )
    }

    @Composable
    private fun HeaderRow(frontColor: ColorProvider, data: DailyForecastData) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().wrapContentHeight(),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            val today = data.days.firstOrNull()
            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.Start,
            ) {
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

            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.End,
            ) {
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
            }
        }
    }

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
