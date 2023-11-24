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

import 'dayforcast.dart' as dayforcast;
import 'settings_page.dart';

void main() {
  runApp(const MyApp());
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

  Future<Widget> getDays() async {
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
              forceAndroidLocationManager: true,
              desiredAccuracy: LocationAccuracy.low).timeout(const Duration(seconds: 15));
          } on TimeoutException {
            return dumbySearch(errorMessage: translation("Unable to locate device", unitsUsed[0]),
              updateLocation: updateLocation,
              icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
              place: absoluteProposed, settings: unitsUsed,);
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

      print('got here');
      var params = {
        'key': apiKey,
        'q': absoluteProposed,
        'days': '3 ',
        'aqi': 'no',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      try {
        var file = await cacheManager.getSingleFile(url.toString(), headers: {'cache-control': 'private, max-age=120'});
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
            errorMessage: 'unable to load forecast for place: $proposedLoc',
            updateLocation: updateLocation,
            icon: const Icon(Icons.location_disabled, color: WHITE, size: 30,),
            place: absoluteProposed,
            settings: unitsUsed,);
        }
      } on SocketException {
        return dumbySearch(errorMessage: translation("Not connected to the internet", unitsUsed[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      } on Error catch (e) {
        return dumbySearch(errorMessage: "general error:$e", updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      }

      //var jsonbody = jsonDecode(response.body);
      var jsonbody = jsonDecode(response);

      dayforcast.LOCATION = proposedLoc;
      SetData('LastPlace', proposedLoc);
      var forecastlist = jsonbody['forecast']['forecastday'];

      List<dayforcast.Day> days = [];
      int index = 0;
      for (var forecast in forecastlist) {
        days.add(dayforcast.Day.fromJson(forecast, index, unitsUsed, jsonbody["location"]["localtime_epoch"]));
        index += 1;
      }

      dayforcast.Current current =
      dayforcast.Current.fromJson(jsonbody, unitsUsed);

      dayforcast.WeatherData data = dayforcast.WeatherData(
          days, current, jsonbody['location']['name'], unitsUsed);

      return WeatherPage(data: data,
          updateLocation: updateLocation);

    } catch (e, stacktrace) {
      print(stacktrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder<Widget>(
          future: getDays(),
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
