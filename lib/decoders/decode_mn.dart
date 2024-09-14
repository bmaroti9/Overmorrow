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
import 'package:flutter/material.dart';
import 'package:overmorrow/Icons/overmorrow_weather_icons_icons.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:worldtime/worldtime.dart';

import '../caching.dart';
import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';
import 'decode_wapi.dart';
import 'extra_info.dart';

String metNTextCorrection(String text, {language = 'English'}) {
  String p = metNWeatherToText[text] ?? 'Clear Sky';
  String t = translation(p, language);
  return t;
}

int metNcalculateFeelsLike(double t, double r, double v) {
  //unfortunately met norway has no feels like temperatures, so i have to calculate it myself based on:
  //temperature, relative humidity, and wind speed
  // https://meteor.geol.iastate.edu/~ckarsten/bufkit/apparent_temperature.html

  if (t > 27) {
    t = (t * 1.8) + 32;

    double heat_index = -42.379 + (2.04901523 * t) + (10.14333127 * r)
        - (0.22475541 * t * r) - (0.00683783 * t * t)
        - (0.05481717 * r * r) + (0.00122874 * t * t * r)
        + (0.00085282 * t * r * r) - (0.00000199 * t * t * r * r);

    return ((heat_index - 32) / 1.8).round();
  }

  else if (t < 10) {
    t = (t * 1.8) + 32;

    double wind_chill = 35.74 + (0.6215 * t) - (35.75 * pow(v, 0.16)) + (0.4275 * t * pow(v, 0.16));

    return ((wind_chill - 32) / 1.8).round();
  }

  else {
    return t.round();
  }

}

String metNGetName(index, settings, item, start) {
  if (index < 3) {
    const names = ['Today', 'Tomorrow', 'Overmorrow'];
    return translation(names[index], settings["Language"]);
  }
  String x = item["properties"]["timeseries"][start]["time"].split("T")[0];
  List<String> z = x.split("-");
  DateTime time = DateTime(int.parse(z[0]), int.parse(z[1]), int.parse(z[2]));
  const weeks = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  String weekname = translation(weeks[time.weekday - 1], settings["Language"]);
  return "$weekname, ${time.month}/${time.day}";
}

String metNBackdropCorrection(String text) {
  return textBackground[text] ?? 'clear_sky3.jpg';
}

Color metNBackColorCorrection(String text) {
  return textBackColor[text] ?? BLACK;
}

Color metNAccentColorCorrection(String text) {
  return accentColors[text] ?? WHITE;
}

List<Color> metNContentColorCorrection(String text) {
  return textFontColor[text] ?? [WHITE, WHITE];
}

IconData metNIconCorrection(String text) {
  return textMaterialIcon[text] ?? OvermorrowWeatherIcons.sun2;
}

String metNTimeCorrect(String date) {
  final realtime = date.split('T')[1];
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
    return '${realhour}am';
  }
  else if (num == 12) {
    return '12pm';
  }
  return '${num - 12}pm';
}

Future<DateTime> MetNGetLocalTime(lat, lng) async {
  return await Worldtime().timeByLocation(
    latitude: lat,
    longitude: lng,
  );
}

Future<List<dynamic>> MetNMakeRequest(double lat, double lng, String real_loc) async {

  final MnParams = {
    "lat" : lat.toString(),
    "lon" : lng.toString(),
    "altitude" : "100",
  };
  final headers = {
    "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
  };
  final MnUrl = Uri.https("api.met.no", 'weatherapi/locationforecast/2.0/complete', MnParams);

  print(("real_loc", real_loc, MnUrl));

  var MnFile = await cacheManager2.getSingleFile(MnUrl.toString(), key: "$real_loc, met.no", headers: headers).timeout(const Duration(seconds: 6));
  var MnResponse = await MnFile.readAsString();
  final MnData = jsonDecode(MnResponse);

  DateTime fetch_datetime = await MnFile.lastModified();
  return [MnData, fetch_datetime];

}

class MetNCurrent {
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

  final String photographerName;
  final String photographerUrl;
  final String photoUrl;

  final List<Color> imageDebugColors;

  const MetNCurrent({
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
    required this.photographerName,
    required this.photographerUrl,
    required this.photoUrl,
    required this.imageDebugColors,
  });

