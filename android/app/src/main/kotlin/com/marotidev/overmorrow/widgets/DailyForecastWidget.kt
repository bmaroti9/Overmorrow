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
private val dfIntListType: Type  = object : TypeToken<List<Int>>() {}.type
private val dfStrListType: Type  = object : TypeToken<List<String>>() {}.type

// ── Data models ───────────────────────────────────────────────────────────────

private data class ForecastDay(
    val label: String,
    val condition: String,
    val hi: Int,
    val lo: Int,
    val precipPct: Int,
) {
    val displayCondition: String by lazy {
        condition.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() }
    }
}

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

// ── Layout tier — extensible via sealed interface ─────────────────────────────

private sealed interface LayoutTier {
    data class Minimal(val showPlace: Boolean) : LayoutTier
    data class Compact(val dayColumns: Int, val showQuote: Boolean) : LayoutTier
    data class Full(val cardCount: Int, val showQuote: Boolean) : LayoutTier

    companion object {
        fun resolve(width: Dp, height: Dp, futureDays: Int, hasQuote: Boolean): LayoutTier {
            if (width < Spec.minWidth || height < Spec.minHeight) {
                return Minimal(showPlace = height >= 100.dp)
            }
            if (width < Spec.compactMaxWidth) {
                val available = width - 28.dp
                val cols = (available.value / Spec.dayColWidth.value).toInt()
                    .coerceIn(0, 5).coerceAtMost(futureDays)
                return Compact(cols, showQuote = hasQuote && height >= Spec.compactQuoteMinHeight)
            }
            val reserved = Spec.headerBudget + Spec.frameBudget +
                (if (hasQuote) Spec.quoteBudget else 0.dp)
            val available = (height - reserved).coerceAtLeast(0.dp)
            val cards = (available.value / (Spec.cardMinHeight.value + Spec.cardGap.value)).toInt()
                .coerceIn(0, futureDays).coerceAtMost(MAX_DAYS - 1)
            return Full(cards, showQuote = hasQuote)
        }
    }
}

private object Spec {
    val minWidth          = 160.dp
    val minHeight         = 130.dp
    val compactMaxWidth   = 240.dp
    val compactQuoteMinHeight = 240.dp

    val headerBudget  = 92.dp
    val quoteBudget   = 20.dp
    val frameBudget   = 26.dp
    val cardMinHeight = 52.dp
    val cardGap       = 4.dp
    val dayColWidth   = 52.dp

    val outerPadV = 10.dp
    val outerPadH = 12.dp

    const val highPrecipThreshold = 60
}

