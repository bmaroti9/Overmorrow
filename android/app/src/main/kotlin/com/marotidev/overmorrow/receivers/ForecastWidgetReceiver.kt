package com.marotidev.overmorrow.receivers

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.ForecastWidget
class ForecastWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ForecastWidget>() {
    override val glanceAppWidget = ForecastWidget()
}