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
import 'api_key.dart';
import 'caching.dart';
import 'dayforcast.dart';
import 'main_ui.dart';
import 'package:flutter/services.dart';

import 'dayforcast.dart' as dayforcast;
import 'settings_page.dart';

void main() {
  //runApp(const MyApp());

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {

  String proposedLoc = 'New York';
  bool startup = true;

  void updateLocation(String newLocation) {
    setState(() {
      proposedLoc = newLocation;
    });
  }

  Future<List<String>> getRadar() async {
    const String url = 'https://api.rainviewer.com/public/weather-maps.json';

    var file = await cacheManager2.getSingleFile(url.toString());
    var response = await file.readAsString();
    //final response = await http.get(Uri.parse(url));
    //print('Response data: ${response.body}');
    final Map<String, dynamic> data = json.decode(response);

    final String host = data["host"];
    //const atEnd = "/512/2/-32/108/3/1_1.png";
    //const atEnd = "/512/2/2/1/8/1_1.png";

    final radar = data["radar"]["past"];

    List<String> images = [];

    for (var x in radar) {
      //Image hihi = Image.network(host + x["path"] + atEnd);
      images.add(host + x["path"]);
    }

    return images;
  }

  Future<Widget> getDays(bool recall) async {
    try {

      List<String> unitsUsed = await getSettingsUsed();

      if (startup) {
        proposedLoc = await getLastPlace();
        startup = false;
      }

      String absoluteProposed = proposedLoc;

      if (proposedLoc == 'CurrentLocation') {
        String loc_status = await isLocationSafe();
        if (loc_status == "enabled") {
          Position position;
          try {
            position = await Geolocator.getCurrentPosition(
              //forceAndroidLocationManager: true,
              desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 4));
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return dumbySearch(errorMessage: translation(
                  "Unable to locate device", unitsUsed[0]),
                updateLocation: updateLocation,
                icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
                place: absoluteProposed,
                settings: unitsUsed,);
            }
          } on LocationServiceDisabledException {
            return dumbySearch(errorMessage: translation("location services are disabled.", unitsUsed[0]),
              updateLocation: updateLocation,
              icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
              place: absoluteProposed, settings: unitsUsed,);
          }
          absoluteProposed = '${position.latitude},${position.longitude}';
        }
        else {
          return dumbySearch(errorMessage: translation(loc_status, unitsUsed[0]),
            updateLocation: updateLocation,
            icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
            place: absoluteProposed, settings: unitsUsed,);
        }
      }

      var response;
      var file;

      print('got here');
      var params = {
        'key': apiKey,
        'q': absoluteProposed,
        'days': '3 ',
        'aqi': 'yes',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      try {
        file = await cacheManager2.getSingleFile(url.toString(), key: absoluteProposed, headers: {'cache-control': 'private, max-age=120'}).timeout(const Duration(seconds: 6));
        response = await file.readAsString();
        //response = await http.post(url).timeout(
        //    const Duration(seconds: 10));
        //var hihi = x.getFileStream(url.toString());
        //var huhu = await hihi.last;

      } on TimeoutException {
        return dumbySearch(errorMessage: translation("Weak or no wifi connection", unitsUsed[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      } on HttpExceptionWithStatus catch (hihi){
        print(hihi.toString());
        if (hihi.toString().contains("statusCode: 400")) {
          return dumbySearch(
            errorMessage: '${translation('Place not found', unitsUsed[0])}: $proposedLoc',
            updateLocation: updateLocation,
            icon: const Icon(Icons.location_disabled, color: WHITE, size: 30,),
            place: absoluteProposed,
            settings: unitsUsed,);
        }
        else if (hihi.toString().contains("statusCode: ")) {
          String replacement = "<api_key>";

          String newStr = hihi.toString().replaceAll(apiKey, replacement);
          return dumbySearch(errorMessage: "general error at place 1: $newStr", updateLocation: updateLocation,
            icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
            place: absoluteProposed, settings: unitsUsed,);
        }
      } on SocketException {
        return dumbySearch(errorMessage: translation("Not connected to the internet", unitsUsed[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      } on Error catch (e) {
        return dumbySearch(errorMessage: "general error at place 2: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      }

      //var jsonbody = jsonDecode(response.body);
      var jsonbody = jsonDecode(response);

      dayforcast.LOCATION = proposedLoc;
      SetData('LastPlace', proposedLoc);


      var forecastlist = jsonbody['forecast']['forecastday'];
      var timenow = jsonbody["location"]["localtime_epoch"];
      String loc_p = jsonbody['location']['name'];


      List<dayforcast.Day> days = [];
      int index = 0;
      for (var forecast in forecastlist) {
        days.add(dayforcast.Day.fromJson(forecast, index, unitsUsed, timenow));
        index += 1;
      }

      List<String> radar;
      try {
         radar = await getRadar();
      } on Error catch(e) {
        return dumbySearch(errorMessage: "error with the radar: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      }

      dayforcast.Current current = dayforcast.Current.fromJson(jsonbody, unitsUsed, radar);

      dayforcast.WeatherData data = dayforcast.WeatherData(
          days, current, loc_p, unitsUsed);

      return WeatherPage(data: data,
          updateLocation: updateLocation);

    } catch (e) {
      proposedLoc = await getLastPlace();
      List<String> unitsUsed = await getSettingsUsed();

      print("ERRRRRRRRROR");

      cacheManager2.emptyCache();

      if (recall) {
        return dumbySearch(errorMessage: "general error at place X: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: proposedLoc, settings: unitsUsed,);
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
