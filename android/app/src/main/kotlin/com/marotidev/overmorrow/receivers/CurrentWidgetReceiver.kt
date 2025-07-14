package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.CurrentWidget

class CurrentWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CurrentWidget>() {
    override val glanceAppWidget = CurrentWidget()
}