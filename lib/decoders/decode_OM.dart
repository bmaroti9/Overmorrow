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
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:overmorrow/Icons/overmorrow_weather_icons_icons.dart';
import 'package:overmorrow/decoders/decode_wapi.dart';

import '../caching.dart';
import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';
import 'extra_info.dart';

String OMConvertTime(String time) {
  return time.split("T")[1];
}

String OMamPmTime(String time) {
  String a = time.split("T")[1];
  List<String> num = a.split(":");
  int hour = int.parse(num[0]);
  int minute = int.parse(num[1]);

  if (hour > 12) {
    if (minute < 10) {
      return "${hour - 12}:0${minute}pm";
    }
    return "${hour - 12}:${minute}pm";
  }
  if (minute < 10) {
    return "$hour:0${minute}am";
  }
  return "$hour:${minute}am";
}

int AqiIndexCorrection(int aqi) {
  if (aqi <= 20) {
    return 1;
  }
  if (aqi <= 40) {
    return 2;
  }
  if (aqi <= 60) {
    return 3;
  }
  if (aqi <= 80) {
    return 4;
  }
  if (aqi <= 100) {
    return 5;
  }
  return 6;
}

DateTime OMGetLocalTime(item) {
  return DateTime.now().toUtc().add(Duration(seconds: item["utc_offset_seconds"]));
}

double OMGetSunStatus(item) {
  DateTime localtime = OMGetLocalTime(item);

  List<String> splitted1 = item["daily"]["sunrise"][0].split("T")[1].split(":");
  DateTime sunrise = localtime.copyWith(hour: int.parse(splitted1[0]), minute: int.parse(splitted1[1]));

  List<String> splitted2 = item["daily"]["sunset"][0].split("T")[1].split(":");
  DateTime sunset = localtime.copyWith(hour: int.parse(splitted2[0]), minute: int.parse(splitted1[1]));

  int total = sunset.difference(sunrise).inMinutes;
  int passed = localtime.difference(sunrise).inMinutes;

  return passed / total;
}

Future<List<dynamic>> OMRequestData(double lat, double lng, String real_loc) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lng.toString(),
    "minutely_15" : ["precipitation"],
    "current": ["temperature_2m", "relative_humidity_2m", "apparent_temperature", "weather_code", "wind_speed_10m", 'wind_direction_10m'],
    "hourly": ["temperature_2m", "precipitation", "weather_code", "wind_speed_10m", "wind_direction_10m", "uv_index", "precipitation_probability"],
    "daily": ["weather_code", "temperature_2m_max", "temperature_2m_min", "uv_index_max", "precipitation_sum", "precipitation_probability_max", "wind_speed_10m_max", "wind_direction_10m_dominant", "sunrise", "sunset"],
    "timezone": "auto",
    "forecast_days": "14",
    "forecast_minutely_15" : "24",
  };
  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);

  var oMFile = await cacheManager2.getSingleFile(oMUrl.toString(), key: "$real_loc, open-meteo").timeout(const Duration(seconds: 6));
  var oMResponse = await oMFile.readAsString();
  final OMData = jsonDecode(oMResponse);

  DateTime fetch_datetime = await oMFile.lastModified();

  return [OMData, fetch_datetime];
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
  String weekname = translation(weeks[time.weekday - 1], settings["Language"]);
  return "$weekname, ${time.month}/${time.day}";
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

IconData oMIconCorrection(String text) {
  //return textIconMap[text] ?? 'sun.png';
  return textMaterialIcon[text] ?? OvermorrowWeatherIcons.sun2;
}


double oMIconSizeCorrection(String text) {
  //return textIconMap[text] ?? 'sun.png';
  return textIconSizeNormalize[text] ?? 1;
}


class OMCurrent {
  final String text;
  final int temp;
  final int humidity;
  final int feels_like;
  final int uv;
  final double precip;

  final int wind;
  final int wind_dir;

  final Color surface;
  final Color primary;
  final Color primaryLight;
  final Color primaryLighter;
  final Color onSurface;
  final Color outline;
  final Color containerLow;
  final Color container;
  final Color containerHigh;
  final Color colorPop;
  final Color descColor;
  final Color surfaceVariant;
  final Color onPrimaryLight;
  final Color primarySecond;

  final Color backup_primary;
  final Color backup_backcolor;

  final Image image;

  const OMCurrent({
    required this.precip,
    required this.humidity,
    required this.feels_like,
    required this.temp,
    required this.text,
    required this.uv,
    required this.wind,
    required this.backup_backcolor,
    required this.backup_primary,
    required this.wind_dir,

    required this.surface,
    required this.primary,
    required this.primaryLight,
    required this.primaryLighter,
    required this.onSurface,
    required this.outline,
    required this.containerLow,
    required this.container,
    required this.containerHigh,
    required this.colorPop,
    required this.descColor,
    required this.surfaceVariant,
    required this.onPrimaryLight,
    required this.primarySecond,

    required this.image,
  });

