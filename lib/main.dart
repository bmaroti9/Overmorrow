import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hihi_haha/search_screens.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_key.dart';
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
    print('updateLocation');
    setState(() {
      proposedLoc = newLocation;
    });
  }

  Future<Widget> getDays() async {
    print('getDays');
    try {
      List<String> unitsUsed = await getSettingsUsed();
      print(unitsUsed);

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

      var params = {
        'key': apiKey,
        'q': absoluteProposed,
        'days': '3 ',
        'aqi': 'no',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      var response;
      try {
        response = await http.post(url).timeout(
            const Duration(seconds: 10));
      } on TimeoutException catch(e) {
        return dumbySearch(errorMessage: "Unable to load forecast. "
            "Please check your internet connection", updateLocation: updateLocation,
            icon: const Icon(Icons.wifi_off, color: WHITE, size: 30,), place: absoluteProposed,);
      }

      var jsonbody = jsonDecode(response.body);
      if (response.statusCode == 400) {
        //SnackbarGlobal.show(jsonbody['error']['message']);
        //updateLocation(dayforcast.LOCATION);
        return dumbySearch(errorMessage: jsonbody["error"]["message"], updateLocation: updateLocation,
            icon: const Icon(Icons.gps_off_outlined, color: WHITE, size: 30,), place: absoluteProposed,);
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
    print('build');
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
