import 'package:flutter/material.dart';
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
  void updateLocation(String newLocation) {
    setState(() {
      dayforcast.LOCATION = newLocation;
    });
  }

  static Future<dayforcast.WeatherData> getDays() async {
    try {
      List<String> units_used = await getUnitsUsed();

      var params = {
        'key': apiKey,
        'q': dayforcast.LOCATION,
        'days': '3 ',
        'aqi': 'no',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      var response = await http.post(url);
      var jsonbody = jsonDecode(response.body);
      var forecastlist = jsonbody['forecast']['forecastday'];

      List<dayforcast.Day> days = [];
      int index = 0;
      for (var forecast in forecastlist) {
        days.add(dayforcast.Day.fromJson(forecast, index, units_used, jsonbody["location"]["localtime_epoch"]));
        index += 1;
      }

      dayforcast.Current current =
      dayforcast.Current.fromJson(jsonbody, units_used);

      return dayforcast.WeatherData(
          days, current, jsonbody['location']['name'], units_used);
    } catch (e, stacktrace) {
      print(stacktrace);
      throw (e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