private const val MAX_DAYS = 7

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

        fun str(key: String, def: String = "") = p.getString("$key.$id", def) ?: def
        fun int(key: String, def: Int = 0)     = p.getInt("$key.$id", def)
        fun <T> json(raw: String, type: Type): List<T> =
            try { dfGson.fromJson<List<T>>(raw, type) ?: emptyList() } catch (_: Exception) { emptyList() }

        val highs:  List<Int>    = json(str("dailyForecast.dailyHighTemps",   "[]"), dfIntListType)
        val lows:   List<Int>    = json(str("dailyForecast.dailyLowTemps",    "[]"), dfIntListType)
        val conds:  List<String> = json(str("dailyForecast.dailyConditions",  "[]"), dfStrListType)
        val names:  List<String> = json(str("dailyForecast.dailyNames",       "[]"), dfStrListType)
        val precip: List<Int>    = json(str("dailyForecast.dailyPrecipProbs", "[]"), dfIntListType)

        val count = minOf(names.size, highs.size, lows.size, conds.size, precip.size, MAX_DAYS)
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
            placeName     = str("widget.place",      "—"),
            location      = str("widget.location",   "--"),
            latLon        = str("widget.latLon",     "--"),
            backColorStr  = str("widget.backColor",  "secondary container"),
            frontColorStr = str("widget.frontColor", "primary"),
            quote         = str("widget.quote",      ""),
            currentTemp   = int("dailyForecast.currentTemp"),
            todayDate     = str("dailyForecast.todayDate", ""),
            days          = days,
        )
    }

    // ── Entry point ──────────────────────────────────────────────────────────

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState, appWidgetId: Int) {
        val data = parseWidgetData(state, appWidgetId)

        val backColor    = getBackColor(data.backColorStr)
        val frontColor   = getFrontColor(data.frontColorStr)
        val onFrontColor = getOnFrontColor(data.frontColorStr)

        val size = LocalSize.current
        val futureDays = (data.days.size - 1).coerceAtLeast(0)
        val tier = LayoutTier.resolve(size.width, size.height, futureDays, data.quote.isNotEmpty())

        val clickAction = actionStartActivity<MainActivity>(
            context,
            "overmorrrow://opened?location=${data.location}&latlon=${data.latLon}".toUri()
        )

        when (tier) {
            is LayoutTier.Minimal -> MinimalLayout(data, frontColor, backColor, tier, clickAction)
            is LayoutTier.Compact -> CompactLayout(data, frontColor, backColor, tier, clickAction)
            is LayoutTier.Full    -> FullLayout(data, frontColor, backColor, onFrontColor, tier, clickAction)
        }
    }

    // ── MinimalLayout ────────────────────────────────────────────────────────

    @Composable
    private fun MinimalLayout(
        data: DailyForecastData,
        frontColor: ColorProvider,
        backColor: ColorProvider,
        tier: LayoutTier.Minimal,
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
                    "${today?.hi ?: "—"}° / ${today?.lo ?: "—"}°",
                    style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp),
                )
                if (tier.showPlace) {
                    Spacer(modifier = GlanceModifier.size(2.dp))
                    Text(
                        data.placeName,
                        style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp),
                        maxLines = 1,
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
        tier: LayoutTier.Compact,
        clickAction: androidx.glance.action.Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .cornerRadius(24.dp)
                .padding(horizontal = 14.dp, vertical = 12.dp)
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
                        "${today?.hi ?: "—"}° / ${today?.lo ?: "—"}°",
                        style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp),
                    )
                }
                Spacer(modifier = GlanceModifier.defaultWeight())
                Column(
                    modifier = GlanceModifier.wrapContentWidth(),
                    horizontalAlignment = Alignment.Horizontal.End,
                ) {
                    if (data.todayDate.isNotEmpty()) {
                        Text(data.todayDate, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp), maxLines = 1)
                    }
                    LocationRow(tintColor = GlanceTheme.colors.outline, name = data.placeName, iconSize = 11.dp, fontSize = 10)
                }
            }

            if (tier.dayColumns > 0) {
                Spacer(modifier = GlanceModifier.size(8.dp))
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                ) {
                    val safeCount = minOf(tier.dayColumns, (data.days.size - 1).coerceAtLeast(0))
                    for (i in 1..safeCount) {
                        if (i > 1) Spacer(modifier = GlanceModifier.size(8.dp))
                        DayColumn(frontColor, data.days, i)
                    }
                }
            }

            if (tier.showQuote) {
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
        tier: LayoutTier.Full,
        clickAction: androidx.glance.action.Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(backColor)
                .cornerRadius(24.dp)
                .padding(horizontal = Spec.outerPadH, vertical = Spec.outerPadV)
                .clickable(onClick = clickAction),
        ) {
            HeaderRow(frontColor, data)

            Spacer(modifier = GlanceModifier.size(6.dp))

            data.days.drop(1).take(tier.cardCount).forEachIndexed { i, day ->
                if (i > 0) Spacer(modifier = GlanceModifier.size(Spec.cardGap))
                DayCard(frontColor, onFrontColor, day, modifier = GlanceModifier.fillMaxWidth())
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            if (tier.showQuote) {
                Spacer(modifier = GlanceModifier.size(4.dp))
                QuoteText(data.quote, fontSize = 11)
            }
        }
    }

    // ── Shared composables ───────────────────────────────────────────────────

    @Composable
    private fun QuoteText(quote: String, fontSize: Int) {
        Text(
            text  = "\"$quote\"",
            style = TextStyle(color = GlanceTheme.colors.outline, fontSize = fontSize.sp),
            modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp),
            maxLines = 2,
        )
    }

    @Composable
    private fun LocationRow(tintColor: ColorProvider, name: String, iconSize: Dp, fontSize: Int) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Image(
                provider    = ImageProvider(R.drawable.icon_location),
                contentDescription = "Location",
                colorFilter = ColorFilter.tint(tintColor),
                modifier    = GlanceModifier.size(iconSize).padding(end = 2.dp),
            )
            Text(name, style = TextStyle(color = tintColor, fontSize = fontSize.sp), maxLines = 1)
        }
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
                Text(
                    "${data.currentTemp}°",
                    style = TextStyle(color = frontColor, fontSize = 28.sp, fontWeight = FontWeight.Bold),
                )
                Text(
                    "${today?.hi ?: "—"}° / ${today?.lo ?: "—"}°",
                    style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 12.sp),
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            Column(
                modifier = GlanceModifier.wrapContentWidth(),
                horizontalAlignment = Alignment.Horizontal.End,
            ) {
                if (data.todayDate.isNotEmpty()) {
                    Text(data.todayDate, style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 11.sp), maxLines = 1)
                    Spacer(modifier = GlanceModifier.size(2.dp))
                }
                LocationRow(tintColor = GlanceTheme.colors.outline, name = data.placeName, iconSize = 12.dp, fontSize = 12)
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
                        color    = if (day.precipPct >= Spec.highPrecipThreshold) GlanceTheme.colors.error else GlanceTheme.colors.outline,
                        fontSize = 10.sp,
                    ),
                )
            }
        }
    }

    @Composable
    private fun DayCard(
        frontColor: ColorProvider,
        onFrontColor: ColorProvider,
        day: ForecastDay,
        modifier: GlanceModifier = GlanceModifier,
    ) {
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
                Text(day.displayCondition, style = TextStyle(color = onFrontColor, fontSize = 11.sp), maxLines = 1)
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
                        color    = if (day.precipPct >= Spec.highPrecipThreshold) GlanceTheme.colors.error else onFrontColor,
                        fontSize = 12.sp,
                    ),
                )
            }
        }
    }
}
