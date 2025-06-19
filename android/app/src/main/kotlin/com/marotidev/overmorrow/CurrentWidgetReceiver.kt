package com.marotidev.overmorrow

import HomeWidgetGlanceWidgetReceiver

class CurrentWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CurrentWidget>() {
    override val glanceAppWidget = CurrentWidget()
}