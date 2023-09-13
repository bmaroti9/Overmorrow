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
        'q': 'Szeged',
        'days': '3',
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
          return Center(
            child: Column(
              children: [
                buildWholeThing(snapshot.data),
                //buildCurrent(snapshot.data?.current),
                // You can access the current data as well like this:
                // buildCurrent(snapshot.data.current),
              ],
            ),
          );
        },
      )),
    );
  }

  Widget buildWholeThing(dayforcast.WeatherData? data) => Container(
    color: const Color(0xffD58477),
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.0), // Adds 20-pixel padding on all sides
          child: Text(
            "Caption",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        ),
        Container(
          height: 696,
          //constraints: BoxConstraints.expand(),
          margin: EdgeInsets.symmetric(horizontal: 10.0), // Leaves 20-pixel margin on each side
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xff1b42c3), // Set the color of the outline
              width: 5.0, // Set the width of the outline
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          // Add your content here
        ),
      ],
    ),
  );


  Widget buildCurrent(var current) => Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xff1b42c3), // Set the color of the outline
          width: 5.0, // Set the width of the outline
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Center(
        child: Text(
          current.text,
          style: GoogleFonts.comfortaa(
              fontSize: 40, color: const Color(0xff1b42c3)),
          textAlign: TextAlign.center,
        ),
      ));

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
