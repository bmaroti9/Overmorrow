package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.UvWidget

class UvWidgetReceiver : HomeWidgetGlanceWidgetReceiver<UvWidget>() {
    override val glanceAppWidget = UvWidget()
}