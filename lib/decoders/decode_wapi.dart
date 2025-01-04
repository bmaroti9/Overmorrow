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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import '../Icons/overmorrow_weather_icons_icons.dart';
import '../api_key.dart';
import '../caching.dart';
import '../settings_page.dart';

import '../weather_refact.dart' as weather_refactor;
import '../weather_refact.dart';
import 'decode_OM.dart';
import 'extra_info.dart';

import 'package:flutter/material.dart';

//decodes the whole response from the weatherapi.com api_call

Future<List<dynamic>> WapiMakeRequest(String latlong, String real_loc) async {
  //gets the json response for weatherapi.com
  final params = {
    'key': wapi_Key,
    'q': latlong,
    'days': '3',
    'aqi': 'yes',
    'alerts': 'no',
  };
  final url = Uri.http('api.weatherapi.com', 'v1/forecast.json', params);

  //var file = await cacheManager2.getSingleFile(url.toString(), key: "$real_loc, weatherapi.com ")
  //    .timeout(const Duration(seconds: 3));

  var file = await XCustomCacheManager.fetchData(url.toString(), "$real_loc, weatherapi.com");

  DateTime fetch_datetime = await file[0].lastModified();
  bool isonline = file[1];

  var response = await file[0].readAsString();

  var wapi_body = jsonDecode(response);

  return [wapi_body, fetch_datetime, isonline];
}

int wapiGetWindDir(var data) {
  int total = 0;
  for (var i = 0; i < data.length; i++) {
    int x = data[i]["wind_degree"];
    total += x;
  }
  return (total / data.length).round();
}

String amPmTime(String time) {
  List<String> splited = time.split(" ");
  List<String> num = splited[0].split(":");
  int hour = int.parse(num[0]);
  int minute = int.parse(num[1]);
  String atEnd = 'am';
  if (splited[1] == 'PM') {
    atEnd = 'pm';
  }
  if (minute < 10) {
    return "$hour:0$minute$atEnd";
  }

  return "$hour:$minute$atEnd";
}

