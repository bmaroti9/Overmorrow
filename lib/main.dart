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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

  Future<List<dynamic>> getDays(bool recall) async {

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
              desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 4));
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return [dumbySearch(errorMessage: translation(
                  "Unable to locate device", settings[0]),
                updateLocation: updateLocation,
                icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
                place: backupName,
                settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
            }
          } on LocationServiceDisabledException {
            return [dumbySearch(errorMessage: translation("location services are disabled.", settings[0]),
              updateLocation: updateLocation,
              icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
              place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
          }

          backupName = '${position.latitude},${position.longitude}';
          proposedLoc = 'search';
          isItCurrentLocation = true;
          print('True');
        }
        else {
          return [dumbySearch(errorMessage: translation(loc_status, settings[0]),
            updateLocation: updateLocation,
            icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
            place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
        }
      }
      if (proposedLoc == 'search') {
        List<dynamic> x = await getRecommend(backupName);
        if (x.length > 0) {
          var split = json.decode(x[0]);
          absoluteProposed = "${split["lat"]},${split["lon"]}";
          backupName = split["name"];
        } else {
          return [dumbySearch(
            errorMessage: '${translation('Place not found', settings[0])}: $backupName',
            updateLocation: updateLocation,
            icon: const Icon(Icons.location_disabled, color: WHITE, size: 30,),
            place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
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
        return [dumbySearch(errorMessage: translation("Weak or no wifi connection", settings[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
      } on HttpExceptionWithStatus catch (hihi){
        print(hihi.toString());
        return [dumbySearch(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
      } on SocketException {
        return [dumbySearch(errorMessage: translation("Not connected to the internet", settings[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
      } on Error catch (e, stacktrace) {
        print(stacktrace);
        return [dumbySearch(errorMessage: "general error at place 2: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: absoluteProposed,), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
      }

      await setLastPlace(backupName, absoluteProposed);  // if the code didn't fail
                                // then this will be the new startup

      return [WeatherPage(data: weatherdata,
          updateLocation: updateLocation), weatherdata.current.backcolor];

    } catch (e, stacktrace) {
      List<String> settings = await getSettingsUsed();
      String weather_provider = await getWeatherProvider();

      print("ERRRRRRRRROR");
      print(stacktrace);

      cacheManager2.emptyCache();

      if (recall) {
        return [dumbySearch(errorMessage: "general error at place X: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings, provider: weather_provider, latlng: 'search',), instantBackColor == WHITE ? const Color(0xff7a9dbc) : instantBackColor];
      }
      else {
        return getDays(true);
      }
    }
  }

  Future<Widget> fillTime(var data) async {
    await Future.delayed(const Duration(seconds: 1));

    return data[0];
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder<List<dynamic>>(
          future: getDays(false),
          builder: (BuildContext context,
              AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Container(
                color: instantBackColor,
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: instantBackColor == WHITE ? const Color(0xff7a9dbc) : WHITE,
                    size: 40,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return Center(
                child: ErrorWidget(snapshot.error as Object),
              );
              //return comfortatext('Error fetching data', 20);
            }
            //return buildWholeThing(snapshot.data);
            //return snapshot.data![0];
            return FutureBuilder<Widget>(
                future: fillTime(snapshot.data),
                builder: (BuildContext context,
                    AsyncSnapshot<Widget> snapshot2) {
                  if (snapshot2.connectionState != ConnectionState.done) {
                    return TweenBackgroundAnimation(
                      color1: instantBackColor,
                      color2: snapshot.data?[1],
                    );
                  } else if (snapshot2.hasError) {
                    print(snapshot.error);
                    return Center(
                      child: ErrorWidget(snapshot.error as Object),
                    );
                    //return comfortatext('Error fetching data', 20);
                  }
                  return snapshot2.data!;
                }
            );
          },
        )),
    );
  }
}

class TweenBackgroundAnimation extends StatelessWidget {
  final Color color1;
  final Color color2;

  const TweenBackgroundAnimation({Key? key, required this.color1, required this.color2}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(seconds: 1),
      tween: ColorTween(begin: color1, end: color2),
      builder: (context, color, child) {
        return Container(
          color: color,
          child: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: WHITE,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}