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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:overmorrow/services/location_service.dart';
import 'package:workmanager/workmanager.dart';
import 'caching.dart';
import 'decoders/extra_info.dart';
import 'main_ui.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

import 'settings_page.dart';

const updateWeatherDataKey = "com.marotidev.overmorrow.updateWeatherData";

class WidgetService {

  static Future<void> saveData(String id, value) async {
    await HomeWidget.saveWidgetData(id, value);
  }

  static Future<void> syncCurrentDataToWidget(LightCurrentWeatherData weatherData, int widgetId) async {
    await saveData("widgetFailure.$widgetId", "enabled");

    await saveData("current.temp.$widgetId", weatherData.temp);
    await saveData("current.condition.$widgetId", weatherData.condition);
    await saveData("current.updatedTime.$widgetId", weatherData.updatedTime);
  }

  static Future<void> syncWidgetFailure(int widgetId, String failure) async {
    await saveData("widgetFailure.$widgetId", failure);
  }

  static Future<void> reloadCurrentWidgets() async {
    await HomeWidget.updateWidget(
      androidName: 'CurrentWidget',
      qualifiedAndroidName: 'com.marotidev.overmorrow.CurrentWidgetReceiver',
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
void callbackDispatcher() {

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

          for (HomeWidgetInfo widgetInfo in installedWidgets) {
            final int widgetId = widgetInfo.androidWidgetId!;

            final String locationKey = "current.location.$widgetId";
            final String latLonKey = "current.latLon.$widgetId";

            final String widgetLocation = (await HomeWidget.getWidgetData<String>(locationKey, defaultValue: "unknown")) ?? "unknown";
            final String widgetLatLon = (await HomeWidget.getWidgetData<String>(latLonKey, defaultValue: "unknown")) ?? "unknown";

            print((widgetId, widgetLocation, widgetLatLon));

            final LightCurrentWeatherData weatherData = await LightCurrentWeatherData.
            getLightCurrentWeatherData(widgetLocation, widgetLatLon);

            print((weatherData.condition));

            await WidgetService.syncCurrentDataToWidget(weatherData, widgetId);
          }

          WidgetService.reloadCurrentWidgets();



        } catch (e, stacktrace) {
          print("ERRRRRRRRRRRRRRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOOOOOOORRRRRRRRRRRRRRRRRRRRRR");
          print((e, stacktrace));
          return Future.value(false);
        }
    }

    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: kDebugMode // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  HomeWidget.registerInteractivityCallback(interactiveCallback);

  print("thissssssssssssssssssssssssssssssssss");
  Workmanager().registerOneOffTask("test_task_${DateTime.now().millisecondsSinceEpoch}", updateWeatherDataKey);

  Workmanager().registerPeriodicTask(
    "updateWeatherWidget",
    updateWeatherDataKey,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected, requiresBatteryNotLow: true),
  );

  final data = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  if (data.shortestSide / ratio < 600) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((value) => runApp(const MyApp()));
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();