String convertTime(String input, {by = " "}) {
  List<String> splited = input.split(by);
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

double getSunStatus(String sunrise, String sunset, DateTime localtime, {by = " "}) {
  List<String> splited1 = sunrise.split(by);
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

  int hour3 = localtime.hour;
  int minute3 = localtime.minute;
  int all3 = (hour3 * 60 + minute3) - all1;

  return min(1, max(all3 / all2, 0));

}


Future<DateTime> WapiGetLocalTime(lat, lng) async {
  return await XWorldTime.timeByLocation(
    latitude: lat,
    longitude: lng,
  );
}

double unit_coversion(double value, String unit) {
  List<double> p = weather_refactor.conversionTable[unit] ?? [0, 0];
  double a = p[0] + value * p[1];
  return a;
}

double temp_multiply_for_scale(int temp, String unit) {
  if (unit == '˚C') {
    return max(0, min(105, 17 + temp * 2.4));
  }
  else{
    return max(0, min(105, (0 + temp).toDouble()));
  }
}

IconData iconCorrection(name, isday, localizations) {
  String text = textCorrection(name, isday, false, localizations);
  //String p = weather_refactor.textIconMap[text] ?? 'clear_night.png';
  return textMaterialIcon[text] ?? OvermorrowWeatherIcons.sun2;
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

String getName(index, settings, localizations) {
  List<String> names = [
    localizations.today,
    localizations.tomorrow,
    localizations.overmorrow,
  ];
  return names[index];
}

String backdropCorrection(name, isday, localizations) {
  String text = textCorrection(name, isday, false, localizations);
  String backdrop = weather_refactor.textBackground[text] ?? "haze.jpg";

  return backdrop;
}

String textCorrection(name, isday, bool ShouldTranslate, localizations) {
  String x = weather_refactor.weatherTextMap[name] ?? 'Clear Sky';
  if (x == 'Clear Sky'){
    if (isday == 1) {
      x =  'Clear Sky';
    }
    else{
      x =  'Clear Night';
    }
  }
  else if (x == 'Partly Cloudy'){
    if (isday == 1) {
      x =  'Partly Cloudy';
    }
    else{
      x =  'Cloudy Night';
    }
  }

  if (ShouldTranslate) {
    x = conditionTranslation(x, localizations) ?? "TranslationErr";
  }
  return x;
}

class WapiCurrent {
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

  const WapiCurrent({
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

  static Future<WapiCurrent> fromJson(item, settings, real_loc, lat, lng, start, localizations) async {

    Image Uimage;

    String photographerName = "";
    String photographerUrl = "";
    String photoLink = "";

    if (settings["Image source"] == "network") {
      try {
        final text = textCorrection(
            item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"],
            false, localizations
        );
        final ImageData = await getUnsplashImage(text, real_loc, lat, lng);
        Uimage = ImageData[0];
        photographerName = ImageData[1];
        photographerUrl = ImageData[2];
        photoLink = ImageData[3];
      }
      //fallback to asset image when condition changed and there is no image for the new one
      catch(e) {
        String imagePath = backdropCorrection(
            item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"], localizations
        );
        Uimage = Image.asset("assets/backdrops/$imagePath", fit: BoxFit.cover,
          width: double.infinity, height: double.infinity,);

        List<String> credits = assetImageCredit(textCorrection(
            item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"],
            false, localizations));
        photoLink = credits[0]; photographerName = credits[1]; photographerUrl = credits[2];
      }
    }
    else {
      String imagePath = backdropCorrection(
          item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"], localizations
      );
      Uimage = Image.asset("assets/backdrops/$imagePath", fit: BoxFit.cover,
        width: double.infinity, height: double.infinity,);

      List<String> credits = assetImageCredit(textCorrection(
          item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"], false, localizations));
      photoLink = credits[0]; photographerName = credits[1]; photographerUrl = credits[2];
    }

    Color back = BackColorCorrection(
      textCorrection(
        item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"], false, localizations
      ),
    );

    Color primary = PrimaryColorCorrection(
        textCorrection(
          item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"], false, localizations
        )
    );

    List<dynamic> x = await getMainColor(settings, primary, back, Uimage);
    List<Color> colors = x[0];
    List<Color> imageDebugColors = x[1];

    return WapiCurrent(

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

      text: textCorrection(
          item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"],
          true, localizations,
      ),
      image: Uimage,
      temp: unit_coversion(item["hour"][start]["temp_c"], settings["Temperature"])
          .round(),
      feels_like: unit_coversion(
          item["hour"][start]["feelslike_c"], settings["Temperature"]).round(),

      uv: item["hour"][start]["uv"].round(),
      humidity: item["hour"][start]["humidity"],
      precip: double.parse(unit_coversion(
          item["day"]["totalprecip_mm"],
          settings["Precipitation"]).toStringAsFixed(1)),
      wind: unit_coversion(item["hour"][start]["wind_kph"], settings["Wind"])
          .round(),
      wind_dir: item["hour"][start]["wind_degree"],

      photographerName: photographerName,
      photographerUrl: photographerUrl,
      photoUrl: photoLink,
      imageDebugColors: imageDebugColors,
    );
  }
}

class WapiDay {
  final String text;
  final IconData icon;
  final double iconSize;
  final String name;
  final String minmaxtemp;
  final List<WapiHour> hourly;
  final List<WapiHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;
  final int windspeed;
  final int uv;
  final double mm_precip;

  final int wind_dir;

  const WapiDay({
    required this.text,
    required this.icon,
    required this.iconSize,
    required this.name,
    required this.minmaxtemp,
    required this.hourly,
    required this.uv,

    required this.precip_prob,
    required this.total_precip,
    required this.windspeed,
    required this.hourly_for_precip,
    required this.mm_precip,
    required this.wind_dir,
  });

  static WapiDay fromJson(item, index, settings, approximatelocal, localizations) => WapiDay(
    text: textCorrection(
        item["day"]["condition"]["code"], 1, true, localizations
    ),
    icon: iconCorrection(
        item["day"]["condition"]["code"], 1, localizations,
    ),
    iconSize: oMIconSizeCorrection(textCorrection(
        item["day"]["condition"]["code"], 1, false, localizations,
    ),),
    name: getName(index, settings, localizations),
    minmaxtemp: '${unit_coversion(item["day"]["maxtemp_c"], settings["Temperature"]).round()}°'
        '/${unit_coversion(item["day"]["mintemp_c"], settings["Temperature"]).round()}°',

    hourly: buildWapiHour(item["hour"], settings, index, approximatelocal, true, localizations),
    hourly_for_precip: buildWapiHour(item["hour"], settings, index, approximatelocal, false, localizations),

    mm_precip: item["day"]["totalprecip_mm"] + item["day"]["totalsnow_cm"] / 10,
    total_precip: double.parse(unit_coversion(item["day"]["totalprecip_mm"], settings["Precipitation"]).toStringAsFixed(1)),
    precip_prob: item["day"]["daily_chance_of_rain"],
    windspeed: unit_coversion(item["day"]["maxwind_kph"], settings["Wind"]).round(),
    uv: item["day"]["uv"].round(),
    wind_dir: wapiGetWindDir(item["hour"])
  );

  static List<WapiHour> buildWapiHour(data, settings, int index, DateTime approximatelocal, bool get_rid_first, localizations) {
    List<WapiHour> hourly = [];

    for (var i = 0; i < 24; i++) {
      DateTime hour = DateTime.parse(data[i]["time"]);
      if (approximatelocal.difference(hour).inMinutes <= 0 || !get_rid_first) {
        hourly.add(WapiHour.fromJson(data[i], settings, localizations));
      }
    }
    return hourly;
  }
}

class WapiHour {
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

  const WapiHour(
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
      });

  static WapiHour fromJson(item, settings, localizations) => WapiHour(
    text: textCorrection(
        item["condition"]["code"], item["is_day"], true, localizations
    ),
    icon: iconCorrection(
        item["condition"]["code"], item["is_day"], localizations
    ),
    iconSize: oMIconSizeCorrection(textCorrection(
        item["condition"]["code"], item["is_day"], false, localizations,
    ),),
    temp: unit_coversion(item["temp_c"], settings["Temperature"]).round(),
    time: getTime(item["time"], settings["Time mode"] == '12 hour'),
    precip: double.parse(
        unit_coversion(item["precip_mm"] + (item["snow_cm"] / 10), settings["Precipitation"]).toStringAsFixed(1)
    ),

    raw_temp: item["temp_c"],
    raw_precip: item["precip_mm"] + (item["snow_cm"] / 10),
    raw_wind: item["wind_kph"],

    wind: double.parse(unit_coversion(item["wind_kph"], settings["Wind"]).toStringAsFixed(1)),

    precip_prob: max(item["chance_of_rain"], item["chance_of_snow"]),
    uv: item["uv"].round(),
    wind_dir: item["wind_degree"],

  );
}

class WapiSunstatus {
  final String sunrise;
  final String sunset;
  final double sunstatus;
  final String absoluteSunriseSunset;

  const WapiSunstatus({
    required this.sunrise,
    required this.sunstatus,
    required this.sunset,
    required this.absoluteSunriseSunset,
  });

  static WapiSunstatus fromJson(item, settings, localtime) => WapiSunstatus(
    sunrise: settings["Time mode"] == "24 hour"
        ? convertTime(item["forecast"]["forecastday"][0]["astro"]["sunrise"])
        : amPmTime(item["forecast"]["forecastday"][0]["astro"]["sunrise"]),
    sunset: settings["Time mode"] == "24 hour"
        ? convertTime(item["forecast"]["forecastday"][0]["astro"]["sunset"])
        : amPmTime(item["forecast"]["forecastday"][0]["astro"]["sunset"]),
    absoluteSunriseSunset: "${convertTime(item["forecast"]["forecastday"][0]["astro"]["sunrise"])}/"
        "${convertTime(item["forecast"]["forecastday"][0]["astro"]["sunset"])}",
    sunstatus: getSunStatus(item["forecast"]["forecastday"][0]["astro"]["sunrise"],
        item["forecast"]["forecastday"][0]["astro"]["sunset"], localtime),
  );
}

class WapiAqi {
  final int aqi_index;
  final double pm2_5;
  final double pm10;
  final double o3;
  final double no2;
  final String aqi_title;
  final String aqi_desc;

  const WapiAqi({
    required this.no2,
    required this.o3,
    required this.pm2_5,
    required this.pm10,
    required this.aqi_index,
    required this.aqi_desc,
    required this.aqi_title,
  });

  static WapiAqi fromJson(item) => WapiAqi(
    aqi_index: item["current"]["air_quality"]["us-epa-index"],
    pm10: double.parse(item["current"]["air_quality"]["pm10"].toStringAsFixed(1)),
    pm2_5: double.parse(item["current"]["air_quality"]["pm2_5"].toStringAsFixed(1)),
    o3: double.parse(item["current"]["air_quality"]["o3"].toStringAsFixed(1)),
    no2: double.parse(item["current"]["air_quality"]["no2"].toStringAsFixed(1)),

    aqi_title: ['good', 'fair', 'moderate', 'poor', 'very poor', 'unhealthy']
    [item["current"]["air_quality"]["us-epa-index"] - 1],

    aqi_desc: ['Air quality is excellent; no health risk.',
      'Acceptable air quality; minor risk for sensitive people.',
      'Sensitive individuals may experience mild effects.',
      'Health effects possible for everyone, serious for sensitive groups.',
      'Serious health effects for everyone.',
      'Emergency conditions; severe health effects for all.']
    [item["current"]["air_quality"]["us-epa-index"] - 1],

  );
}


class Wapi15MinutePrecip { //weatherapi doesn't actaully have 15 minute forecast, but i figured i could just use the
                          //hourly data and just use some smoothing between the hours to emulate the 15 minutes
                          //still better than not having it
  final String t_minus;
  final double precip_sum;
  final List<double> precips;

  const Wapi15MinutePrecip({
    required this.t_minus,
    required this.precip_sum,
    required this.precips,
  });

  static Wapi15MinutePrecip fromJson(item, settings, day, hour) {
    int closest = 100;
    int end = -1;
    double sum = 0;

    List<double> precips = [];
    List<double> hourly = [];

    //int day = 0;
    //int hour = 0;

    int i = 0;

    while (i < 6) {
      if (item["forecast"]["forecastday"].length <= day) {
        break;
      }
      if (item["forecast"]["forecastday"][day]["hour"].length > hour) {
        double x;
        if (hour == 0 && day == 0) {
          x = double.parse(item["current"]["precip_mm"].toStringAsFixed(1));
        }
        else {
          x = double.parse(item["forecast"]["forecastday"][day]["hour"][hour]["precip_mm"].toStringAsFixed(1));
        }

        if (x > 0.0) {
          if (closest == 100) {
            closest = i + 1;
          }
          if (i >= end) {
            end = i + 1;
          }
        }

        hourly.add(x);

        i += 1;
        hour += 1;
      }
      else {
        day += 1;
      }
    }

    //smooth the hours into 15 minute segments

    for (int i = 0; i < hourly.length - 1; i++) {
      double now = hourly[i];
      double next = hourly[i + 1];

      double dif = next - now;
      for (double x = 0; x <= 1; x += 0.25) {
        double g = (now + (dif * x)) / 4; //because we are dividing the sum of 1 hour into quarters
        sum += g;
        precips.add(g);
      }
    }

    String t_minus = "";
    if (closest != 100) {
      if (closest <= 2) {
        if (end <= 1) {
          t_minus = "rain expected in the next 1 hour";
        }
        else {
          String x = " $end ";
          t_minus = "rain expected in the next x hours";
          t_minus = t_minus.replaceAll(" x ", x);
        }
      }
      else if (closest < 1) {
        t_minus = "rain expected in 1 hour";
      }
      else {
        String x = " $closest ";
        t_minus = "rain expected in x hours";
        t_minus = t_minus.replaceAll(" x ", x);
      }
    }

    sum = max(sum, 0.1); //if there is rain then it shouldn't write 0

    return Wapi15MinutePrecip(
      t_minus: t_minus,
      precip_sum: unit_coversion(sum, settings["Precipitation"]),
      precips: precips,
    );

  }

}

Future<WeatherData> WapiGetWeatherData(lat, lng, real_loc, settings, placeName, localizations) async {

  var wapi = await WapiMakeRequest("$lat,$lng", real_loc);

  var wapi_body = wapi[0];
  DateTime fetch_datetime = wapi[1];
  bool isonline = wapi[2];

  //DateTime lastKnowTime = DateTime.parse(wapi_body["location"]["localtime"]);
  DateTime lastKnowTime = await WapiGetLocalTime(lat, lng);

  //this gives us the time passed since last fetch, this is all basically for offline mode
  Duration realTimeOffset = DateTime.now().difference(fetch_datetime);

  //now we just need to apply this time offset to get the real current time
  DateTime localtime = lastKnowTime.add(realTimeOffset);

  //get hour diff
  DateTime approximateLocal = DateTime(localtime.year, localtime.month, localtime.day, localtime.hour);
  int start = approximateLocal.difference(DateTime(lastKnowTime.year,
      lastKnowTime.month, lastKnowTime.day)).inHours % 24;

  //get day diff
  int dayDif = DateTime(localtime.year, localtime.month, localtime.day).difference(
      DateTime(lastKnowTime.year, lastKnowTime.month, lastKnowTime.day)).inDays;

  //make sure that there is data left
  if (dayDif >= wapi_body["forecast"]["forecastday"].length) {
    throw const SocketException("Cached data expired");
  }

  //remove outdated days
  wapi_body["forecast"]["forecastday"] = wapi_body["forecast"]["forecastday"].sublist(dayDif);

  //int epoch = wapi_body["location"]["localtime_epoch"];
  WapiSunstatus sunstatus = WapiSunstatus.fromJson(wapi_body, settings,
      DateTime(localtime.year, localtime.month, localtime.day, localtime.hour, localtime.minute));

  List<WapiDay> days = [];

  for (int n = 0; n < wapi_body["forecast"]["forecastday"].length; n++) {
    days.add(WapiDay.fromJson(
        wapi_body["forecast"]["forecastday"][n], n, settings, approximateLocal, localizations));
  }

  return WeatherData(
    place: placeName,
    settings: settings,
    provider: "weatherapi.com",
    real_loc: real_loc,

    lat: lat,
    lng: lng,

    current: await WapiCurrent.fromJson(wapi_body["forecast"]["forecastday"][0], settings,
        real_loc, lat, lng, start, localizations),
    days: days,
    sunstatus: sunstatus,
    aqi: WapiAqi.fromJson(wapi_body),
    radar: await RainviewerRadar.getData(),

    fetch_datetime: fetch_datetime,
    updatedTime: DateTime.now(),
    localtime: "${localtime.hour}:${localtime.minute}",

    minutely_15_precip: Wapi15MinutePrecip.fromJson(wapi_body, settings, 0, start),

    isonline: isonline
  );
}
