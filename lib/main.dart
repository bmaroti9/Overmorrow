/*
Copyright (C) <2024>  <Balint Maroti>

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
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'caching.dart';
import 'decoders/extra_info.dart';
import 'main_ui.dart';
import 'package:flutter/services.dart';

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

  Future<Widget> getDays(bool recall, proposedLoc, backupName, startup) async {

    try {

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
        String loc_status = await isLocationSafe();
        if (loc_status == "enabled") {
          Position position;
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 2));
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return dumbySearch(errorMessage: translation(
                  "Unable to locate device", settings["Language"]!),
                updateLocation: updateLocation,
                icon: Icons.gps_off,
                place: backupName,
                settings: settings, provider: weather_provider, latlng: absoluteProposed);
            }
          } on LocationServiceDisabledException {
            return dumbySearch(errorMessage: translation("location services are disabled.", settings["Language"]!),
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


          } on FormatException {
            backupName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
          } on PlatformException {
            backupName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
          }

        }
        else {
          return dumbySearch(errorMessage: translation(loc_status, settings["Language"]!),
            updateLocation: updateLocation,
            icon: Icons.gps_off,
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
            errorMessage: '${translation('Place not found', settings["Language"]!)}: \n $backupName',
            updateLocation: updateLocation,
            icon: Icons.location_disabled,
            place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
        }
      }

      String RealName = backupName.toString();
      if (isItCurrentLocation) {
        backupName = 'CurrentLocation';
      }

      var weatherdata;

      try {
        weatherdata = await WeatherData.getFullData(settings, RealName, backupName, absoluteProposed, weather_provider);

      } on TimeoutException {
        return dumbySearch(errorMessage: translation("Weak or no wifi connection", settings["Language"]!),
          updateLocation: updateLocation,
          icon: Icons.wifi_off,
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      } on HttpExceptionWithStatus catch (hihi){
        return dumbySearch(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      } on SocketException {
        return dumbySearch(errorMessage: translation("Not connected to the internet", settings["Language"]!),
          updateLocation: updateLocation,
          icon: Icons.wifi_off,
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      }

      await setLastPlace(backupName, absoluteProposed);  // if the code didn't fail
                                // then this will be the new startup

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
          place: backupName, settings: settings, provider: weather_provider, latlng: 'search',);
      }
      else {
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
    updateLocation('40.7128, 74.0060', "New York", time: 300, startup: true); //just for testing
  }

  Future<void> updateLocation(proposedLoc, backupName, {time = 500, startup = false}) async {
    setState(() {
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

      await Future.delayed(Duration(milliseconds: (800 - time).toInt()));

      setState(() {
        isLoading = false;
      });

    } catch (error) {

      setState(() {
        isLoading = false;
      });
    }

    if (startup) {
      startup2 = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Color> colors = getStartBackColor();

    final EdgeInsets systemGestureInsets = MediaQuery.of(context).systemGestureInsets;
    if (systemGestureInsets.left > 0) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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