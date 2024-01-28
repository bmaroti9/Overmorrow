/*
Copyright (C) <2024>  <Balint Maroti>

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
import 'dart:ui';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart' as weather_refactor;

//decodes the whole response from the weatherapi.com api_call

bool RandomSwitch = false;

String amPmTime(String time) {
  List<String> splited = time.split(" ");
  List<String> num = splited[0].split(":");
  int hour = int.parse(num[0]);
  int minute = int.parse(num[1]);
  String atEnd = 'am';
  if (splited[1] == 'PM') {
    atEnd = 'pm';
  }
  return "$hour:$minute$atEnd";
}

String convertTime(String input) {
  List<String> splited = input.split(" ");
  List<String> num = splited[0].split(":");
  int hour = int.parse(num[0]);
  int minute = int.parse(num[1]);
  if (splited[1] == 'PM') {
    hour += 12;
  }
  if (hour < 10) {
    if (minute < 10) {
      return "0$hour:0$minute";
    }
    return "0$hour:$minute";
  }
  if (minute < 10) {
    return "$hour:0$minute";
  }
  return "$hour:$minute";
}

double getSunStatus(String sunrise, String sunset, String time) {
  List<String> splited1 = sunrise.split(" ");
  List<String> num1 = splited1[0].split(":");
  int hour1 = int.parse(num1[0]);
  int minute1 = int.parse(num1[1]);
  if (splited1[1] == 'PM') {
    hour1 += 12;
  }
  int all1 = hour1 * 60 + minute1;

  List<String> splited2 = sunset.split(" ");
  List<String> num2 = splited2[0].split(":");
  int hour2 = int.parse(num2[0]);
  int minute2 = int.parse(num2[1]);
  if (splited2[1] == 'PM') {
    hour2 += 12;
  }
  int all2 = (hour2 * 60 + minute2) - all1;

  List<String> splited3 = time.split(" ");
  List<String> num3 = splited3[1].split(":");
  int hour3 = int.parse(num3[0]);
  int minute3 = int.parse(num3[1]);
  int all3 = (hour3 * 60 + minute3) - all1;

  return min(1, max(all3 / all2, 0));

}

double unit_coversion(double value, String unit) {
  List<double> p = weather_refactor.conversionTable[unit] ?? [0, 0];
  double a = p[0] + value * p[1];
  return a;
}

double temp_multiply_for_scale(int temp, String unit) {
  if (unit == '˚C') {
    return max(0, min(100, 17 + temp * 2.4));
  }
  else{
    return max(0, min(100, (0 + temp).toDouble()));
  }
}

String iconCorrection(name, isday) {
  String text = textCorrection(name, isday);
  String p = weather_refactor.textIconMap[text] ?? 'clear_night.png';
  return p;
}

String getTime(date, bool ampm) {
   if (ampm) {
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
   else {
     final realtime = date.split(' ');
     return realtime[1];
   }
}

Color backroundColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  Color p = weather_refactor.textBackColor[text] ?? WHITE;
  return p;
}


Color accentColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  Color p = weather_refactor.accentColors[text] ?? WHITE;
  return p;
}

String getName(index, settings) {
  List<String> names = ['Today', 'Tomorrow', 'Overmorrow'];
  return translation(names[index], settings[0]);
}

String backdropCorrection(name, isday) {
  String text = textCorrection(name, isday);
  String backdrop = weather_refactor.textBackground[text] ?? "haze.jpg";
  return backdrop;
}

String textCorrection(name, isday, {settings = 'English'}) {
  name = weather_refactor.weatherTextMap[name] ?? "Clear Sky";
  String x = 'Clear Sky';
  print(name);
  if (name == 'Clear Sky'){
    if (isday == 1) {
      x =  'Clear Sky';
    }
    else{
      x =  'Clear Night';
    }
  }
  else if (name == 'Partly Cloudy'){
    if (isday == 1) {
      x =  'Partly Cloudy';
    }
    else{
      x =  'Cloudy Night';
    }
  }
  String p = translation(x, settings[0]);
  return p;
}

List<Color> contentColorCorrection(name, isday) {
  String text = textCorrection(name, isday);
  List<Color> p = weather_refactor.textFontColor[text] ?? [BLACK, WHITE];
  return p;
}

class WapiCurrent {
  final String text;
  final String backdrop;
  final int temp;
  final List<Color> contentColor;
  final int humidity;
  final int feels_like;
  final int uv;
  final double precip;
  final int wind;
  final Color backcolor;
  final Color accentcolor;

  const WapiCurrent({
    required this.feels_like,
    required this.precip,
    required this.accentcolor,
    required this.backcolor,
    required this.backdrop,
    required this.contentColor,
    required this.humidity,
    required this.temp,
    required this.text,
    required this.uv,
    required this.wind,
  });

  static WapiCurrent fromJson(item, settings) => WapiCurrent(
    text: textCorrection(
        item["current"]["condition"]["text"], item["current"]["is_day"], settings: settings
    ),
    backdrop: backdropCorrection(
        item["current"]["condition"]["text"], item["current"]["is_day"]
    ),
    temp: unit_coversion(item["current"]["temp_c"], settings[1]).round(),
    feels_like: unit_coversion(item["current"]["feelslike_c"], settings[1]).round(),

    contentColor: settings[5] == "high contrast"
        ? [BLACK,WHITE]
        :  contentColorCorrection(item["current"]["condition"]["text"], item["current"]["is_day"]),

    backcolor: settings[5] == "high contrast"
        ? BLACK
        :  backroundColorCorrection(item["current"]["condition"]["text"], item["current"]["is_day"]),

    accentcolor: accentColorCorrection(
        item["current"]["condition"]["text"], item["current"]["is_day"]
    ),

    uv: item["current"]["uv"].round(),
    humidity: item["current"]["humidity"],
    precip: double.parse(unit_coversion(item["forecast"]["forecastday"][0]["day"]["totalprecip_mm"], settings[2]).toStringAsFixed(1)),
    wind: unit_coversion(item["current"]["wind_kph"], settings[3]).round(),
  );
}

class WapiDay {
  final String text;
  final String icon;
  final String name;
  final String minmaxtemp;
  final List<WapiHour> hourly;
  final List<WapiHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;
  final int windspeed;
  final int uv;
  final mm_precip;

  const WapiDay({
    required this.text,
    required this.icon,
    required this.name,
    required this.minmaxtemp,
    required this.hourly,
    required this.uv,

    required this.precip_prob,
    required this.total_precip,
    required this.windspeed,
    required this.hourly_for_precip,
    required this.mm_precip,
  });

  static WapiDay fromJson(item, index, settings, timenow) => WapiDay(
    text: textCorrection(
        item["day"]["condition"]["text"], 1, settings: settings
    ),
    icon: iconCorrection(
        item["day"]["condition"]["text"], 1
    ),
    name: getName(index, settings),
    minmaxtemp: '${unit_coversion(item["day"]["maxtemp_c"], settings[1]).round()}°'
        '/${unit_coversion(item["day"]["mintemp_c"], settings[1]).round()}°',

    hourly: buildWapiHour(item["hour"], settings, index, timenow, true),
    hourly_for_precip: buildWapiHour(item["hour"], settings, index, timenow, false),

    mm_precip: item["day"]["totalprecip_mm"] + item["day"]["totalsnow_cm"] / 10,
    total_precip: double.parse(unit_coversion(item["day"]["totalprecip_mm"], settings[2]).toStringAsFixed(1)),
    precip_prob: item["day"]["daily_chance_of_rain"],
    windspeed: unit_coversion(item["day"]["maxwind_kph"], settings[3]).round(),
    uv: item["day"]["uv"].round(),
  );

  static List<WapiHour> buildWapiHour(data, settings, int index, int timenow, bool get_rid_first) {
    List<WapiHour> hourly = [];
    if (index == 0 && get_rid_first) {
      for (var i = 0; i < data.length; i++) {
        if (data[i]["time_epoch"] > timenow) {
          hourly.add(WapiHour.fromJson(data[i], settings));
        }
      }
    }
    else {
      for (var i = 0; i < data.length; i++) {
        hourly.add(WapiHour.fromJson(data[i], settings));
      }
    }
    return hourly;
  }
}

class WapiHour {
  final int temp;
  final String icon;
  final String time;
  final String text;
  final double precip;

  const WapiHour(
      {
        required this.temp,
        required this.time,
        required this.icon,
        required this.text,
        required this.precip,
      });

  static WapiHour fromJson(item, settings) => WapiHour(
    text: textCorrection(
        item["condition"]["text"], item["is_day"], settings: settings
    ),
    icon: iconCorrection(
        item["condition"]["text"], item["is_day"]
    ),
    //temp:double.parse(unit_coversion(item["temp_c"], settings[1]).toStringAsFixed(1)),
    temp: unit_coversion(item["temp_c"], settings[1]).round(),
    time: getTime(item["time"], settings[6] == '12 hour'),
    precip: item["precip_mm"] + (item["snow_cm"] / 10),
  );
}
