package com.marotidev.overmorrow.receivers

import HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.DateCurrentWidget

class DateCurrentWidgetReceiver : HomeWidgetGlanceWidgetReceiver<DateCurrentWidget>() {
    override val glanceAppWidget = DateCurrentWidget()
}