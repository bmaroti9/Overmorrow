package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.DailyForecastWidget

class DailyForecastWidgetReceiver : HomeWidgetGlanceWidgetReceiver<DailyForecastWidget>() {
    override val glanceAppWidget = DailyForecastWidget()
}