    setPreferedLocale();
  }

  void setPreferedLocale() async {
    String loc = await getLanguageUsed();
    Locale to = languageNameToLocale[loc] ?? const Locale('en');

    setState(() {
      _locale = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets systemGestureInsets = MediaQuery.of(context).systemGestureInsets;
    if (systemGestureInsets.left > 0) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    // I have no idea why this works but thank you to https://stackoverflow.com/a/72754385
    return MaterialApp(
      locale: _locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(key: Key(_locale.toString()),),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _sanitizePlaceName(String input) {
    final safe = input.replaceAll(RegExp(r'[^\w\s\-,]'), '').trim();
    if (safe.isEmpty) return ''; // Handle empty input after sanitization
    return safe.length > 100 ? safe.substring(0, 100) : safe;
  }

  Future<Widget> getDays(bool recall, proposedLoc, backupName, startup) async {
    try {

      AppLocalizations localizations = AppLocalizations.of(context)!;

      Map<String, String> settings = await getSettingsUsed();
      String weatherProvider = await getWeatherProvider();
      backupName = _sanitizePlaceName(backupName);

      if (startup) {
        List<String> n = await getLastPlace();  //loads the last place you visited
        proposedLoc = n[1];
        backupName = n[0];
        startup = false;
      }

      String absoluteProposed = proposedLoc;
      bool isItCurrentLocation = false;

      if (backupName == 'CurrentLocation') {
        String loc_status = await isLocationSafe(localizations);
        if (loc_status == "enabled") {
          Position position;
          try {
            position = await Geolocator.getCurrentPosition(
                locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium,
                    timeLimit: const Duration(seconds: 3)
                )
            );
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return ErrorPage(errorMessage: localizations.unableToLocateDevice,
                  updateLocation: updateLocation,
                  icon: Icons.gps_off,
                  place: backupName,
                  settings: settings, provider: weatherProvider, latlng: absoluteProposed);
            }
          } on LocationServiceDisabledException {
            return ErrorPage(errorMessage: localizations.locationServicesAreDisabled,
              updateLocation: updateLocation,
              icon: Icons.gps_off,
              place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
          }

          isItCurrentLocation = true;

          try {

            List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude).timeout(const Duration(seconds: 3));
            Placemark place = placemarks[0];

            backupName = place.locality ?? place.subLocality ?? place.thoroughfare ?? place.subThoroughfare ?? "";
            absoluteProposed = "${position.latitude}, ${position.longitude}";

            //update the last known position for the home screen widgets
            setLastKnownLocation(backupName, absoluteProposed);

          } on Error {
            backupName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
          }
        }
        else {
          return ErrorPage(errorMessage: loc_status, updateLocation: updateLocation, icon: Icons.gps_off,
            place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
        }
      }

      if (proposedLoc == 'query') {
        List<dynamic> suggestedLocations = await LocationService.getRecommendation(backupName, settings["Search provider"], settings);
        if (suggestedLocations.isNotEmpty) {
          var split = json.decode(suggestedLocations[0]);
          absoluteProposed = "${split["lat"]},${split["lon"]}";
          backupName = split["name"];
        } else {
          return ErrorPage(
            errorMessage: '${localizations.placeNotFound}: \n $backupName',
            updateLocation: updateLocation,
            icon: Icons.location_disabled,
            key: Key(backupName),
            place: backupName,
            settings: settings,
            provider: weatherProvider,
            latlng: absoluteProposed,
          );
        }
      }

      String RealName = backupName.toString();
      if (isItCurrentLocation) {
        backupName = 'CurrentLocation';
      }

      WeatherData weatherData;

      try {
        weatherData = await WeatherData.getFullData(settings, RealName, backupName, absoluteProposed, weatherProvider, localizations);
      } on TimeoutException {
        return ErrorPage(errorMessage: localizations.weakOrNoWifiConnection,
          updateLocation: updateLocation,
          icon: Icons.wifi_off, key: Key(backupName),
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
      } on HttpExceptionWithStatus catch (hihi){
        return ErrorPage(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,
          shouldAdd: "Please try another weather provider!",);
      } on SocketException {
        return ErrorPage(errorMessage: localizations.notConnectedToTheInternet,
          updateLocation: updateLocation,
          icon: Icons.wifi_off, key: Key(backupName),
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
      }
      catch (e, stacktrace) {
        if (kDebugMode) {
          debugPrint('Stack trace: $stacktrace');
        }
        return ErrorPage(errorMessage: "general error at place 1: ${e.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,
          shouldAdd: "Please try another weather provider!",);
      }

      await setLastPlace(backupName, absoluteProposed);  // if the code didn't fail
      // then this will be the new startup place

      //WidgetService.saveData('counter', weatherData.current.temp);
      //WidgetService.reloadWidget();

      return WeatherPage(data: weatherData, updateLocation: updateLocation);

    } catch (e, stacktrace) {
      Map<String, String> settings = await getSettingsUsed();
      String weatherProvider = await getWeatherProvider();

      if (kDebugMode) {
        debugPrint('Error fetching weather data: $e');
        debugPrint('Stack trace: $stacktrace');
      }

      await cacheManager2.emptyCache();

      if (recall) {
        return ErrorPage(
          errorMessage: "An error occurred while fetching data",
          updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName,
          settings: settings,
          provider: weatherProvider,
          latlng: 'query',
          shouldAdd: "Please try another weather provider!",
        );
      } else {
        //retry after clearing cache
        return getDays(true, proposedLoc, backupName, startup);
      }
    }
  }

  Widget w1 = Container();
  bool isLoading = false;
  bool startup2 = false;

  @override
  void initState() {
    super.initState();

    //defaults to new york when no previous location was found
    updateLocation('40.7128, -74.0060', "New York", time: 300, startup: true); //just for testing
  }

  Future<void> updateLocation(proposedLoc, backupName, {time = 0, startup = false}) async {

    setState(() {
      HapticFeedback.lightImpact();
      if (startup) {
        startup2 = true;
      }
      isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: time));

    if (!mounted) return;

    try {

      Widget screen = await getDays(false, proposedLoc, backupName, startup);

      setState(() {
        w1 = screen;
        if (!mounted) return;
        if (startup) {
          startup2 = false;
        }
      });

      setState(() {
        isLoading = false;
      });

    } catch (error,s) {

      if (kDebugMode) {
        print((error, s));
      }

      setState(() {
        isLoading = false;
      });
    }

    if (startup) {
      startup2 = false;
    }
  }

  List<Color> colors = getStartBackColor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      body: Stack(
        children: [
          w1,
          if (isLoading) Container(
            color: startup2 ? colors[0] : const Color.fromRGBO(0, 0, 0, 0.7),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: startup2 ? colors[1] : WHITE,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> getStartBackColor() {
  var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool isDarkMode = brightness == Brightness.dark;
  Color back = isDarkMode ? BLACK : WHITE;
  Color front = isDarkMode ? const Color.fromRGBO(250, 250, 250, 0.7) : const Color.fromRGBO(0, 0, 0, 0.3);
  return [back, front];
}