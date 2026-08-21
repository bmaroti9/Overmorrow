package com.marotidev.overmorrow.receivers

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.UvWidget
class UvWidgetReceiver : HomeWidgetGlanceWidgetReceiver<UvWidget>() {
    override val glanceAppWidget = UvWidget()
}