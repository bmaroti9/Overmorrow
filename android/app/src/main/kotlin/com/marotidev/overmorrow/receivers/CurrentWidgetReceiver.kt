package com.marotidev.overmorrow.receivers

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.CurrentWidget

class CurrentWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CurrentWidget>() {
    override val glanceAppWidget = CurrentWidget()
}