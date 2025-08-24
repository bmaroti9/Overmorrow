/*
Copyright (C) <2025>  <Balint Maroti>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../decoders/weather_data.dart';
import '../main_ui.dart';
import '../settings_page.dart';

const updateWeatherDataKey = "com.marotidev.overmorrow.updateWeatherData";

const currentWidgetReceiver = 'com.marotidev.overmorrow.receivers.CurrentWidgetReceiver';
const dateCurrentWidgetReceiver = 'com.marotidev.overmorrow.receivers.DateCurrentWidgetReceiver';
const windWidgetReceiver = 'com.marotidev.overmorrow.receivers.WindWidgetReceiver';
const forecastWidgetReceiver = 'com.marotidev.overmorrow.receivers.ForecastWidgetReceiver';

class WidgetService {

  static Future<void> saveData(String id, value) async {
    await HomeWidget.saveWidgetData(id, value);
    print(("Saved", id, value));
  }

  static Future<void> syncCurrentDataToWidget(LightCurrentWeatherData data, int widgetId) async {
    await saveData("current.temp.$widgetId", data.temp);
    await saveData("current.condition.$widgetId", data.condition);
    await saveData("current.updatedTime.$widgetId", data.updatedTime);
    await saveData("current.date.$widgetId", data.dateString);

    await saveData("widget.place.$widgetId", data.place);
    //place is the name of the city while location can include currentLocation
  }

  static Future<void> syncWindDataToWidget(LightWindData data, int widgetId) async {
    await saveData("wind.windSpeed.$widgetId", data.windSpeed);
    await saveData("wind.windDirAngle.$widgetId", data.windDirAngle);
    await saveData("wind.windUnit.$widgetId", data.windUnit);
  }

  static Future<void> syncHourlyForecastDataToWidget(LightHourlyForecastData data, int widgetId) async {
    await saveData("hourlyForecast.currentTemp.$widgetId", data.currentTemp);
    await saveData("hourlyForecast.currentCondition.$widgetId", data.currentCondition);
    await saveData("hourlyForecast.updatedTime.$widgetId", data.updatedTime);

    await saveData("hourlyForecast.hourlyTemps.$widgetId", data.hourlyTemps);
    await saveData("hourlyForecast.hourlyConditions.$widgetId", data.hourlyConditions);
    await saveData("hourlyForecast.hourlyNames.$widgetId", data.hourlyNames);

    await saveData("widget.place.$widgetId", data.place);
  }

  static Future<void> saveBackgroundTaskState(String state) async {
    await saveData("widget.backgroundUpdateState", state);
  }

  static Future<void> reloadWidgets() async {
    HomeWidget.updateWidget(
      androidName: 'CurrentWidget',
      qualifiedAndroidName: currentWidgetReceiver,
    );
    HomeWidget.updateWidget(
      androidName: 'DateCurrentWidget',
      qualifiedAndroidName: dateCurrentWidgetReceiver,
    );
    HomeWidget.updateWidget(
      androidName: 'WindWidget',
      qualifiedAndroidName: windWidgetReceiver,
    );
    HomeWidget.updateWidget(
      androidName: 'ForecastWidget',
      qualifiedAndroidName: forecastWidgetReceiver,
    );
  }
}

//this is the best solution i found to trigger an update of the data after the preferences have been changed
@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  print("INTERACTIVE CALLBACK, ${uri.toString()}");
  if (uri?.host == 'update') {
    await Workmanager().registerOneOffTask(
        "test_task_${DateTime.now().millisecondsSinceEpoch}", updateWeatherDataKey);
  }
}

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void myCallbackDispatcher() {

  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task"); //simpleTask will be emitted here.

    switch (task) {
      case updateWeatherDataKey :

        try {
          print("HEEEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRRRRRRRREEEEEEEEEEEEEEEEEEE");

          final List<HomeWidgetInfo> installedWidgets = await HomeWidget.getInstalledWidgets();

          if (installedWidgets.isEmpty) {
            print("no widgets installed, skipping update");
            return Future.value(true);
          }

          Map<String, String> settings = await getSettingsUsed();

          for (HomeWidgetInfo widgetInfo in installedWidgets) {
            final int widgetId = widgetInfo.androidWidgetId!;
            final String widgetClassName = widgetInfo.androidClassName!;
            print(("classname", widgetClassName));

            final String locationKey = "widget.location.$widgetId";
            final String latLonKey = "widget.latLon.$widgetId";
            final String providerKey = "widget.provider.$widgetId";

            final String widgetLocation = (await HomeWidget.getWidgetData<String>(locationKey, defaultValue: "unknown")) ?? "unknown";
            final String widgetProvider = (await HomeWidget.getWidgetData<String>(providerKey, defaultValue: "unknown")) ?? "unknown";

            if (widgetLocation == "unknown") continue;

            String placeName;
            String latLon;

            if (widgetLocation == "CurrentLocation") {
              List<String> lastKnown = await getLastKnownLocation();
              placeName = lastKnown[0];
              latLon = lastKnown[1];
            }
            else {
              placeName = widgetLocation;
              latLon = (await HomeWidget.getWidgetData<String>(latLonKey, defaultValue: "unknown")) ?? "unknown";
            }

            //these two are so similar that i'm updating them with the same logic
            if (widgetClassName == currentWidgetReceiver || widgetClassName == dateCurrentWidgetReceiver) {

              LightCurrentWeatherData data = await LightCurrentWeatherData
                  .getLightCurrentWeatherData(placeName, latLon, widgetProvider, settings);

              await WidgetService.syncCurrentDataToWidget(data, widgetId);
            }
            else if (widgetClassName == windWidgetReceiver) {

              LightWindData data = await LightWindData
                  .getLightWindData(placeName, latLon, widgetProvider, settings);

              await WidgetService.syncWindDataToWidget(data, widgetId);
            }
            else if (widgetClassName == forecastWidgetReceiver) {

              LightHourlyForecastData data = await LightHourlyForecastData
                  .getLightForecastData(placeName, latLon, widgetProvider, settings);

              await WidgetService.syncHourlyForecastDataToWidget(data, widgetId);
            }

          }

          WidgetService.reloadWidgets();

        } catch (err, stacktrace) {
          if (kDebugMode) {
            print("ERRRRRRRRRRRRRRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOOOOOOORRRRRRRRRRRRRRRRRRRRRR");
            print((err, stacktrace));
          }
          String e = sanitizeErrorMessage(err.toString());
          WidgetService.saveBackgroundTaskState(e.toString());
          return Future.value(false);
        }
    }

    WidgetService.saveBackgroundTaskState("WORKER RESULT SUCCESS AT ${DateTime.now()}");
    return Future.value(true);
  });
}