/*
Copyright (C) <2025>  <Balint Maroti>

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
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overmorrow/Icons/overmorrow_weather_icons3_icons.dart';
import 'package:overmorrow/decoders/decode_wapi.dart';
import 'package:overmorrow/services/image_service.dart';
import '../l10n/app_localizations.dart';

import '../caching.dart';
import '../services/color_service.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';
import 'decode_RV.dart';
import 'weather_data.dart';

String OMConvertTime(String time) {
  return time.split("T")[1];
}

String OmAqiDesc(index, localizations) {
  return [
    localizations.goodAqiDesc,
    localizations.fairAqiDesc,
    localizations.moderateAqiDesc,
    localizations.poorAqiDesc,
    localizations.veryPoorAqiDesc,
    localizations.unhealthyAqiDesc,
  ][index - 1];
}

String OmAqiTitle(index, localizations) {
  return [
    localizations.good,
    localizations.fair,
    localizations.moderate,
    localizations.poor,
    localizations.veryPoor,
    localizations.unhealthy,
  ][index - 1];
}

List<double> omGetMaxMinTempForDaily(days) {
  double minTemp = 100;
  double maxTemp = -100;
  for (int i = 0; i < days.length; i++) {
    if (days[i].rawMinTemp < minTemp) {
      minTemp = days[i].rawMinTemp;
    }
    if (days[i].rawMaxTemp > maxTemp) {
      maxTemp = days[i].rawMaxTemp;
    }
  }
  return [minTemp, maxTemp];
}

String OMamPmTime(String time) {
  String a = time.split("T")[1];
  List<String> num = a.split(":");
  int hour = int.parse(num[0]);
  int minute = int.parse(num[1]);

  if (hour == 0) {
    return "0:${minute.toString().padLeft(2, "0")}am";
  }
  if (hour == 12) {
    return "12:${minute.toString().padLeft(2, "0")}pm";
  }

  if (hour > 12) {
    return "${hour - 12}:${minute.toString().padLeft(2, "0")}pm";
  }
  return "$hour:${minute.toString().padLeft(2, "0")}am";
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
  DateTime localTime = DateTime.now().toUtc().add(Duration(seconds: item["utc_offset_seconds"]));
  return localTime;
}

double OMGetSunStatus(item) {
  DateTime localtime = OMGetLocalTime(item);

  List<String> splitted1 = item["daily"]["sunrise"][0].split("T")[1].split(":");
  DateTime sunrise = localtime.copyWith(hour: int.parse(splitted1[0]), minute: int.parse(splitted1[1]));

  List<String> splitted2 = item["daily"]["sunset"][0].split("T")[1].split(":");
  DateTime sunset = localtime.copyWith(hour: int.parse(splitted2[0]), minute: int.parse(splitted2[1]));

  int total = sunset.difference(sunrise).inMinutes;
  int passed = localtime.difference(sunrise).inMinutes;

  return min(1, max(passed / total, 0));
}

Future<List<dynamic>> OMRequestData(double lat, double lng, String real_loc) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lng.toString(),
    "minutely_15" : ["precipitation"],
    "current": ["temperature_2m", "weather_code", "relative_humidity_2m", "apparent_temperature"],
    "hourly": ["temperature_2m", "precipitation", "weather_code", "wind_speed_10m", "wind_direction_10m", "uv_index", "precipitation_probability", "wind_gusts_10m"],
    "daily": ["weather_code", "temperature_2m_max", "temperature_2m_min", "uv_index_max", "precipitation_sum", "precipitation_probability_max", "wind_speed_10m_max", "wind_direction_10m_dominant", "sunrise", "sunset"],
    "timezone": "auto",
    "forecast_days": "14",
    "forecast_minutely_15" : "24",
  };

  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);
  //print(oMUrl);

  //var oMFile = await cacheManager2.getSingleFile(oMUrl.toString(), key: "$real_loc, open-meteo").timeout(const Duration(seconds: 6));
  var oMFile = await XCustomCacheManager.fetchData(oMUrl.toString(), "$real_loc, open-meteo");

  var oMResponse = await oMFile[0].readAsString();
  final OMData = jsonDecode(oMResponse);

  DateTime fetch_datetime = await oMFile[0].lastModified();
  bool isonline = oMFile[1];

  return [OMData, fetch_datetime, isonline];
}

String oMGetName(index, settings, item, dayDif, localizations) {
  String x = item["daily"]["time"][index].split("T")[0];
  List<String> z = x.split("-");
  DateTime time = DateTime(int.parse(z[0]), int.parse(z[1]), int.parse(z[2]));
  List<String> weeks = [
    localizations.mon,
    localizations.tue,
    localizations.wed,
    localizations.thu,
    localizations.fri,
    localizations.sat,
    localizations.sun
  ];
  String weekname = weeks[time.weekday - 1];
  final String date = settings["Date format"] == "mm/dd" ? "${time.month}/${time.day}"
      :"${time.day}/${time.month}";
  return "$weekname, $date";
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

String oMCurrentTextCorrection(int code, absoluteSunriseSunset, time) {
  String t = time.contains("T") ? time.split("T")[1] : time.split(" ")[1];
  int minute = int.parse(t.split(":")[1]);
  int hour = int.parse(t.split(":")[0]);

  List<String> x = absoluteSunriseSunset.split("/");
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
  return textMaterialIcon[text] ?? OvermorrowWeatherIcons3.clear_sky;
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

  final ImageService imageService;

  final ColorScheme palette;
  final Color colorPop;
  final Color descColor;
  final List<Color> debugColors;

  const OMCurrent({
    required this.precip,
    required this.humidity,
    required this.feels_like,
    required this.temp,
    required this.text,
    required this.uv,
    required this.wind,
    required this.wind_dir,

    required this.imageService,

    required this.palette,
    required this.colorPop,
    required this.descColor,
    required this.debugColors,
  });

  static Future<OMCurrent> fromJson(item, settings, sunstatus, timenow, real_loc, lat, lng, start, dayDif, context, isonline) async {

    String currentCondition = oMCurrentTextCorrection(
        item["current"]["weather_code"], sunstatus.absoluteSunriseSunset, timenow);

    //offline mode
    if (!isonline) {
      currentCondition = oMCurrentTextCorrection(
          item["hourly"]["weather_code"][start], sunstatus.absoluteSunriseSunset, timenow);
    }

    ImageService imageService = await ImageService.getImageService(currentCondition, real_loc, settings);
    ColorPalette colorPalette = await ColorPalette.getColorPalette(imageService.image, settings["Color mode"], settings);

    return OMCurrent(
      imageService: imageService,

      palette: colorPalette.palette,
      colorPop: colorPalette.colorPop,
      descColor: colorPalette.descColor,
      debugColors: colorPalette.imageColors,

      text: conditionTranslation(currentCondition, context) ?? "TranslationErr",
      uv: item["daily"]["uv_index_max"][dayDif].round(),
      feels_like: unit_coversion(
          item["current"]["apparent_temperature"], settings["Temperature"])
          .round(),

      precip: double.parse(unit_coversion(
          item["daily"]["precipitation_sum"][dayDif], settings["Precipitation"])
          .toStringAsFixed(1)),
      wind: unit_coversion(item["hourly"]["wind_speed_10m"][start], settings["Wind"]).round(),
      humidity: item["current"]["relative_humidity_2m"],
      temp: unit_coversion(
        isonline ? item["current"]["temperature_2m"] : item["hourly"]["temperature_2m"][start],
        settings["Temperature"]).round(),
      wind_dir: item["hourly"]["wind_direction_10m"][start],
    );
  }
}


class OMDay {
  final String text;

  final IconData icon;

  final String name;

  final int minTemp;
  final int maxTemp;
  final double rawMinTemp; //the unconverted numbers used for charts
  final double rawMaxTemp;

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

    required this.minTemp,
    required this.maxTemp,
    required this.rawMinTemp,
    required this.rawMaxTemp,

    required this.hourly,

    required this.precip_prob,
    required this.total_precip,
    required this.windspeed,
    required this.hourly_for_precip,
    required this.mm_precip,
    required this.uv,
    required this.wind_dir,
  });

  static OMDay? build(item, settings, index, sunstatus, approximatelocal, dayDif, localizations) {

    List<OMHour> hours = buildHours(index, true, item, settings, sunstatus, approximatelocal, localizations);

    if (hours.isNotEmpty) {
      return OMDay(
        uv: item["daily"]["uv_index_max"][index].round(),
        icon: oMIconCorrection(oMTextCorrection(item["daily"]["weather_code"][index])),
        text: conditionTranslation(oMTextCorrection(item["daily"]["weather_code"][index]), localizations) ?? "TranslationErr",
        name: oMGetName(index, settings, item, dayDif, localizations),
        windspeed: unit_coversion(item["daily"]["wind_speed_10m_max"][index], settings["Wind"]).round(),
        total_precip: double.parse(unit_coversion(item["daily"]["precipitation_sum"][index], settings["Precipitation"]).toStringAsFixed(1)),

        minTemp: unit_coversion(item["daily"]["temperature_2m_min"][index], settings["Temperature"]).round(),
        maxTemp: unit_coversion(item["daily"]["temperature_2m_max"][index], settings["Temperature"]).round(),
        rawMinTemp: item["daily"]["temperature_2m_min"][index],
        rawMaxTemp: item["daily"]["temperature_2m_max"][index],

        precip_prob: item["daily"]["precipitation_probability_max"][index] ?? 0,
        mm_precip: item["daily"]["precipitation_sum"][index],
        hourly_for_precip: buildHours(index, false, item, settings, sunstatus, approximatelocal, localizations),
        hourly: hours,
        wind_dir: item["daily"]["wind_direction_10m_dominant"][index] ?? 0,
      );
    }
    return null;

  }

  static List<OMHour> buildHours(index, get_rid_first, item, settings, sunstatus, approximatelocal, localizations) {
    List<OMHour> hourly = [];

    int l = item["hourly"]["weather_code"].length;

    for (var i = 0; i < 24; i++) {
      int j = index * 24 + i;
      DateTime hour = DateTime.parse(item["hourly"]["time"][j]);
      if ((approximatelocal.difference(hour).inMinutes <= 0 || !get_rid_first) && l > j) {
        hourly.add(OMHour.fromJson(item, j, settings, sunstatus, localizations));
      }
    }
    return hourly;
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

  static OM15MinutePrecip fromJson(item, settings, minuteOffset, AppLocalizations localizations) {

    int closest = 100;
    int end = -1;
    double sum = 0;

    List<double> precips = [];

    int offset15 = minuteOffset ~/ 15;

    print(("offset 15", offset15, minuteOffset));

    for (int i = offset15; i < item["minutely_15"]["precipitation"].length; i++) {
      double x = item["minutely_15"]["precipitation"][i];
      if (x > 0.0) {
        if (closest == 100) {
          closest = i;
        }
        if (i > end) {
          end = i;
        }
      }
      sum += x;

      precips.add(x);
    }

    //make it still be the same length so it doesn't mess up the labeling
    for (int i = 0; i < offset15; i++) {
      precips.add(0);
    }

    sum = max(sum, 0.1); //if there is rain then it shouldn't write 0

    String t_minus = "";
    if (closest != 100) {
      if (closest <= 1) {
        if (end == 1) {
          t_minus = localizations.rainInHalfHour;
        }
        else if (end <= 2) {
          int x = [15, 30, 45][end];
          t_minus = localizations.rainInMinutes(x);
        }
        else if (end ~/ 4 == 1) {
          t_minus = localizations.rainInOneHour;
        }
        else {
          int x = (end + 2) ~/ 4;
          t_minus = localizations.rainInHours(x);
        }
      }
      else if (closest < 4) {
        int x = [15, 30, 45][closest - 1];
        t_minus = localizations.rainExpectedInMinutes(x);
      }
      else if ((closest + 2) ~/ 4 == 1) {
        t_minus = localizations.rainExpectedInOneHour;
      }
      else {
        int x = (closest + 2) ~/ 4;
        t_minus = localizations.rainExpectedInHours(x);
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

  final String time;

  final String text;
  final double precip;
  final int precip_prob;
  final double wind;
  final int wind_dir;
  final int wind_gusts;
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
    required this.raw_precip,
    required this.raw_temp,
    required this.raw_wind,
    required this.wind_dir,
    required this.wind_gusts,
    required this.uv,
    required this.precip_prob,
  });

  static OMHour fromJson(item, index, settings, sunstatus, localizations) => OMHour(
    temp: unit_coversion(item["hourly"]["temperature_2m"][index], settings["Temperature"]).round(),
    text: conditionTranslation(
        oMCurrentTextCorrection(
            item["hourly"]["weather_code"][index], sunstatus.absoluteSunriseSunset, item["hourly"]["time"][index]
        ),
        localizations
    ) ?? "TranslationErr",
    icon: oMIconCorrection(oMCurrentTextCorrection(item["hourly"]["weather_code"][index],
        sunstatus.absoluteSunriseSunset, item["hourly"]["time"][index])),
    time: settings["Time mode"] == '12 hour'? oMamPmTime(item["hourly"]["time"][index]) : oM24hour(item["hourly"]["time"][index]),

    precip: double.parse(
        unit_coversion(item["hourly"]["precipitation"][index], settings["Precipitation"]).toStringAsFixed(1)),

    precip_prob: item["hourly"]["precipitation_probability"][index] ?? 0,
    wind: double.parse(
        unit_coversion(item["hourly"]["wind_speed_10m"][index], settings["Wind"]).toStringAsFixed(1)),
    wind_gusts: unit_coversion(item["hourly"]["wind_gusts_10m"][index], settings["Wind"]).toInt(),
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
        ? OMConvertTime(item["daily"]["sunset"][0])
        : OMamPmTime(item["daily"]["sunset"][0]),
    absoluteSunriseSunset: "${OMConvertTime(item["daily"]["sunrise"][0])}/"
        "${OMConvertTime(item["daily"]["sunset"][0])}",
    sunstatus: OMGetSunStatus(item)
  );
}

class OMAqi{
  final int aqi_index;

  final String aqi_desc;
  final String aqi_title;

  const OMAqi({
    required this.aqi_desc,
    required this.aqi_title,
    required this.aqi_index,
  });

  static Future<OMAqi> fromJson(lat, lng, settings, localizations) async {
    final params = {
      "latitude": lat.toString(),
      "longitude": lng.toString(),
      "current": ["european_aqi"],
    };
    final url = Uri.https("air-quality-api.open-meteo.com", 'v1/air-quality', params);


    //var file = await cacheManager2.getSingleFile(url.toString(), key: "$lat, $lng, aqi open-meteo").timeout(const Duration(seconds: 6));
    var file = await XCustomCacheManager.fetchData(url.toString(), "$lat, $lng, aqi open-meteo");

    var response = await file[0].readAsString();
    final item = jsonDecode(response)["current"];

    int index = AqiIndexCorrection(item["european_aqi"]);

    return OMAqi(
      aqi_index: index,

      aqi_title: OmAqiTitle(index, localizations),

      aqi_desc: OmAqiDesc(index, localizations),
    );
  }
}


class OMExtendedAqi{ //this data will only be called if you open the Air quality page
                      //this is done to reduce the amount of unused calls to the open-meteo servers

  final double pm2_5;
  final double pm10;
  final double o3;
  final double no2;
  final double co;
  final double so2;

  //percent
  final double pm2_5_p;
  final double pm10_p;
  final double o3_p;
  final double no2_p;
  final double co_p;
  final double so2_p;

  final double alder;
  final double birch;
  final double grass;
  final double mugwort;
  final double olive;
  final double ragweed;

  //hourly
  final List<double> pm2_5_h;
  final List<double> pm10_h;
  final List<double> no2_h;
  final List<double> o3_h;
  final List<double> co_h;
  final List<double> so2_h;

  final String mainPollutant;

  final List<int> dailyAqi;

  final int european_aqi;
  final int us_aqi;
  final String european_desc;
  final String us_desc;

  final double aod;
  final String aod_desc;

  final double dust;

  const OMExtendedAqi({
    required this.no2,
    required this.o3,
    required this.pm2_5,
    required this.pm10,
    required this.co,
    required this.so2,

    required this.alder,
    required this.birch,
    required this.grass,
    required this.mugwort,
    required this.olive,
    required this.ragweed,

    required this.aod,
    required this.aod_desc,

    required this.dust,

    required this.european_aqi,
    required this.us_aqi,
    required this.european_desc,
    required this.us_desc,

    required this.no2_h,
    required this.o3_h,
    required this.pm2_5_h,
    required this.pm10_h,
    required this.co_h,
    required this.so2_h,

    required this.pm2_5_p,
    required this.pm10_p,
    required this.o3_p,
    required this.no2_p,
    required this.co_p,
    required this.so2_p,

    required this.dailyAqi,

    required this.mainPollutant,
  });

  static Future<OMExtendedAqi> fromJson(lat, lng, settings, AppLocalizations localizations) async {

    final params = {
      "latitude": lat.toString(),
      "longitude": lng.toString(),
      "current": ['carbon_monoxide', 'sulphur_dioxide', "pm10", "pm2_5", "nitrogen_dioxide", "ozone",
        'alder_pollen', 'birch_pollen', 'grass_pollen', 'mugwort_pollen', 'olive_pollen', 'ragweed_pollen',
        'aerosol_optical_depth', 'dust', 'european_aqi', 'us_aqi'],
      "hourly" : ["pm10", "pm2_5", "nitrogen_dioxide", "ozone", "sulphur_dioxide", "carbon_monoxide"],
      "timezone": "auto",
      "forecast_days" : "5",
    };
    final url = Uri.https("air-quality-api.open-meteo.com", 'v1/air-quality', params);

    //var file = await cacheManager2.getSingleFile(url.toString(), key: "$lat, $lng, aqi open-meteo extended").timeout(const Duration(seconds: 3));
    var file = await XCustomCacheManager.fetchData(url.toString(), "$lat, $lng, aqi-extended open-meteo");

    var response = await file[0].readAsString();
    final item = jsonDecode(response);

    final no2_h = List<double>.from((item["hourly"]["nitrogen_dioxide"] as List?) ?.map((e) => (e as double?) ?? 0.0) ?? []);
    final o3_h = List<double>.from((item["hourly"]["ozone"] as List?) ?.map((e) => (e as double?) ?? 0.0) ?? []);
    final pm2_5_h = List<double>.from((item["hourly"]["pm2_5"] as List?) ?.map((e) => (e as double?) ?? 0.0) ?? []);
    final pm10_h = List<double>.from((item["hourly"]["pm10"] as List?) ?.map((e) => (e as double?) ?? 0.0) ?? []);
    final co_h = List<double>.from((item["hourly"]["carbon_monoxide"] as List?) ?.map((e) => (e as double?) ?? 0.0) ?? []);
    final so2_h = List<double>.from((item["hourly"]["sulphur_dioxide"] as List?) ?.map((e) => (e as double?) ?? 0.0) ?? []);


    //determine the individual air quality indexes for each day using the hourly values of the different contaminants
    // https://www.airnow.gov/publications/air-quality-index/technical-assistance-document-for-reporting-the-daily-aqi/

    const List<int> aqiCategories = [0, 51, 101, 151, 201, 301, 500];
    const List<int> europeanAqiCategories = [0, 26, 51, 151, 76, 101, 500];
    const List<String> pollutantNames = ["ozone", "pm2.5", "pm10", "carbon monoxide", "sulphur dioxide", "nitrogen dioxide"];
    const List<List<double>> breakpoints = [
      [0, 0.055, 0.071, 0.086, 0.106, 0.201, 0.604], //o3
      [0, 9.1, 35.5, 55.5, 125.5, 225.5, 325.4], //pm2.5
      [0, 55, 155, 255, 355, 425, 604], //pm10
      [0, 4.5, 9.5, 12.5, 15.5, 30.5, 50.4], //co
      [0, 36, 76, 186, 305, 605, 1004], //so2
      [0, 54, 101, 361, 650, 1250, 2049] //no2
    ];
    
    List<int> dailyAqi = [];
    String mainPollutant = "hehe";
    for (int i = 0; i < item["hourly"]["pm2_5"].length / 24; i++) {
      //some of the values in the documentation are in ppm so open-meteo's mg/m^3 data has to be converted to ppm
      //https://teesing.com/en/tools/ppm-mg3-converter <- used this as a reference
      //the division by 1000 is because is because we're converting micrograms to grams

      List<double> values = [
        double.parse((o3_h.getRange(i * 24, (i + 1) * 24).reduce(max) * 24.45 / 48 / 1000).toStringAsFixed(3)),
        double.parse(pm2_5_h.getRange(i * 24, (i + 1) * 24).reduce(max).toStringAsFixed(1)),
        double.parse(pm10_h.getRange(i * 24, (i + 1) * 24).reduce(max).toStringAsFixed(0)),
        double.parse((co_h.getRange(i * 24, (i + 1) * 24).reduce(max) * 24.45 / 28.01 / 1000).toStringAsFixed(1)),
        double.parse((so2_h.getRange(i * 24, (i + 1) * 24).reduce(max) * 24.45 / 64.066 / 1000).toStringAsFixed(0)),
        double.parse((no2_h.getRange(i * 24, (i + 1) * 24).reduce(max) * 24.45 / 46.0055 / 1000).toStringAsFixed(0)),
      ];

      List<int> final_indexes = [];

      for (int x = 0; x < 6; x++) {

        double current = values[x];

        //find the above and below breakpoints
        double bp_hi = 1;
        double bp_lo = 0;

        int i_hi = 1;
        int i_lo = 0;

        for (int z = 0; z < breakpoints[x].length - 1; z++) {
          if (current >= breakpoints[x][z]) {
            bp_lo = breakpoints[x][z];
            bp_hi = breakpoints[x][z + 1];

            i_lo = aqiCategories[z];
            i_hi = aqiCategories[z + 1];
          }
        }

        int final_index = (((i_hi - i_lo) / (bp_hi - bp_lo)) * (current - bp_lo) + i_lo).round();
        final_indexes.add(final_index);
      }
      int biggest = final_indexes.reduce(max);

      //determine the main pollutant for today
      if (i == 0) {
        mainPollutant = pollutantNames[final_indexes.indexOf(biggest)];
      }

      dailyAqi.add(biggest);
    }

    final aod_names = [
      localizations.extremelyHazy,
      localizations.veryClear,
      localizations.clear,
      localizations.slightlyHazy,
      localizations.haze,
      localizations.veryHazy,
      localizations.extremelyHazy
    ];
    const aod_breakpoints = [0, 0.05, 0.1, 0.2, 0.4, 0.7, 1.0];

    final aod_value = item["current"]["aerosol_optical_depth"];

    int aod_index = 0;
    for (int i = 0; i < aod_breakpoints.length; i++) {
      if (aod_value > aod_breakpoints[i])  {
        aod_index = i;
      }
    }

    final String aod_desc = aod_names[aod_index];

    int usIndex = 0;
    int europeanIndex = 0;
    for (int i = 0; i < aqiCategories.length; i++) {
      if (item["current"]["european_aqi"] > aqiCategories[i])  {
        usIndex = i;
      }
      if (item["current"]["us_aqi"] > europeanAqiCategories[i])  {
        europeanIndex = i;
      }
    }

    String usDesc = OmAqiTitle(usIndex + 1, localizations); //because the function expects values between 1 and something
    String europeanDesc = OmAqiTitle(europeanIndex + 1, localizations);

    return OMExtendedAqi(
      pm10: item["current"]["pm10"],
      pm2_5: item["current"]["pm2_5"],
      no2: item["current"]["nitrogen_dioxide"],
      o3: item["current"]["ozone"],
      co: item["current"]["carbon_monoxide"],
      so2: item["current"]["sulphur_dioxide"],

      alder: item["current"]["alder_pollen"] ?? -1,
      birch: item["current"]["birch_pollen"] ?? -1,
      grass: item["current"]["grass_pollen"] ?? -1,
      mugwort: item["current"]["mugwort_pollen"] ?? -1,
      olive: item["current"]["olive_pollen"] ?? -1,
      ragweed: item["current"]["ragweed_pollen"] ?? -1,

      aod: aod_value,
      aod_desc: aod_desc,

      dust: item["current"]["dust"],

      no2_h: no2_h,
      o3_h: o3_h,
      pm2_5_h: pm2_5_h,
      pm10_h: pm10_h,
      co_h: co_h,
      so2_h: so2_h,

      mainPollutant: mainPollutant,

      dailyAqi: dailyAqi,

      european_aqi: item["current"]["european_aqi"],
      us_aqi: item["current"]["us_aqi"],
      us_desc: usDesc,
      european_desc: europeanDesc,

      //i am looking at the one before last because the last is basically only for calculating the high
      //and not actually expected to be reached
      o3_p: o3_h[0] * 24.45 / 48 / 1000 / breakpoints[0][breakpoints[0].length - 2] * 100,
      pm2_5_p: pm2_5_h[0] / breakpoints[1][breakpoints[1].length - 2] * 100,
      pm10_p: pm10_h[0] / breakpoints[2][breakpoints[2].length - 2] * 100,
      co_p: co_h[0] * 24.45 / 28.01 / 1000 / breakpoints[3][breakpoints[3].length - 2] * 100,
      so2_p: so2_h[0] * 24.45 / 64.066 / 1000 / breakpoints[4][breakpoints[4].length - 2] * 100,
      no2_p: no2_h[0] * 24.45 / 46.0055 / 1000 / breakpoints[5][breakpoints[5].length - 2] * 100,
    );
  }
}

Future<WeatherData> OMGetWeatherData(lat, lng, real_loc, settings, placeName, localizations) async {

  var OM = await OMRequestData(lat, lng, real_loc);
  var oMBody = OM[0];

  DateTime fetch_datetime = OM[1];
  bool isonline = OM[2];

  DateTime localtime = OMGetLocalTime(oMBody);

  String real_time = "jT${localtime.hour}:${localtime.minute}";

  DateTime lastKnowTime = DateTime.parse(oMBody["current"]["time"]);

  //get hour diff
  DateTime approximateLocal = DateTime(localtime.year, localtime.month, localtime.day, localtime.hour);
  int start = approximateLocal.difference(DateTime(lastKnowTime.year,
      lastKnowTime.month, lastKnowTime.day)).inHours;

  //get day diff
  int dayDif = DateTime(localtime.year, localtime.month, localtime.day).difference(
      DateTime(lastKnowTime.year, lastKnowTime.month, lastKnowTime.day)).inDays;

  //make sure that there is data left
  if (dayDif >= oMBody["daily"]["weather_code"].length) {
    throw const SocketException("Cached data expired");
  }

  OMSunstatus sunstatus = OMSunstatus.fromJson(oMBody, settings);

  List<OMDay> days = [];
  List<dynamic> hourly72 = [];

  for (int n = 0; n < 14; n++) {
    OMDay? day = OMDay.build(oMBody, settings, n, sunstatus, approximateLocal, dayDif, localizations);
    if (day != null) {
      days.add(day);
      if (hourly72.length < 72) {
        if (n != 0) {
          hourly72.add(day.name);
        }
        for (int z = 0; z < day.hourly.length; z++) {
          if (hourly72.length < 72) {
            hourly72.add(day.hourly[z]);
          }
        }
      }
    }
  }

  return WeatherData(
    radar: await RainviewerRadar.getData(),
    aqi: await OMAqi.fromJson(lat, lng, settings, localizations),
    sunstatus: sunstatus,
    minutely_15_precip: OM15MinutePrecip.fromJson(oMBody, settings,
        DateTime(localtime.year, localtime.month, localtime.day, localtime.hour, localtime.minute).
        difference(lastKnowTime).inMinutes, localizations),
    alerts: [],

    dailyMinMaxTemp: omGetMaxMinTempForDaily(days),

    hourly72: hourly72,

    current: await OMCurrent.fromJson(oMBody, settings, sunstatus, real_time, real_loc, lat, lng,
        start, dayDif, localizations, isonline),
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
    isonline: isonline,
  );
}

Future<LightCurrentWeatherData> omGetLightCurrentData(settings, placeName, lat, lon) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lon.toString(),
    "current": ["temperature_2m", "weather_code"],
    "daily": ["sunrise", "sunset"],
    "forecast_days": "1",
    "timezone": "auto",
  };

  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);
  final response = (await http.get(oMUrl)).body;

  final item = jsonDecode(response);

  DateTime localtime = OMGetLocalTime(item);
  String realTime = "jT${localtime.hour}:${localtime.minute}";
  DateTime now = DateTime.now();

  final absoluteSunriseSunset =  "${OMConvertTime(item["daily"]["sunrise"][0])}/"
      "${OMConvertTime(item["daily"]["sunset"][0])}";

  return LightCurrentWeatherData(
    condition: oMCurrentTextCorrection(item["current"]["weather_code"], absoluteSunriseSunset, realTime),
    place: placeName,
    temp: unit_coversion(item["current"]["temperature_2m"], settings["Temperature"]).round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    dateString: getDateStringFromLocalTime(now),
  );
}

Future<LightWindData> omGetLightWindData(settings, lat, lon) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lon.toString(),
    "current": ["wind_speed_10m", "wind_direction_10m"],
  };

  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);
  final response = (await http.get(oMUrl)).body;

  final item = jsonDecode(response);

  return LightWindData(
      windDirAngle: item["current"]["wind_direction_10m"],
      windSpeed: unit_coversion(item["current"]["wind_speed_10m"], settings["Wind"]).round(),
      windUnit: settings["Wind"]
  );
}

Future<LightHourlyForecastData> omGetHourlyForecast(settings, placeName, lat, lon) async {
  final oMParams = {
    "latitude": lat.toString(),
    "longitude": lon.toString(),
    "current": ["temperature_2m", "weather_code"],
    "hourly" : ["temperature_2m", "weather_code"],
    "daily": ["sunrise", "sunset"],
    "forecast_days": "1",
    "timezone": "auto",
  };

  final oMUrl = Uri.https("api.open-meteo.com", 'v1/forecast', oMParams);
  final response = (await http.get(oMUrl)).body;

  final item = jsonDecode(response);

  DateTime localtime = OMGetLocalTime(item);
  String realTime = "jT${localtime.hour}:${localtime.minute}";
  DateTime now = DateTime.now();

  final absoluteSunriseSunset =  "${OMConvertTime(item["daily"]["sunrise"][0])}/"
      "${OMConvertTime(item["daily"]["sunset"][0])}";

  List<String> hourlyConditions = [];
  List<int> hourlyTemps = [];
  List<String> hourlyNames = [];

  for (int i = 0; i < item["hourly"]["temperature_2m"].length; i++) {
    DateTime d = DateTime.parse(item["hourly"]["time"][i]);
    if (d.hour % 6 == 0) {
      hourlyConditions.add(oMCurrentTextCorrection(
          item["hourly"]["weather_code"][i], absoluteSunriseSunset, item["hourly"]["time"][i]
      ));
      hourlyTemps.add(unit_coversion(item["hourly"]["temperature_2m"][i], settings["Temperature"]).round());
      hourlyNames.add("${d.hour}h");
    }
  }

  return LightHourlyForecastData(
      place: placeName,
      currentCondition: oMCurrentTextCorrection(item["current"]["weather_code"], absoluteSunriseSunset, realTime),
      currentTemp: unit_coversion(item["current"]["temperature_2m"], settings["Temperature"]).round(),
      updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
      //i can't sync lists to widgets so i need to encode and then decode them
      hourlyConditions: jsonEncode(hourlyConditions),
      hourlyNames: jsonEncode(hourlyNames),
      hourlyTemps: jsonEncode(hourlyTemps),
  );
}