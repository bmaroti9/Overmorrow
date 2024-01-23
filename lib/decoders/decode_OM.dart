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


import 'dart:ui';

import 'package:hihi_haha/decoders/decode_wapi.dart';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';

String oMGetName(index, settings, item) {
  if (index < 3) {
    const names = ['Today', 'Tomorrow', 'Overmorrow'];
    return translation(names[index], settings[0]);
  }
  String x = item["daily"]["time"][index].split("T")[0];
  List<String> z = x.split("-");
  DateTime time = DateTime(int.parse(z[0]), int.parse(z[1]), int.parse(z[2]));
  const weeks = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  return translation(weeks[time.weekday - 1], settings[0]);
}

String oMamPmTime(String time) {
  List<String> splited = time.split("T");
  List<String> num = splited[1].split(":");
  int hour = int.parse(num[0]);
  if (hour == 0) {
    return "12am";
  }
  if (hour < 12) {
    return "${hour}am";
  }
  if (hour == 12) {
    return "12pm";
  }
  return "${hour - 12}pm";
}

String oM24hour(String time) {
  List<String> splited = time.split("T");
  return splited[1];
}

String oMTextCorrection(int code) {
  return OMCodes[code] ?? 'Clear Sky';
}

String oMCurrentTextCorrection(int code, sunstatus, time){
  String t = time.contains("T") ? time.split("T")[1] : time.split(" ")[1];
  int minute = int.parse(t.split(":")[1]);
  int hour = int.parse(t.split(":")[0]);

  List<String> x = sunstatus.absoluteSunriseSunset.split("/");
  int up_h = int.parse(x[0].split(":")[0]);
  int up_m = int.parse(x[0].split(":")[1]);

  int down_h = int.parse(x[1].split(":")[0]);
  int donw_m = int.parse(x[1].split(":")[1]);

  double a_current = hour + minute / 60;
  double a_up = up_h + up_m / 60;
  double a_down = down_h + donw_m / 60;
  
  if (a_up <= a_current && a_current <= a_down) {
    return OMCodes[code] ?? 'Clear Sky';
  }
  else {
    if (code == 0 || code == 1) {
      return 'Clear Night';
    }
    else if (code == 2 || code == 3) {
      return 'Cloudy Night';
    }
    return OMCodes[code] ?? 'Clear Sky';
  }
}

String oMBackdropCorrection(String text) {
  return textBackground[text] ?? 'very_clear.jpg';
}

Color oMBackColorCorrection(String text) {
  return textBackColor[text] ?? BLACK;
}

Color oMAccentColorCorrection(String text) {
  return accentColors[text] ?? WHITE;
}

List<Color> oMContentColorCorrection(String text) {
  return textFontColor[text] ?? [WHITE, WHITE];
}

String oMIconCorrection(String text) {
  return textIconMap[text] ?? 'sun.png';
}


class OMCurrent {
  final String text;
  final String backdrop;
  final int temp;
  final List<Color> contentColor;
  final int humidity;
  final int uv;
  final double precip;
  final int wind;
  final Color backcolor;
  final Color accentcolor;

  const OMCurrent({
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

  static OMCurrent fromJson(item, settings, sunstatus, timenow) => OMCurrent(
    text: translation(oMCurrentTextCorrection(item["current"]["weather_code"], sunstatus, timenow), settings[0]),
    uv: item["daily"]["uv_index_max"][0].round(),
    accentcolor: oMAccentColorCorrection(
      oMCurrentTextCorrection(item["current"]["weather_code"], sunstatus, timenow),
    ),

    backcolor: settings[5] == "high contrast"
        ? BLACK
        :  oMBackColorCorrection(oMCurrentTextCorrection(item["current"]["weather_code"], sunstatus, timenow),),

    backdrop: oMBackdropCorrection(
      oMCurrentTextCorrection(item["current"]["weather_code"], sunstatus, timenow),
    ),

    contentColor: settings[5] == "high contrast"
        ? [BLACK,WHITE]
        :  oMContentColorCorrection(oMCurrentTextCorrection(item["current"]["weather_code"], sunstatus, timenow),),

    precip: double.parse(unit_coversion(item["current"]["precipitation"], settings[2]).toStringAsFixed(1)),
    wind: unit_coversion(item["current"]["precipitation"], settings[3]).round(),
    humidity: item["current"]["relative_humidity_2m"],
    temp: unit_coversion(item["current"]["temperature_2m"], settings[1]).round(),
  );
}


class OMDay {
  final String text;
  final String icon;
  final String name;
  final String minmaxtemp;
  final List<OMHour> hourly;
  final List<OMHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;
  final int windspeed;
  final double mm_precip;
  final int uv;

  const OMDay({
    required this.text,
    required this.icon,
    required this.name,
    required this.minmaxtemp,
    required this.hourly,

    required this.precip_prob,
    required this.total_precip,
    required this.windspeed,
    required this.hourly_for_precip,
    required this.mm_precip,
    required this.uv,
  });

  static OMDay build(item, settings, index, sunstatus) {
    return OMDay(
      uv: item["daily"]["uv_index_max"][0].round(),
      icon: oMIconCorrection(oMTextCorrection(item["daily"]["weather_code"][index])),
      text: translation(oMTextCorrection(item["daily"]["weather_code"][index]), settings[0]),
      name: oMGetName(index, settings, item),
      windspeed: unit_coversion(item["daily"]["wind_speed_10m_max"][index], settings[3]).round(),
      total_precip: double.parse(unit_coversion(item["daily"]["precipitation_sum"][index], settings[2]).toStringAsFixed(1)),
      minmaxtemp: "${unit_coversion(item["daily"]["temperature_2m_min"][index], settings[1]).round().toString()}°"
          "/${unit_coversion(item["daily"]["temperature_2m_max"][index], settings[1]).round().toString()}°",
      precip_prob: item["daily"]["precipitation_probability_max"][index] ?? 0,
      mm_precip: item["daily"]["precipitation_sum"][index],
      hourly_for_precip: buildHours(index, false, item, settings, sunstatus),
      hourly: buildHours(index, true, item, settings, sunstatus),
    );
  }

  static List<OMHour> buildHours(index, get_rid_first, item, settings, sunstatus) {
    int timenow = int.parse(item["current"]["time"].split("T")[1].split(":")[0]);
    List<OMHour> hourly = [];
    if (index == 0 && get_rid_first) {
      for (var i = 0; i < 24; i++) {
        if (index * 24 + i >= timenow) {
          hourly.add(OMHour.fromJson(item, i, settings, sunstatus));
        }
      }
      return hourly;
    }
    else {
      for (var i = 0; i < 24; i++) {
        hourly.add(OMHour.fromJson(item, index * 24 + i, settings, sunstatus));
      }
      return hourly;
    }
  }
}

class OMHour {
  final int temp;
  final String icon;
  final String time;
  final String text;
  final double precip;

  const OMHour({
    required this.temp,
    required this.time,
    required this.icon,
    required this.text,
    required this.precip,
  });

  static OMHour fromJson(item, index, settings, sunstatus) => OMHour(
    temp: unit_coversion(item["hourly"]["temperature_2m"][index], settings[1]).round(),
    text: translation(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index]), settings[0]),
    icon: oMIconCorrection(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index])),
    time: settings[6] == '12 hour'? oMamPmTime(item["hourly"]["time"][index]) : oM24hour(item["hourly"]["time"][index]),
    precip: unit_coversion(item["hourly"]["precipitation"][index], settings[2]),
  );
}