/*
Copyright (C) <2023>  <Balint Maroti>

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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hihi_haha/search_screens.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'dart:convert';
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
        .then((value) => runApp(MyApp()));
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

  String proposedLoc = '40.7128, 74.0060';
  String backupName = "New York";

  bool startup = true;

  void updateLocation(String coordinates, String backup_name) {
    setState(() {
      proposedLoc = coordinates;
      backupName = backup_name;
    });
  }

  Future<Widget> getDays(bool recall) async {
    try {

      List<String> settings = await getSettingsUsed();
      String weather_provider = await getWeatherProvider();
      //print(weather_provider);

      if (startup) {
        List<String> n = await getLastPlace();  //loads the last place you visited
        print(n);
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
              desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 4));
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return dumbySearch(errorMessage: translation(
                  "Unable to locate device", settings[0]),
                updateLocation: updateLocation,
                icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
                place: backupName,
                settings: settings, provider: weather_provider, latlng: absoluteProposed,);
            }
          } on LocationServiceDisabledException {
            return dumbySearch(errorMessage: translation("location services are disabled.", settings[0]),
              updateLocation: updateLocation,
              icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
              place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
          }

          backupName = '${position.latitude},${position.longitude}';
          proposedLoc = 'search';
          isItCurrentLocation = true;
          print('True');
        }
        else {
          return dumbySearch(errorMessage: translation(loc_status, settings[0]),
            updateLocation: updateLocation,
            icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
            place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
        }
      }
      if (proposedLoc == 'search') {
        List<dynamic> x = await getRecommend(backupName);
        if (x.length > 0) {
          var split = json.decode(x[0]);
          absoluteProposed = "${split["lat"]},${split["lon"]}";
          backupName = split["name"];
        } else {
          return dumbySearch(
            errorMessage: '${translation('Place not found', settings[0])}: $backupName',
            updateLocation: updateLocation,
            icon: const Icon(Icons.location_disabled, color: WHITE, size: 30,),
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
        return dumbySearch(errorMessage: translation("Weak or no wifi connection", settings[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      } on HttpExceptionWithStatus catch (hihi){
        print(hihi.toString());
        return dumbySearch(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      } on SocketException {
        return dumbySearch(errorMessage: translation("Not connected to the internet", settings[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      } on Error catch (e, stacktrace) {
        print(stacktrace);
        return dumbySearch(errorMessage: "general error at place 2: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,);
      }

      await setLastPlace(backupName, absoluteProposed);  // if the code didn't fail
                                // then this will be the new startup

      return WeatherPage(data: weatherdata,
          updateLocation: updateLocation);

    } catch (e, stacktrace) {
      List<String> settings = await getSettingsUsed();
      String weather_provider = await getWeatherProvider();

      print("ERRRRRRRRROR");
      print(stacktrace);

      cacheManager2.emptyCache();

      if (recall) {
        return dumbySearch(errorMessage: "general error at place X: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: 'search',);
      }
      else {
        return getDays(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder<Widget>(
          future: getDays(false),
          builder: (BuildContext context,
              AsyncSnapshot<Widget> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return Center(
                child: ErrorWidget(snapshot.error as Object),
              );
              //return comfortatext('Error fetching data', 20);
            }
            //return buildWholeThing(snapshot.data);
            return snapshot.data!;
          },
        )),
    );
  }
}