  static Future<OMCurrent> fromJson(item, settings, sunstatus, timenow, real_loc, lat, lng) async {

    //GET IMAGE
    Image Uimage;

    if (settings["Image source"] == "network") {
      Uimage = await getUnsplashImage(oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow), real_loc, lat, lng);
    }
    else {
      String imagePath = oMBackdropCorrection(
        oMCurrentTextCorrection(
            item["current"]["weather_code"], sunstatus, timenow),
      );
      Uimage = Image.asset("assets/backdrops/$imagePath", fit: BoxFit.cover,
        width: double.infinity, height: double.infinity,);
    }

    Color back = BackColorCorrection(
      oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow),
    );

    Color primary = PrimaryColorCorrection(
      oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow),
    );

    List<Color> colors = await getMainColor(settings, primary, back, Uimage);

    return OMCurrent(
      image: Uimage,

      text: translation(oMCurrentTextCorrection(
          item["current"]["weather_code"], sunstatus, timenow),
          settings["Language"]),
      uv: item["daily"]["uv_index_max"][0].round(),
      feels_like: unit_coversion(
          item["current"]["apparent_temperature"], settings["Temperature"])
          .round(),

      surface: colors[0],
      primary: colors[1],
      primaryLight: colors[2],
      primaryLighter: colors[3],
      onSurface: colors[4],
      outline: colors[5],
      containerLow: colors[6],
      container: colors[7],
      containerHigh: colors[8],
      surfaceVariant: colors[9],
      onPrimaryLight: colors[10],
      primarySecond: colors[11],

      colorPop: colors[12],
      descColor: colors[13],

      backup_backcolor: back,
      backup_primary: primary,

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

  final IconData icon;
  final double iconSize;

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
    required this.iconSize,

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
      iconSize: oMIconSizeCorrection(oMTextCorrection(item["daily"]["weather_code"][index])),
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

class OM15MinutePrecip {
  final String t_minus;
  final double precip_sum;
  final List<double> precips;

  const OM15MinutePrecip({
    required this.t_minus,
    required this.precip_sum,
    required this.precips,
  });

  static OM15MinutePrecip fromJson(item, settings) {

    int closest = 100;
    int end = -1;
    double sum = 0;

    List<double> precips = [];

    for (int i = 0; i < item["minutely_15"]["precipitation"].length; i++) {
      double x = item["minutely_15"]["precipitation"][i];
      if (x > 0.0) {
        if (closest == 100) {
          closest = i + 1;
        }
        if (i > end) {
          end = i + 1;
        }
      }
      sum += x;

      precips.add(x);
    }

    print(("closest", closest));

    sum = max(sum, 0.1); //if there is rain then it shouldn't write 0

    String t_minus = "";
    if (closest != 100) {
      if (closest <= 2) {
        if (end == 2) {
          t_minus = "the next half an hour";
        }
        else if (end < 4) {
          t_minus = "the next ${[15, 30, 45][end - 1]} minutes";
        }
        else if (end ~/ 4 == 1) {
          t_minus = "the next 1 hour";
        }
        else {
          t_minus = "the next ${end ~/ 4} hours";
        }
      }
      else if (closest < 4) {
        t_minus = "${[15, 30, 45][closest - 1]} minutes";
      }
      else if (closest ~/ 4 == 1) {
        t_minus = "1 hour";
      }
      else {
        t_minus = "${closest ~/ 4} hours";
      }
    }

    return OM15MinutePrecip(
      t_minus: t_minus,
      precip_sum: unit_coversion(sum, settings["Precipitation"]),
      precips: precips,
    );
  }
}

class OMHour {
  final int temp;

  final IconData icon;
  final double iconSize;

  final String time;
  final String text;
  final double precip;
  final int precip_prob;
  final double wind;
  final int wind_dir;
  final int uv;

  final double raw_temp;
  final double raw_precip;
  final double raw_wind;

  const OMHour({
    required this.temp,
    required this.time,
    required this.icon,
    required this.text,
    required this.precip,
    required this.wind,
    required this.iconSize,
    required this.raw_precip,
    required this.raw_temp,
    required this.raw_wind,
    required this.wind_dir,
    required this.uv,
    required this.precip_prob,
  });

  static OMHour fromJson(item, index, settings, sunstatus) => OMHour(
    temp: unit_coversion(item["hourly"]["temperature_2m"][index], settings["Temperature"]).round(),
    text: translation(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index]), settings["Language"]),
    icon: oMIconCorrection(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index])),
    iconSize: oMIconSizeCorrection(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus, item["hourly"]["time"][index])),
    time: settings["Time mode"] == '12 hour'? oMamPmTime(item["hourly"]["time"][index]) : oM24hour(item["hourly"]["time"][index]),

    precip: unit_coversion(item["hourly"]["precipitation"][index], settings["Precipitation"]),
    precip_prob: item["hourly"]["precipitation_probability"][index],
    wind: double.parse(
        unit_coversion(item["hourly"]["wind_speed_10m"][index], settings["Wind"]).toStringAsFixed(1)),
    wind_dir: item["hourly"]["wind_direction_10m"][index],
    uv: item["hourly"]["uv_index"][index].round(),

    raw_precip: item["hourly"]["precipitation"][index],
    raw_temp: item["hourly"]["temperature_2m"][index],
    raw_wind: item["hourly"]["wind_speed_10m"][index],
  );
}

