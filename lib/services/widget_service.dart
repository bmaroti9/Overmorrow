/*
Copyright (C) <2026>  <Balint Maroti>

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

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:overmorrow/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../decoders/weather_data.dart';
import '../main_ui.dart';
import 'weather_service.dart';

const updateWeatherDataKey = "com.marotidev.overmorrow.updateWeatherData";

const currentWidgetReceiver = 'com.marotidev.overmorrow.receivers.CurrentWidgetReceiver';
const dateCurrentWidgetReceiver = 'com.marotidev.overmorrow.receivers.DateCurrentWidgetReceiver';
const windWidgetReceiver = 'com.marotidev.overmorrow.receivers.WindWidgetReceiver';
const uvWidgetReceiver = 'com.marotidev.overmorrow.receivers.UvWidgetReceiver';
const forecastWidgetReceiver = 'com.marotidev.overmorrow.receivers.ForecastWidgetReceiver';
const oneHourlyWidgetReceiver = 'com.marotidev.overmorrow.receivers.OneHourlyWidgetReceiver';
const dailyForecastWidgetReceiver = 'com.marotidev.overmorrow.receivers.DailyForecastWidgetReceiver';

void initializeWidgetServices() {
  Workmanager().initialize(
      myCallbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: kDebugMode // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  HomeWidget.registerInteractivityCallback(interactiveCallback);

  if (kDebugMode) {
    print("thissssssssssssssssssssssssssssssssss");
    Workmanager().registerOneOffTask("test_task_${DateTime.now().millisecondsSinceEpoch}", updateWeatherDataKey);
  }

  Workmanager().registerPeriodicTask(
    "updateWeatherWidget",
    updateWeatherDataKey,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected, requiresBatteryNotLow: true),
  );
}

class WidgetService {

  static Future<void> saveData(String id, value) async {
    await HomeWidget.saveWidgetData(id, value);
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

  static Future<void> syncUvDataToWidget(LightUvData data, int widgetId) async {
    await saveData("uv.uv.$widgetId", data.uv);
  }

  // TODO: migrate quotes to l10n system so they can be translated per locale
  static const List<String> _shakespeareQuotes = [
    "To be, or not to be, that is the question.",
    "All the world's a stage, and all the men and women merely players.",
    "What's in a name? That which we call a rose by any other name would smell as sweet.",
    "We know what we are, but know not what we may be.",
    "The course of true love never did run smooth.",
    "This above all: to thine own self be true.",
    "brevity is the soul of wit.",
    "All that glitters is not gold.",
    "Good night, good night! Parting is such sweet sorrow.",
    "If music be the food of love, play on.",
    "Cowards die many times before their deaths; the valiant never taste of death but once.",
    "There is nothing either good or bad, but thinking makes it so.",
    "We are such stuff as dreams are made on.",
  ];

  static Future<void> syncDailyForecastDataToWidget(LightDailyForecastData data, int widgetId) async {
    await saveData("dailyForecast.currentTemp.$widgetId", data.currentTemp);
    await saveData("dailyForecast.dailyHighTemps.$widgetId", data.dailyHighTemps);
    await saveData("dailyForecast.dailyLowTemps.$widgetId", data.dailyLowTemps);
    await saveData("dailyForecast.dailyConditions.$widgetId", data.dailyConditions);
    await saveData("dailyForecast.dailyNames.$widgetId", data.dailyNames);
    await saveData("dailyForecast.dailyPrecipProbs.$widgetId", data.dailyPrecipProbs);
    await saveData("widget.place.$widgetId", data.place);
    // Today's date label e.g. "Tue, Mar 31"
    final todayLabel = DateFormat('EEE, MMM d').format(DateTime.now());
    await saveData("dailyForecast.todayDate.$widgetId", todayLabel);
    // Rotate Shakespeare quote on each update
    final quoteIndex = (widgetId + DateTime.now().day) % _shakespeareQuotes.length;
    await saveData("widget.quote.$widgetId", _shakespeareQuotes[quoteIndex]);
  }

  static Future<void> syncHourlyForecastDataToWidget(LightHourlyForecastData data, int widgetId) async {
    await saveData("hourlyForecast.currentTemp.$widgetId", data.currentTemp);
    await saveData("hourlyForecast.currentCondition.$widgetId", data.currentCondition);
    await saveData("hourlyForecast.updatedTime.$widgetId", data.updatedTime);

    await saveData("hourlyForecast.hourly6Temps.$widgetId", data.hourly6Temps);
    await saveData("hourlyForecast.hourly6Conditions.$widgetId", data.hourly6Conditions);
    await saveData("hourlyForecast.hourly6Names.$widgetId", data.hourly6Names);

    await saveData("hourlyForecast.hourly1Temps.$widgetId", data.hourly1Temps);
    await saveData("hourlyForecast.hourly1Conditions.$widgetId", data.hourly1Conditions);
    await saveData("hourlyForecast.hourly1Names.$widgetId", data.hourly1Names);

    await saveData("widget.place.$widgetId", data.place);
  }

  static void logUpdateTime(SharedPreferences prefs) {

    List<String> timeLog = prefs.getStringList("backgroundUpdateLog") ?? [];

    String timeString = DateTime.now().toString();
    timeLog.add(timeString);
    if (timeLog.length > 30) {
      timeLog.removeAt(0);
    }

    print(("timelog", timeLog));
    prefs.setStringList("backgroundUpdateLog", timeLog);
  }

  static Future<void> saveBackgroundTaskState(String state) async {
    await saveData("widget.backgroundUpdateState", state);
  }

  static int _getHourFromLabel(String label) {
    if (label.endsWith('h')) {
      return int.tryParse(label.substring(0, label.length - 1)) ?? 0;
    }
    try {
      return DateFormat('ha').parse(label.toUpperCase()).hour;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> updateWidgetTimeFormat(String timeMode) async {
    final installedWidgets = await HomeWidget.getInstalledWidgets();
    for (final widgetInfo in installedWidgets.where((w) =>
        w.androidClassName == forecastWidgetReceiver ||
        w.androidClassName == oneHourlyWidgetReceiver)) {
      final id = widgetInfo.androidWidgetId!;
      for (final prefix in ['hourly6', 'hourly1']) {
        final key = 'hourlyForecast.${prefix}Names.$id';
        final stored = await HomeWidget.getWidgetData<String>(key);
        if (stored == null) continue;
        final formattedLabels = (jsonDecode(stored) as List).cast<String>()
            .map((label) => formatHourByTimeMode(DateTime(0, 1, 1, _getHourFromLabel(label)), timeMode))
            .toList();
        await saveData(key, jsonEncode(formattedLabels));
      }
    }
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
    HomeWidget.updateWidget(
      androidName: 'OneHourlyWidget',
      qualifiedAndroidName: oneHourlyWidgetReceiver,
    );
    HomeWidget.updateWidget(
      androidName: 'UvWidget',
      qualifiedAndroidName: uvWidgetReceiver,
    );
    HomeWidget.updateWidget(
      androidName: 'DailyForecastWidget',
      qualifiedAndroidName: dailyForecastWidgetReceiver,
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

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    switch (task) {
      case updateWeatherDataKey :

        try {
          print("HEEEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRRRRRRRREEEEEEEEEEEEEEEEEEE");

          //--------------------NOTIFICATIONS--------------------

          if (prefs.getBool("Ongoing notification") ?? false) {
            await NotificationService().updateOngoingNotification(prefs);
          }

          //--------------------WIDGETS--------------------------

          final List<HomeWidgetInfo> installedWidgets = await HomeWidget.getInstalledWidgets();

          if (installedWidgets.isEmpty) {
            if (prefs.getBool("Ongoing notification") ?? false) {
              WidgetService.saveBackgroundTaskState("WORKER RESULT SUCCESS AT ${DateTime.now()} \nONGOING NOTIFICATION");
              WidgetService.logUpdateTime(prefs);
            }
            else {
              print("no widgets installed, skipping update");
              WidgetService.saveBackgroundTaskState("WORKER RESULT SUCCESS AT ${DateTime.now()} \nNO WIDGETS INSTALLED");
            }
            return Future.value(true);
          }

          for (HomeWidgetInfo widgetInfo in installedWidgets) {
            final int widgetId = widgetInfo.androidWidgetId!;
            final String widgetClassName = widgetInfo.androidClassName!;
            print(("classname", widgetClassName));
            print("DEBUG: Processing widget with ID=$widgetId, className=$widgetClassName");

            final String locationKey = "widget.location.$widgetId";
            final String latLonKey = "widget.latLon.$widgetId";
            final String providerKey = "widget.provider.$widgetId";

            final String widgetLocation = (await HomeWidget.getWidgetData<String>(locationKey, defaultValue: "unknown")) ?? "unknown";
            final String widgetProvider = (await HomeWidget.getWidgetData<String>(providerKey, defaultValue: "unknown")) ?? "unknown";

            if (widgetLocation == "unknown") continue;

            String placeName;
            String latLon;

            if (widgetLocation == "CurrentLocation") {
              placeName = prefs.getString('LastKnownPositionName') ?? 'unknown';
              latLon = prefs.getString('LastKnownPositionCord') ?? 'unknown';
            }
            else {
              placeName = widgetLocation;
              latLon = (await HomeWidget.getWidgetData<String>(latLonKey, defaultValue: "unknown")) ?? "unknown";
            }

            //these two are so similar that i'm updating them with the same logic
            if (widgetClassName == currentWidgetReceiver || widgetClassName == dateCurrentWidgetReceiver) {

              LightCurrentWeatherData data = await LightCurrentWeatherData
                  .getLightCurrentWeatherData(placeName, latLon, widgetProvider, prefs);

              await WidgetService.syncCurrentDataToWidget(data, widgetId);
            }
            else if (widgetClassName == windWidgetReceiver) {

              LightWindData data = await LightWindData
                  .getLightWindData(placeName, latLon, widgetProvider, prefs);

              await WidgetService.syncWindDataToWidget(data, widgetId);
            }
            else if (widgetClassName == forecastWidgetReceiver || widgetClassName == oneHourlyWidgetReceiver) {

              LightHourlyForecastData data = await LightHourlyForecastData
                  .getLightForecastData(placeName, latLon, widgetProvider, prefs);

              await WidgetService.syncHourlyForecastDataToWidget(data, widgetId);
            } else if (widgetClassName == uvWidgetReceiver) {

              LightUvData data = await LightUvData.getLightUvData(placeName, latLon, widgetProvider, prefs);

              await WidgetService.syncUvDataToWidget(data, widgetId);
            } else if (widgetClassName == dailyForecastWidgetReceiver) {
              LightDailyForecastData data = await LightDailyForecastData
                  .getLightDailyData(placeName, latLon, widgetProvider, prefs);

              await WidgetService.syncDailyForecastDataToWidget(data, widgetId);
            }

          }

          WidgetService.reloadWidgets();

        } catch (err, stacktrace) {
          if (kDebugMode) {
            print("ERRRRRRRRRRRRRRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOOOOOOORRRRRRRRRRRRRRRRRRRRRR");
            print((err, stacktrace));
          }
          String e = sanitizeErrorMessage(err.toString());
          WidgetService.saveBackgroundTaskState("WORKER RESULT FAILURE AT ${DateTime.now()} \n $e");
          return Future.value(false);
        }
    }

    WidgetService.saveBackgroundTaskState("WORKER RESULT SUCCESS AT ${DateTime.now()}");
    WidgetService.logUpdateTime(prefs);
    return Future.value(true);
  });
}