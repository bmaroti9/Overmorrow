import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  bool startup = true;
  String oldLoc = 'New York';

  void updateLocation(String newLocation) {
    print('updateLocation');
    setState(() {
      oldLoc = dayforcast.LOCATION.toString();
      dayforcast.LOCATION = newLocation;
    });
  }

  Future<dayforcast.WeatherData> getDays() async {
    print('getDays');
    try {
      List<String> unitsUsed = await getSettingsUsed();
      print(unitsUsed);

      String forecastLoc = dayforcast.LOCATION;
      String lastPlace = dayforcast.LOCATION;
      print(('dayforcast', dayforcast.LOCATION));

      if (startup) {
        String x = await getLastPlace();
        print(('hihihih', x));
        lastPlace = x;
        forecastLoc = x;
        startup = false;
        print(('this', lastPlace, forecastLoc, startup));
      }

      if (lastPlace == 'CurrentLocation') {
        dayforcast.LOCATION = 'CurrentLocation';
        if (await isLocationSafe()) {
          Position position = await Geolocator.getCurrentPosition(
              forceAndroidLocationManager: true,
              desiredAccuracy: LocationAccuracy.low);
          forecastLoc = '${position.latitude},${position.longitude}';
        }
        else {
          forecastLoc = oldLoc;
        }
      }

      var params = {
        'key': apiKey,
        'q': forecastLoc,
        'days': '3 ',
        'aqi': 'no',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      var response = await http.post(url);
      var jsonbody = jsonDecode(response.body);
      if (response.statusCode == 400) {
        print('somehow');
        SnackbarGlobal.show(jsonbody['error']['message']);
        updateLocation(oldLoc);
      }
      else{
        print(('here', lastPlace));
        SetData('LastPlace', lastPlace);
        dayforcast.LOCATION = lastPlace;
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

      return dayforcast.WeatherData(
          days, current, jsonbody['location']['name'], unitsUsed);
    } catch (e, stacktrace) {
      print(stacktrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return MaterialApp(
      scaffoldMessengerKey: SnackbarGlobal.key,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: FutureBuilder<dayforcast.WeatherData>(
            future: getDays(),
            builder: (BuildContext context,
                AsyncSnapshot<dayforcast.WeatherData> snapshot) {
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
              return WeatherPage(data: snapshot.data,
                     updateLocation: updateLocation);
            },
          )),
    );
  }
}