  static Future<MetNCurrent> fromJson(item, settings, real_loc, lat, lng) async {

    Image Uimage;

    String photographerName = "";
    String photorgaperUrl = "";
    String photoLink = "";

    if (settings["Image source"] == "network") {
      final text = metNTextCorrection(
          item["properties"]["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"],
          language: "English");
      final ImageData = await getUnsplashImage(text, real_loc, lat, lng);
      Uimage = ImageData[0];
      photographerName = ImageData[1];
      photorgaperUrl = ImageData[2];
      photoLink = ImageData[3];
    }
    else {
      String imagePath = metNBackdropCorrection(
        metNTextCorrection(item["properties"]["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
      );
      Uimage = Image.asset("assets/backdrops/$imagePath", fit: BoxFit.cover, width: double.infinity, height: double.infinity,);
    }

    Color back = metNAccentColorCorrection(
      metNTextCorrection(item["properties"]["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    );

    Color primary = metNBackColorCorrection(
      metNTextCorrection(item["properties"]["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    );

    List<dynamic> x = await getMainColor(settings, primary, back, Uimage);
    List<Color> colors = x[0];
    List<Color> imageDebugColors = x[1];

    var it = item["properties"]["timeseries"][0]["data"];

    return MetNCurrent(
      image: Uimage,
      photographerName: photographerName,
      photographerUrl: photorgaperUrl,
      photoUrl: photoLink,

      text: metNTextCorrection(
          it["next_1_hours"]["summary"]["symbol_code"],
          language: settings["Language"]),

      precip: unit_coversion(
          it["next_1_hours"]["details"]["precipitation_amount"],
          settings["Precipitation"]),
      temp: unit_coversion(
          it["instant"]["details"]["air_temperature"],
          settings["Temperature"]).round(),
      humidity: it["instant"]["details"]["relative_humidity"].round(),
      wind: unit_coversion(
          it["instant"]["details"]["wind_speed"] * 3.6,
          settings["Wind"]).round(),
      uv: it["instant"]["details"]["ultraviolet_index_clear_sky"].round(),
      feels_like: metNcalculateFeelsLike(it["instant"]["details"]["air_temperature"],
        it["instant"]["details"]["relative_humidity"], it["instant"]["details"]["wind_speed"] * 3.6),
      imageDebugColors: imageDebugColors,
      wind_dir: it["instant"]["details"]["wind_from_direction"].round(),

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
    );
  }
}

class MetNDay {
  final String text;

  final IconData icon;
  final double iconSize;

  final String name;
  final String minmaxtemp;
  final List<MetNHour> hourly;
  final List<MetNHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;

  final int windspeed;
  final int wind_dir;

  final double mm_precip;
  final int uv;

  const MetNDay({
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

  static MetNDay fromJson(item, settings, start, end, index) {
    
    List<int> temperatures = [];
    List<double> windspeeds = [];
    List<int> winddirs = [];
    List<double> precip_mm = [];
    List<double> precip = [];
    List<int> uvs = [];

    int precipProb = -10;

    List<int> oneSummary = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    const weather_names = ['Clear Night', 'Partly Cloudy', 'Clear Sky', 'Overcast',
      'Haze', 'Rain', 'Sleet', 'Drizzle', 'Thunderstorm', 'Heavy Snow', 'Fog', 'Snow',
      'Heavy Rain', 'Cloudy Night'];
    
    List<MetNHour> hours = [];
    
    for (int n = start; n < end; n++) {
      MetNHour hour = MetNHour.fromJson(item["properties"]["timeseries"][n], settings);
      temperatures.add(hour.temp);
      windspeeds.add(hour.wind);
      winddirs.add(hour.wind_dir);
      uvs.add(hour.uv);

      precip_mm.add(hour.raw_precip);
      precip.add(hour.precip);

      int index = weather_names.indexOf(hour.rawText);
      int value = weatherConditionBiassTable[hour.rawText] ?? 0;
      oneSummary[index] += value;

      if (hour.precip_prob > precipProb) {
        precipProb = hour.precip_prob.toInt();
      }
      hours.add(hour);
    }

    int largest_value = oneSummary.reduce(max);
    int BIndex = oneSummary.indexOf(largest_value);

    return MetNDay(
      mm_precip: precip_mm.reduce((a, b) => a + b),
      precip_prob: precipProb,
      minmaxtemp: "${temperatures.reduce(min)}°/${temperatures.reduce(max)}°",
      hourly: hours,
      hourly_for_precip: hours,
      total_precip: double.parse(precip.reduce((a, b) => a + b).toStringAsFixed(1)),
      windspeed: (windspeeds.reduce((a, b) => a + b) / windspeeds.length).round(),
      name: metNGetName(index, settings, item, start),
      text: translation(weather_names[BIndex], settings["Language"]),
      icon: metNIconCorrection(weather_names[BIndex]),
      iconSize: oMIconSizeCorrection(weather_names[BIndex]),
      wind_dir: (windspeeds.reduce((a, b) => a + b) / windspeeds.length).round(),
      uv: uvs.reduce(max)
    );
  }
}

class MetNHour {
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

  final rawText;

  const MetNHour(
      {
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
        required this.rawText,
      });

  static MetNHour fromJson(item, settings) {
    var nextHours = item["data"]["next_1_hours"] ?? item["data"]["next_6_hours"];
    return MetNHour(
        rawText: metNTextCorrection(
            nextHours["summary"]["symbol_code"]),
        text: metNTextCorrection(
            nextHours["summary"]["symbol_code"],
            language: settings["Language"]),
        temp: unit_coversion(
            item["data"]["instant"]["details"]["air_temperature"],
            settings["Temperature"]).round(),
        precip: unit_coversion(
            nextHours["details"]["precipitation_amount"],
            settings["Precipitation"]),
        precip_prob: (nextHours["details"]["probability_of_precipitation"] ??
            0).round(),
        icon: metNIconCorrection(
          metNTextCorrection(
              nextHours["summary"]["symbol_code"]),
        ),
        time: metNTimeCorrect(item["time"]),
        wind: double.parse(unit_coversion(
            item["data"]["instant"]["details"]["wind_speed"] * 3.6,
            settings["Wind"]).toStringAsFixed(1)),
        wind_dir: item["data"]["instant"]["details"]["wind_from_direction"]
            .round(),
        uv: (item["data"]["instant"]["details"]["ultraviolet_index_clear_sky"] ?? 0)
            .round(),

        raw_wind: item["data"]["instant"]["details"]["wind_speed"] * 3.6,
        raw_precip: nextHours["details"]["precipitation_amount"],
        raw_temp: item["data"]["instant"]["details"]["air_temperature"],
        iconSize: oMIconSizeCorrection(metNTextCorrection(
            nextHours["summary"]["symbol_code"]),)
    );
  }
}


class MetNSunstatus {
  final String sunrise;
  final String sunset;
  final double sunstatus;
  final String absoluteSunriseSunset;

  const MetNSunstatus({
    required this.sunrise,
    required this.sunstatus,
    required this.sunset,
    required this.absoluteSunriseSunset,
  });

  static Future<MetNSunstatus> fromJson(item, settings, lat, lng, date, DateTime timeThere) async {
    final MnParams = {
      "lat" : lat.toString(),
      "lon" : lng.toString(),
      "date" : date.split("T")[0],
    };
    final headers = {
      "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
    };
    final MnUrl = Uri.https("api.met.no", 'weatherapi/sunrise/3.0/sun', MnParams);

    var MnFile = await cacheManager2.getSingleFile(MnUrl.toString(), key: "$lat, $lng, sunstatus met.no", headers: headers).timeout(const Duration(seconds: 6));
    var MnResponse = await MnFile.readAsString();
    final item = jsonDecode(MnResponse);

    DateTime now = DateTime.now().toUtc();

    int dif = now.hour - timeThere.hour;

    List<String> sunriseString = item["properties"]["sunrise"]["time"].split("T")[1].split("+")[0].split(":");
    DateTime sunrise = timeThere.copyWith(
      hour: (int.parse(sunriseString[0]) - dif) % 24,
      minute: int.parse(sunriseString[1]),
    );

    List<String> sunsetString = item["properties"]["sunset"]["time"].split("T")[1].split("+")[0].split(":");
    DateTime sunset = timeThere.copyWith(
      hour: (int.parse(sunsetString[0]) - dif) % 24,
      minute: int.parse(sunsetString[1]),
    );

    return MetNSunstatus(
      sunrise: settings["Time mode"] == "24 hour"
        ? "${sunrise.hour.toString().padLeft(2, "0")}:${sunrise.minute.toString().padLeft(2, "0")}"
        : OMamPmTime("T${sunrise.hour}:${sunrise.minute}"),
      sunset: settings["Time mode"] == "24 hour"
          ? "${sunset.hour.toString().padLeft(2, "0")}:${sunset.minute.toString().padLeft(2, "0")}"
          : OMamPmTime("T${sunset.hour}:${sunset.minute}"),
      absoluteSunriseSunset: "${sunrise.hour}:${sunrise.minute}/${sunset.hour}:${sunset.minute}",
      sunstatus: min(max(
          timeThere.difference(sunrise).inMinutes / sunset.difference(sunrise).inMinutes, 0), 1),
    );
  }
}

Future<WeatherData> MetNGetWeatherData(lat, lng, real_loc, settings, placeName) async {

  DateTime localTime = await MetNGetLocalTime(lat, lng);

  var Mn = await MetNMakeRequest(lat, lng, real_loc);
  var MnBody = Mn[0];

  DateTime fetch_datetime = Mn[1];

  MetNSunstatus sunstatus = await MetNSunstatus.fromJson(MnBody, settings, lat, lng, MnBody["properties"]
  ["timeseries"][0]["time"], localTime);

  List<MetNDay> days = [];

  int begin = 0;
  int index = 0;

  for (int n = 0; n < MnBody["properties"]["timeseries"].length; n++) {
    if (MnBody["properties"]["timeseries"][n]["time"].split("T")[1].split(":")[0] == "00") {
      MetNDay day = MetNDay.fromJson(MnBody, settings, begin, n, index);
      days.add(day);
      index += 1;
      begin = n;
    }
  }

  return WeatherData(
    radar: await RainviewerRadar.getData(),
    aqi: await OMAqi.fromJson(MnBody, lat, lng, settings),
    sunstatus: sunstatus,
    minutely_15_precip: const OM15MinutePrecip(t_minus: "", precip_sum: 0, precips: []), //because MetN has no 15 minute forecast

    current: await MetNCurrent.fromJson(MnBody, settings, real_loc, lat, lng),
    days: days,

    lat: lat,
    lng: lng,

    place: placeName,
    settings: settings,
    provider: "met norway",
    real_loc: real_loc,

    fetch_datetime: fetch_datetime,
    updatedTime: DateTime.now(),
    localtime: "${localTime.hour}:${localTime.minute}"
  );
}