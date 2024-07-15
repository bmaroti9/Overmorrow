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


import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:overmorrow/decoders/decode_wapi.dart';

import '../caching.dart';
import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';
import 'extra_info.dart';

Future<dynamic> OMRequestData(double lat, double lng, String real_loc) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lng.toString(),
    "current": ["temperature_2m", "relative_humidity_2m", "apparent_temperature", "weather_code", "wind_speed_10m", 'wind_direction_10m'],
    "hourly": ["temperature_2m", "precipitation", "weather_code", "wind_speed_10m"],
    "daily": ["weather_code", "temperature_2m_max", "temperature_2m_min", "uv_index_max", "precipitation_sum", "precipitation_probability_max", "wind_speed_10m_max", "wind_direction_10m_dominant"],
    "timezone": "auto",
    "forecast_days": "14"
  };
  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);

  var oMFile = await cacheManager2.getSingleFile(oMUrl.toString(), key: "$real_loc, open-meteo").timeout(const Duration(seconds: 6));
  var oMResponse = await oMFile.readAsString();
  final OMData = jsonDecode(oMResponse);
  return OMData;
}

String oMGetName(index, settings, item) {
  if (index < 3) {
    const names = ['Today', 'Tomorrow', 'Overmorrow'];
    return translation(names[index], settings["Language"]);
  }
  String x = item["daily"]["time"][index].split("T")[0];
  List<String> z = x.split("-");
  DateTime time = DateTime(int.parse(z[0]), int.parse(z[1]), int.parse(z[2]));
  const weeks = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  return translation(weeks[time.weekday - 1], settings["Language"]);
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

String oMCurrentTextCorrection(int code, sunstatus, time) {
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

  //return textBackground.keys.toList()[0]; // used for testing color combinations

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
  return textBackground[text] ?? 'clear_sky3.jpg';
}

List<Color> oMtextcolorCorrection(String text) {
  return textFontColor[text] ?? [WHITE, WHITE];
}

String oMIconCorrection(String text) {
  return textIconMap[text] ?? 'sun.png';
}


class OMCurrent {
  final String text;
  final String backdrop;
  final int temp;
  final int humidity;
  final int feels_like;
  final int uv;
  final double precip;

  final int wind;
  final int wind_dir;

  final Color backcolor;
  final Color primary;
  final Color colorpop;
  final Color textcolor;
  final Color secondary;
  final Color highlight;

  final Color backup_primary;
  final Color backup_backcolor;

  const OMCurrent({
    required this.precip,
    required this.primary,
    required this.backcolor,
    required this.backdrop,
    required this.textcolor,
    required this.humidity,
    required this.feels_like,
    required this.temp,
    required this.text,
    required this.uv,
    required this.wind,
    required this.colorpop,
    required this.secondary,
    required this.highlight,
    required this.backup_backcolor,
    required this.backup_primary,
    required this.wind_dir,
  });

  static OMCurrent fromJson(item, settings, sunstatus, timenow, palette) {
    Color back = BackColorCorrection(
      oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow),
    );

    Color primary = PrimaryColorCorrection(
      oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow),
    );

    /*
    List<Color> colors = getColors(primary, back, settings,
        ColorPopCorrection( oMCurrentTextCorrection(
            item["current"]["weather_code"], sunstatus, timenow),)[
              settings["Color mode"] == "dark" ? 1 : 0
        ]);

     */

    List<Color> colors = getNetworkColors(palette, settings);

    //List<Color> colors = palette.colors.toList();

    return OMCurrent(
      text: translation(oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow),
          settings["Language"]),
      uv: item["daily"]["uv_index_max"][0].round(),
      feels_like: unit_coversion(
          item["current"]["apparent_temperature"], settings["Temperature"])
          .round(),


      backcolor: colors[0],
      primary: colors[1],
      textcolor: colors[2],
      colorpop: colors[3],
      secondary:  colors[4],
      highlight: colors[5],

      backup_backcolor: back,
      backup_primary: primary,

      backdrop: oMBackdropCorrection(
        oMCurrentTextCorrection(
            item["current"]["weather_code"], sunstatus, timenow),
      ),

      precip: double.parse(unit_coversion(
          item["daily"]["precipitation_sum"][0], settings["Precipitation"])
          .toStringAsFixed(1)),
      wind: unit_coversion(item["current"]["wind_speed_10m"], settings["Wind"])
          .round(),
      humidity: item["current"]["relative_humidity_2m"],
      temp: unit_coversion(
          item["current"]["temperature_2m"], settings["Temperature"]).round(),
      wind_dir: item["current"]["wind_direction_10m"],
    );
  }
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
  final int wind_dir;

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
    required this.wind_dir,
  });

  static OMDay build(item, settings, index, sunstatus) {
    return OMDay(
      uv: item["daily"]["uv_index_max"][0].round(),
      icon: oMIconCorrection(oMTextCorrection(item["daily"]["weather_code"][index])),
      text: translation(oMTextCorrection(item["daily"]["weather_code"][index]), settings["Language"]),
      name: oMGetName(index, settings, item),
      windspeed: unit_coversion(item["daily"]["wind_speed_10m_max"][index], settings["Wind"]).round(),
      total_precip: double.parse(unit_coversion(item["daily"]["precipitation_sum"][index], settings["Precipitation"]).toStringAsFixed(1)),
      minmaxtemp: "${unit_coversion(item["daily"]["temperature_2m_min"][index], settings["Temperature"]).round().toString()}°"
          "/${unit_coversion(item["daily"]["temperature_2m_max"][index], settings["Temperature"]).round().toString()}°",
      precip_prob: item["daily"]["precipitation_probability_max"][index] ?? 0,
      mm_precip: item["daily"]["precipitation_sum"][index],
      hourly_for_precip: buildHours(index, false, item, settings, sunstatus),
      hourly: buildHours(index, true, item, settings, sunstatus),
      wind_dir: item["daily"]["wind_direction_10m_dominant"][index] ?? 0,
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
  final double wind;

  const OMHour({
    required this.temp,
    required this.time,
    required this.icon,
    required this.text,
    required this.precip,
    required this.wind,
  });

  static OMHour fromJson(item, index, settings, sunstatus) => OMHour(
    temp: unit_coversion(item["hourly"]["temperature_2m"][index], settings["Temperature"]).round(),
    text: translation(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index]), settings["Language"]),
    icon: oMIconCorrection(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index])),
    time: settings["Time mode"] == '12 hour'? oMamPmTime(item["hourly"]["time"][index]) : oM24hour(item["hourly"]["time"][index]),
    precip: unit_coversion(item["hourly"]["precipitation"][index], settings["Precipitation"]),
    wind: unit_coversion(item["hourly"]["wind_speed_10m"][index], settings["Wind"]),
  );
}