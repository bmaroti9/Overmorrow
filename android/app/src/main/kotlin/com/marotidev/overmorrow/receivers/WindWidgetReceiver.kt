package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.WindWidget

class WindWidgetReceiver : HomeWidgetGlanceWidgetReceiver<WindWidget>() {
    override val glanceAppWidget = WindWidget()
}