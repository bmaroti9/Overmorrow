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
import 'main_ui.dart';
import 'package:flutter/services.dart';

import 'decoders/decode_wapi.dart' as wapi;
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

  String proposedLoc = '40.7128, 74.0060';
  String backupName = "New York";

  bool startup = true;

  void updateLocation(String coordinates, String backup_name) {
    setState(() {
      proposedLoc = coordinates;
      backupName = backup_name;
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

      List<String> settings = await getSettingsUsed();
      String weather_provider = await getWeatherProvider();
      print(weather_provider);

      if (startup) {
        List<String> n = await getLastPlace();
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
                settings: settings,);
            }
          } on LocationServiceDisabledException {
            return dumbySearch(errorMessage: translation("location services are disabled.", settings[0]),
              updateLocation: updateLocation,
              icon: const Icon(Icons.gps_off, color: WHITE, size: 30,),
              place: backupName, settings: settings,);
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
            place: backupName, settings: settings,);
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
            place: backupName, settings: settings,);
        }
      }

      var response;
      var file;

      var params;
      var url;

      if (weather_provider == 'met.norway') {
        List<String> split = absoluteProposed.split(', ');
        params = {
          'lat': split[0],
          'lon': split[1],
        };
        url = Uri.http('api.met.no', 'weatherapi/locationforecast/2.0/complete', params);
        //print('ifdfjdfjshfksjflkjflkjlksjf');
      } else {
        params = {
          'key': wapi_Key,
          'q': absoluteProposed,
          'days': '3 ',
          'aqi': 'yes',
          'alerts': 'no',
        };
        url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      }

      try {
        file = await cacheManager2.getSingleFile(url.toString(), key: "$absoluteProposed,$weather_provider").timeout(const Duration(seconds: 6));
        response = await file.readAsString();
        //response = await http.post(url).timeout(
        //    const Duration(seconds: 10));
        //var hihi = x.getFileStream(url.toString());
        //var huhu = await hihi.last;

      } on TimeoutException {
        return dumbySearch(errorMessage: translation("Weak or no wifi connection", settings[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings,);
      } on HttpExceptionWithStatus catch (hihi){
        print(hihi.toString());
        return dumbySearch(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings,);
      } on SocketException {
        return dumbySearch(errorMessage: translation("Not connected to the internet", settings[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings,);
      } on Error catch (e) {
        return dumbySearch(errorMessage: "general error at place 2: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: backupName, settings: settings,);
      }

      //var jsonbody = jsonDecode(response.body);
      var jsonbody = jsonDecode(response);
      //print(response);

      String RealName = backupName.toString();
      if (isItCurrentLocation) {
        backupName = 'CurrentLocation';
      }

      await setLastPlace(backupName, absoluteProposed);

      List<String> radar;
      try {
        radar = await getRadar();
      } on Error catch(e) {
        return dumbySearch(errorMessage: "error with the radar: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings,);
      }

      return WeatherPage(data: wapi.WeatherData.fromJson(jsonbody, settings, radar, RealName, backupName),
          updateLocation: updateLocation);

    } catch (e) {
      List<String> settings = await getSettingsUsed();

      print("ERRRRRRRRROR");

      cacheManager2.emptyCache();

      if (recall) {
        return dumbySearch(errorMessage: "general error at place X: $e", updateLocation: updateLocation,
          icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: backupName, settings: settings,);
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
