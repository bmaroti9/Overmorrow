package com.marotidev.overmorrow.receivers

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import com.marotidev.overmorrow.widgets.DateCurrentWidget
class DateCurrentWidgetReceiver : HomeWidgetGlanceWidgetReceiver<DateCurrentWidget>() {
    override val glanceAppWidget = DateCurrentWidget()
}