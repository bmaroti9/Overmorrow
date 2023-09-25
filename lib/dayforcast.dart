import 'dart:ui';
import 'ui_helper.dart';

import 'weather_refact.dart' as weather_refactor;

String iconCorrection(name, isday) {
  String text = textCorrection(name, isday);
  String p = weather_refactor.textIconMap[text] ?? 'clear_night.png';
  return p;
}

String getTime(date) {
  final realtime = date.split(' ')[1];
  final realhour = realtime.split(':')[0];
  if (int.parse(realhour) < 12) {
    return realhour + 'am';
  }
  return realhour + 'pm';
}

List<Hour> buildHourly(data) {
  List<Hour> hourly = [];
  for (var i = 0; i < data.length; i++) {
    hourly.add(Hour.fromJson(data[i]));
  }
  return hourly;
}

Color backroundColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  Color p = weather_refactor.textBackColor[text] ?? WHITE;
  return p;
}

String getName(index) {
  List<String> names = ['Today', 'Tomorrow', 'Overmorrow'];
  return names[index];
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

class Hour {
  final temp;
  final icon;
  final time;
  final text;

  const Hour(
  {
    required this.temp,
    required this.time,
    required this.icon,
    required this.text,
  });

  static Hour fromJson(item) => Hour(
    text: textCorrection(
        item["condition"]["text"], item["is_day"]
    ),
    icon: iconCorrection(
        item["condition"]["text"], item["is_day"]
    ),
    temp: item["temp_c"],
    time: getTime(item["time"])
  );
}

class Day {
  final String date;
  final String text;
  final String icon;
  final String name;
  final String minmaxtemp;
  final List<Hour> hourly;

  const Day({
    required this.date,
    required this.text,
    required this.icon,
    required this.name,
    required this.minmaxtemp,
    required this.hourly,
  });

  static Day fromJson(item, index) => Day(
      date: item['date'],
      //text: item["day"]["condition"]["text"],
      //icon: "http:" + item["day"]['condition']['icon'],
      text: textCorrection(
        item["day"]["condition"]["text"], 1
      ),
      icon: iconCorrection(
        item["day"]["condition"]["text"], 1
      ),
      name: getName(index),
      minmaxtemp: '${item["day"]["maxtemp_c"].round()}°'
          '/${item["day"]["mintemp_c"].round()}°',
      hourly: buildHourly(item["hour"]),
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
  final List<Color> contentColor;
  final int maxtemp;
  final int mintemp;
  final int precip;
  final int wind;
  final Color backcolor;

  const Current({
    required this.text,
    required this.backdrop,
    required this.temp,
    required this.contentColor,
    required this.precip,
    required this.maxtemp,
    required this.mintemp,
    required this.wind,
    required this.backcolor,
});

  static Current fromJson(item) => Current(

    text: textCorrection(
      item["current"]["condition"]["text"], item["current"]["is_day"]
    ),
    backdrop: backdropCorrection(
      item["current"]["condition"]["text"], item["current"]["is_day"]
    ),
    temp: item["current"]["temp_c"].round(),

    contentColor: contentColorCorrection(
      item["current"]["condition"]["text"], item["current"]["is_day"]
    ),

    backcolor: backroundColorCorrection(
        item["current"]["condition"]["text"], item["current"]["is_day"]
    ),

    maxtemp: item["forecast"]["forecastday"][0]["day"]["maxtemp_c"].round(),
    mintemp: item["forecast"]["forecastday"][0]["day"]["mintemp_c"].round(),
    precip: item["current"]["precip_mm"].round(),
    wind: item["current"]["wind_kph"].round(),
  );
}
