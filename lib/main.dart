import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_key.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dayforcast.dart' as dayforcast;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static Future<List<dayforcast.Day>> getDays() async {
    try {
      var params = {
        'key': apiKey,
        'q': 'Szeged',
        'days': '3',
        'aqi': 'no',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      var response = await http.post(url);
      var jsonbody = jsonDecode(response.body);
      var forecastlist = jsonbody['forecast']['forecastday'];

      List<dayforcast.Day> result = [];
      for (var forecast in forecastlist) {
        result.add(dayforcast.Day.fromJson(forecast, 1));
        result.add(dayforcast.Day.fromJson(forecast, 0));
      }
      return result;

      //return forecastlist.map<dayforcast.Day>(dayforcast.Day.fromJson).toList();
    } catch (e, stacktrace) {
      print(stacktrace);
      throw (e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<List<dayforcast.Day>>(
          future: getDays(),
          builder: (BuildContext context,
              AsyncSnapshot<List<dayforcast.Day>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return Center(
                child: ErrorWidget(snapshot.error as Object),
              );
            }
            return Center(
              child: buildDays(snapshot.data as List<dayforcast.Day>),
            );
          },
        ),
      ),
    );
  }

  Widget buildDays(List<dayforcast.Day> thesedays) => ListView.builder(
      itemCount: thesedays.length,
      itemExtent: 380,
      itemBuilder: (context, index) {
        final day = thesedays[index];

        return Container(
          //margin: EdgeInsets.all(0),
          //color: day.color,
          decoration: BoxDecoration(
            color: day.color,
            image: const DecorationImage(
                image: AssetImage("assets/images/squigly_line.png"),
                fit: BoxFit.fill),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
                height: 10,
                child: Image.asset('assets/images/' + day.icon)
            ),
          ),
        );
      });
}