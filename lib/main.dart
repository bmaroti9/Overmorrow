import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hihi_haha/search_screens.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:http/http.dart' as http;
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
        if (await isLocationSafe()) {
          Position position = await Geolocator.getCurrentPosition(
              forceAndroidLocationManager: true,
              desiredAccuracy: LocationAccuracy.low);
          absoluteProposed = '${position.latitude},${position.longitude}';
        }
        else {
          absoluteProposed = 'New York';
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
        //print(huhu.originalUrl);
        //x.downloadFile(url.toString(), key: 'muszkli');

      } on TimeoutException {
        return dumbySearch(errorMessage: translation("Weak or no wifi connection", unitsUsed[0]),
          updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      } on SocketException {
        return dumbySearch(errorMessage: translation("Not connected to the internet", unitsUsed[0]), updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      } on Error catch (e) {
        return dumbySearch(errorMessage: "general error:$e", updateLocation: updateLocation,
          icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      }

      //var jsonbody = jsonDecode(response.body);
      var jsonbody = jsonDecode(response);
      if (false) {
        if (jsonbody["error"]["code"] == 1006) {
          return dumbySearch(errorMessage: translation('Place not found', unitsUsed[0]), updateLocation: updateLocation,
            icon: const Icon(Icons.gps_off_outlined, color: WHITE, size: 30,),
            place: absoluteProposed, settings: unitsUsed,);
        }
        return dumbySearch(errorMessage: 'an error occured. \ncode:${jsonbody["error"]["code"]}' , updateLocation: updateLocation,
            icon: const Icon(Icons.bug_report, color: WHITE, size: 30,),
          place: absoluteProposed, settings: unitsUsed,);
      }
      else{
        dayforcast.LOCATION = proposedLoc;
        SetData('LastPlace', proposedLoc);
      }
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