class OMSunstatus {
  final String sunrise;
  final String sunset;
  final double sunstatus;
  final String absoluteSunriseSunset;

  const OMSunstatus({
    required this.sunrise,
    required this.sunstatus,
    required this.sunset,
    required this.absoluteSunriseSunset,
  });

  static OMSunstatus fromJson(item, settings) => OMSunstatus(
    sunrise: settings["Time mode"] == "24 hour"
        ? OMConvertTime(item["daily"]["sunrise"][0])
        : OMamPmTime(item["daily"]["sunrise"][0]),
    sunset: settings["Time mode"] == "24 hour"
        ? OMConvertTime(item["daily"]["sunrise"][0])
        : OMamPmTime(item["daily"]["sunset"][0]),
    absoluteSunriseSunset: "${OMConvertTime(item["daily"]["sunrise"][0])}/"
        "${OMConvertTime(item["daily"]["sunset"][0])}",
    sunstatus: OMGetSunStatus(item)
  );
}

class OMAqi{
  final int aqi_index;
  final double pm2_5;
  final double pm10;
  final double o3;
  final double no2;
  final String aqi_title;
  final String aqi_desc;

  const OMAqi({
    required this.no2,
    required this.o3,
    required this.pm2_5,
    required this.pm10,
    required this.aqi_index,
    required this.aqi_desc,
    required this.aqi_title,
  });

  static Future<OMAqi> fromJson(item, lat, lng) async {
    final params = {
      "latitude": lat.toString(),
      "longitude": lng.toString(),
      "current": ["european_aqi", "pm10", "pm2_5", "nitrogen_dioxide", 'ozone'],
    };
    final url = Uri.https("air-quality-api.open-meteo.com", 'v1/air-quality', params);
    var file = await cacheManager2.getSingleFile(url.toString(), key: "$lat, $lng, aqi open-meteo").timeout(const Duration(seconds: 6));
    var response = await file.readAsString();
    final item = jsonDecode(response)["current"];

    int index = AqiIndexCorrection(item["european_aqi"]);

    return OMAqi(
      aqi_index: index,
      pm10: item["pm10"],
      pm2_5: item["pm2_5"],
      no2: item["nitrogen_dioxide"],
      o3: item["ozone"],

      aqi_title: ['good', 'fair', 'moderate', 'poor', 'very poor', 'unhealthy']
      [index - 1],

      aqi_desc: ['Air quality is excellent; no health risk.',
        'Acceptable air quality; minor risk for sensitive people.',
        'Sensitive individuals may experience mild effects.',
        'Health effects possible for everyone, serious for sensitive groups.',
        'Serious health effects for everyone.',
        'Emergency conditions; severe health effects for all.']
      [index - 1],
    );
  }
}

Future<WeatherData> OMGetWeatherData(lat, lng, real_loc, settings, placeName) async {
  var OM = await OMRequestData(lat, lng, real_loc);
  var oMBody = OM[0];

  DateTime fetch_datetime = OM[1];

  OMSunstatus sunstatus = OMSunstatus.fromJson(oMBody, settings);

  List<OMDay> days = [];
  for (int n = 0; n < 14; n++) {
    OMDay x = OMDay.build(oMBody, settings, n, sunstatus);
    days.add(x);
  }

  DateTime localtime = OMGetLocalTime(oMBody);
  String real_time = "jT${localtime.hour}:${localtime.minute}";

  return WeatherData(
    radar: await RainviewerRadar.getData(),
    aqi: await OMAqi.fromJson(oMBody, lat, lng),
    sunstatus: sunstatus,
    minutely_15_precip: OM15MinutePrecip.fromJson(oMBody, settings),

    current: await OMCurrent.fromJson(oMBody, settings, sunstatus, real_time, real_loc, lat, lng),
    days: days,

    lat: lat,
    lng: lng,

    place: placeName,
    settings: settings,
    provider: "open-meteo",
    real_loc: real_loc,

    fetch_datetime: fetch_datetime,
    updatedTime: DateTime.now(),
    localtime: real_time.split("T")[1],
    );
}