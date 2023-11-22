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

import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'ui_helper.dart';

import 'weather_refact.dart' as weather_refactor;
import 'languages.dart';

String LOCATION = 'Szeged';
bool RandomSwitch = false;

double unit_coversion(double value, String unit) {
  List<double> p = weather_refactor.conversionTable[unit] ?? [0, 0];
  double a = p[0] + value * p[1];
  return a;
}

String translation(String text, String language) {
  int index = languageIndex[language] ?? 0;
  String translated = mainTranslate[text]![index];
  return translated;
}

double temp_multiply_for_scale(double temp, String unit) {
  if (unit == '˚C') {
    return max(0, min(100, 17 + temp * 2.4));
  }
  else{
    return max(0, min(100, 0 + temp));
  }
}

String iconCorrection(name, isday) {
  String text = textCorrection(name, isday);
  String p = weather_refactor.textIconMap[text] ?? 'cloudy13.jpg';
  return p;
}

String getTime(date) {
  final realtime = date.split(' ')[1];
  final realhour = realtime.split(':')[0];
  final num = int.parse(realhour);
  if (num == 0) {
    return '12am';
  }
  else if (num < 10) {
    final minusHour = (num % 10).toString();
    return '${minusHour}am';
  }
  else if (num < 12) {
    return realhour + 'am';
  }
  else if (num == 12) {
    return '12pm';
  }
  return '${num - 12}pm';
}

List<Hour> buildHourly(data, settings, int index, int timenow) {
  List<Hour> hourly = [];
  if (index == 0) {
    for (var i = 0; i < data.length; i++) {
      if (data[i]["time_epoch"] > timenow) {
        hourly.add(Hour.fromJson(data[i], settings));
      }
    }
  }
  else {
    for (var i = 0; i < data.length; i++) {
      hourly.add(Hour.fromJson(data[i], settings));
    }
  }
  return hourly;
}

Color backroundColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  Color p = weather_refactor.textBackColor[text] ?? WHITE;
  return p;
}

String getName(index, settings) {
  List<String> names = ['Today', 'Tomorrow', 'Overmorrow'];
  return translation(names[index], settings[0]);
}

String backdropCorrection(name, isday) {
  String text = textCorrection(name, isday);
  String backdrop = weather_refactor.textBackground[text] ?? "fog.jpg";
  return backdrop;
}

String textCorrection(name, isday, {settings = 'English'}) {
  String x = 'Thunderstorm';
  if (name == 'Clear'){
    if (isday == 1) {
      x =  'Clear Sky';
    }
    else{
      x =  'Clear Night';
    }
  }
  else if (name == 'Partly cloudy'){
    if (isday == 1) {
      x =  'Partly Cloudy';
    }
    else{
      x =  'Cloudy Night';
    }
  }
  else {
    x = weather_refactor.weatherTextMap[name] ?? "undefined";
  }
  String p = translation(x, settings[0]);
  return p;
}

List<Color> contentColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  List<Color> p = weather_refactor.textFontColor[text] ?? [BLACK, WHITE];
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

  static Hour fromJson(item, settings) => Hour(
    text: textCorrection(
        item["condition"]["text"], item["is_day"], settings: settings
    ),
    icon: iconCorrection(
        item["condition"]["text"], item["is_day"]
    ),
    temp:double.parse(unit_coversion(item["temp_c"], settings[1]).toStringAsFixed(1)),
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

  static Day fromJson(item, index, settings, timenow) => Day(
      date: item['date'],
      //text: item["day"]["condition"]["text"],
      //icon: "http:" + item["day"]['condition']['icon'],
      text: textCorrection(
        item["day"]["condition"]["text"], 1, settings: settings
      ),
      icon: iconCorrection(
        item["day"]["condition"]["text"], 1
      ),
      name: getName(index, settings),
      minmaxtemp: '${unit_coversion(item["day"]["maxtemp_c"], settings[1]).round()}°'
          '/${unit_coversion(item["day"]["mintemp_c"], settings[1]).round()}°',
      hourly: buildHourly(item["hour"], settings, index, timenow),
  );
}

class WeatherData {
  final List<String> settings;
  final List<Day> days;
  final Current current;
  final String place;

  WeatherData(this.days, this.current, this.place, this.settings);
}

class Current {
  final String text;
  final String backdrop;
  final int temp;
  final List<Color> contentColor;
  final int humidity;
  final int uv;
  final double precip;
  final int wind;
  final Color backcolor;

  const Current({
    required this.text,
    required this.backdrop,
    required this.temp,
    required this.contentColor,
    required this.precip,
    required this.humidity,
    required this.uv,
    required this.wind,
    required this.backcolor,
});

  static Current fromJson(item, settings) => Current(

    text: textCorrection(
      item["current"]["condition"]["text"], item["current"]["is_day"], settings: settings
    ),
    backdrop: backdropCorrection(
      item["current"]["condition"]["text"], item["current"]["is_day"]
    ),
    temp: unit_coversion(item["current"]["temp_c"], settings[1]).round(),

    contentColor: contentColorCorrection(
      item["current"]["condition"]["text"], item["current"]["is_day"]
    ),

    backcolor: backroundColorCorrection(
        item["current"]["condition"]["text"], item["current"]["is_day"]
    ),

    uv: item["current"]["uv"].round(),
    humidity: item["current"]["humidity"],
    precip: double.parse(unit_coversion(item["forecast"]["forecastday"][0]["day"]["totalprecip_mm"], settings[2]).toStringAsFixed(1)),
    wind: unit_coversion(item["current"]["wind_kph"], settings[3]).round(),
  );
}

class CustomCacheManager{
  static const key = 'muszkli';

}
