package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.ForecastWidget
import com.marotidev.overmorrow.widgets.OneHourlyWidget

class OneHourlyWidgetReceiver : HomeWidgetGlanceWidgetReceiver<OneHourlyWidget>() {
    override val glanceAppWidget = OneHourlyWidget()
}