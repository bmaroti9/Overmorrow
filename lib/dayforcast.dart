import 'dart:ffi';
import 'dart:ui';
import 'ui_helper.dart';

import 'weather_refact.dart' as weather_refactor;

String iconCorrection(name) {
  String p = weather_refactor.weatherIconMap[name] ?? "clear_night.png";
  return p;
}

String backdropCorrection(name, isday) {
  String text = textCorrection(name, isday);
  String backdrop = weather_refactor.textBackground[text] ?? "fog.jpg";
  return backdrop;
}

String textCorrection(name, isday) {
  if (name == 'Clear'){
    if (isday == 1) {
      return 'Clear Sky';
    }
    else{
      return 'Clear Night';
    }
  }
  if (name == 'Partly cloudy'){
    if (isday == 1) {
      return 'Partly Cloudy';
    }
    else{
      return 'Cloudy Night';
    }
  }
  String p = weather_refactor.weatherTextMap[name] ?? "undefined";
  return p;
}

List<Color> contentColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  List<Color> p = weather_refactor.textFontColor[text] ?? [BLACK, WHITE];
  return p;
}

Color getDaysColor(date, night) {
  final splitted = date.split('-');
  final hihi = DateTime.utc(int.parse(splitted[0]),
      int.parse(splitted[1]), int.parse(splitted[2]));
  final dayIndex = (hihi.weekday * 2) - night;
  Color p =
      weather_refactor.dayColorMap[dayIndex] ?? const Color(0xff000000);
  return p;
}

class Day {
  final String date;
  final String text;
  final String icon;
  final Color color;


  const Day({
    required this.date,
    required this.text,
    required this.icon,
    required this.color,
  });

  static Day fromJson(item, night) => Day(
      date: item['date'],
      //text: item["day"]["condition"]["text"],
      //icon: "http:" + item["day"]['condition']['icon'],
      text: textCorrection(
        item["day"]["condition"]["text"], 1
      ),
      icon: iconCorrection(
        item["day"]["condition"]["text"],
      ),
      color: getDaysColor(item['date'], night),
  );
}

class WeatherData {
  final List<Day> days;
  final Current current;
  final String place;

  WeatherData(this.days, this.current, this.place);
}

class Current {
  final String text;
  final String backdrop;
  final int temp;
  final Color titleColor;
  final Color contentColor;

  const Current({
    required this.text,
    required this.backdrop,
    required this.temp,
    required this.titleColor,
    required this.contentColor,
});

  static Current fromJson(item) => Current(

    text: textCorrection(
      item["condition"]["text"], item["is_day"]
    ),
    backdrop: backdropCorrection(
      item["condition"]["text"], item["is_day"]
    ),
    temp: item["temp_c"].round(),

    titleColor: contentColorCorrection(
      item["condition"]["text"], item["isday"]
    )[0],

    contentColor: contentColorCorrection(
      item["condition"]["text"], item["isday"]
    )[1],
  );
}
