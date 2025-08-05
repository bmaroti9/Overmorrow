package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.ForecastWidget

class ForecastWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ForecastWidget>() {
    override val glanceAppWidget = ForecastWidget()
}