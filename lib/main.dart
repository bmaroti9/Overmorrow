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
  static Future<dayforcast.WeatherData> getDays() async {
    try {
      var params = {
        'key': apiKey,
        'q': 'Malé',
        'days': '0',
        'aqi': 'no',
        'alerts': 'no',
      };
      var url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);
      var response = await http.post(url);
      var jsonbody = jsonDecode(response.body);
      var forecastlist = jsonbody['forecast']['forecastday'];

      List<dayforcast.Day> days = [];
      for (var forecast in forecastlist) {
        days.add(dayforcast.Day.fromJson(forecast, 1));
        days.add(dayforcast.Day.fromJson(forecast, 0));
      }

      dayforcast.Current current =
          dayforcast.Current.fromJson(jsonbody['current']);

      return dayforcast.WeatherData(
          days, current, jsonbody['location']['name']);
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
          }
          return buildWholeThing(snapshot.data);
        },
      )),
    );
  }

  Widget buildWholeThing(dayforcast.WeatherData? data) => Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backdrops/${data!.current.backdrop}'),
            fit: BoxFit.cover,
            alignment: const Alignment(-0.25, 0.0),
          ),
        ),
      ),
      Center(
        child: Column(
          children: [
            buildCurrent(data)
          ],
        ),
      ),
    ],
  );

  Widget buildCurrent(var data) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 40),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
              data.place,
              style: GoogleFonts.comfortaa(
                fontSize: 42,
                color: data.current.titleColor
            ),
          )
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 260.0, left: 40),
        child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              '${data.current.temp}°',
              style: GoogleFonts.comfortaa(
                color: data.current.contentColor,
                fontSize: 85,
                fontWeight: FontWeight.w100,
              ),
            )
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              data.current.text,
              style: GoogleFonts.comfortaa(
                color: data.current.contentColor,
                fontSize: 50,
                height: 0.7,
                fontWeight: FontWeight.w300,
              ),
            )
        ),
      )
    ],
  );

  Widget buildDays(var thesedays) => ListView.builder(
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
                height: 10, child: Image.asset('assets/images/' + day.icon)),
          ),
        );
      });
}
