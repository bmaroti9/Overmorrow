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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:overmorrow/weather_refact.dart';
import 'caching.dart';
import 'decoders/extra_info.dart';
import 'main_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'settings_page.dart';

void main() {
  //runApp(const MyApp());

  WidgetsFlutterBinding.ensureInitialized();

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
  Future<Widget> getDays(bool recall, proposedLoc, backupName, startup) async {
    try {

      AppLocalizations localizations = AppLocalizations.of(context)!;

      Map<String, String> settings = await getSettingsUsed();
      String weather_provider = await getWeatherProvider();

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
                desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 2));
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return dumbySearch(errorMessage: localizations.unableToLocateDevice,
                  updateLocation: updateLocation,
                  icon: Icons.gps_off,
                  place: backupName,
                  settings: settings, provider: weather_provider, latlng: absoluteProposed);
            }
          } on LocationServiceDisabledException {
            return dumbySearch(errorMessage: localizations.locationServicesAreDisabled,
              updateLocation: updateLocation,
              icon: Icons.gps_off,
              place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
          }

          isItCurrentLocation = true;

          try {

            List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude);
            Placemark place = placemarks[0];

            backupName = place.locality;
            absoluteProposed = "${position.latitude}, ${position.longitude}";

          } on FormatException {
            backupName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
          } on PlatformException {
            backupName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
          }
        }
        else {
          return dumbySearch(errorMessage: loc_status, updateLocation: updateLocation, icon: Icons.gps_off,
            place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
        }
      }

      if (proposedLoc == 'query') {
        List<dynamic> x = await getRecommend(backupName, settings["Search provider"], settings);
        if (x.length > 0) {
          var split = json.decode(x[0]);
          absoluteProposed = "${split["lat"]},${split["lon"]}";
          backupName = split["name"];
        }
        else {
          return dumbySearch(
            errorMessage: '${localizations.placeNotFound}: \n $backupName',
            updateLocation: updateLocation,
            icon: Icons.location_disabled, key: Key(backupName),
            place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
        }
      }

      String RealName = backupName.toString();
      if (isItCurrentLocation) {
        backupName = 'CurrentLocation';
      }

      var weatherdata;

      print(("backupName", backupName));
      try {
        weatherdata = await WeatherData.getFullData(settings, RealName, backupName, absoluteProposed, weather_provider, localizations);
      } on TimeoutException {
        return dumbySearch(errorMessage: localizations.weakOrNoWifiConnection,
          updateLocation: updateLocation,
          icon: Icons.wifi_off, key: Key(backupName),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      } on HttpExceptionWithStatus catch (hihi){
        return dumbySearch(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,
          shouldAdd: "Please try another weather provider!",);
      } on SocketException {
        return dumbySearch(errorMessage: localizations.notConnectedToTheInternet,
          updateLocation: updateLocation,
          icon: Icons.wifi_off, key: Key(backupName),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      }
      catch (e, stacktrace) {
        print(stacktrace);
        return dumbySearch(errorMessage: "general error at place 1: ${e.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,
          shouldAdd: "Please try another weather provider!",);
      }

      await setLastPlace(backupName, absoluteProposed);  // if the code didn't fail
      // then this will be the new startup place

      return WeatherPage(data: weatherdata, updateLocation: updateLocation);

    } catch (e, stacktrace) {
      Map<String, String> settings = await getSettingsUsed();
      String weather_provider = await getWeatherProvider();

      print("ERRRRRRRRROR");
      print(stacktrace);

      cacheManager2.emptyCache();

      if (recall) {
        return dumbySearch(errorMessage: "general error at place X: $e", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weather_provider, latlng: 'query',
          shouldAdd: "Please try another weather provider!",);
      }
      else {
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

    try {

      Widget screen = await getDays(false, proposedLoc, backupName, startup);

      setState(() {
        w1 = screen;
        if (startup) {
          startup2 = false;
        }
      });
      if (time > 0) {
        await Future.delayed(Duration(milliseconds: (800 - time).toInt()));
      }
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() {
        isLoading = false;
      });

    } catch (error,s) {

      print((error, s));

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