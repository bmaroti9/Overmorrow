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

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:overmorrow/services/weather_service.dart';

import '../api_key.dart';
import '../caching.dart';

import '../weather_refact.dart' as weather_refactor;
import 'decode_RV.dart';
import 'weather_data.dart';


Future<List<dynamic>> WapiMakeRequest(String latlong, String real_loc) async {
  //gets the json response for weatherapi.com
  final params = {
    'key': wapi_Key,
    'q': latlong,
    'days': '3',
    'aqi': 'yes',
    'alerts': 'yes',
  };
  final url = Uri.https('api.weatherapi.com', 'v1/forecast.json', params);

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
  final params = {
    'key': timezonedbKey,
    'lat': lat.toString(),
    'lng': lng.toString(),
    'format': 'json',
    'by': 'position'
  };
  final url = Uri.https('api.timezonedb.com', 'v2.1/get-time-zone', params);
  var file = await XCustomCacheManager.fetchData(url.toString(), "$lat, $lng timezonedb.com");
  var response = await file[0].readAsString();
  var body = jsonDecode(response);
  
  return DateTime.parse(body["formatted"]);
}

String wapiTextCorrection(name, isday) {
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
  return x;
}


//---------------------------------Weather Classes--------------------------------

WeatherCurrent wapiWeatherCurrentFromJson(item, start) {
  return WeatherCurrent(
    condition: wapiTextCorrection(
      item["hour"][start]["condition"]["code"], item["hour"][start]["is_day"],
    ),
    tempC: item["hour"][start]["temp_c"],
    feelsLikeC: item["hour"][start]["feelslike_c"],

    uv: item["hour"][start]["uv"].round(),
    humidity: item["hour"][start]["humidity"],
    precipMm: item["day"]["totalprecip_mm"],
    windKph: item["hour"][start]["wind_kph"],
    windDirA: item["hour"][start]["wind_degree"],
  );
}

WeatherDay wapiWeatherDayFromJson(item, approximatelocal) {
  return WeatherDay(
    condition: wapiTextCorrection(item["day"]["condition"]["code"], 1),
    date: DateTime.parse(item["date"]),

    minTempC: item["day"]["mintemp_c"],
    maxTempC: item["day"]["maxtemp_c"],

    hourly: wapiBuildWeatherHourList(item["hour"], approximatelocal),

    totalPrecipMm: item["day"]["totalprecip_mm"] + item["day"]["totalsnow_cm"] / 10,
    precipProb: item["day"]["daily_chance_of_rain"],
    windKph: item["day"]["maxwind_kph"],
    uv: item["day"]["uv"].round(),
    windDirA: wapiGetWindDir(item["hour"]),
  );
}

List<WeatherHour> wapiBuildWeatherHourList(data, DateTime approximatelocal) {
  List<WeatherHour> hourly = [];

  for (var i = 0; i < 24; i++) {
    DateTime hour = DateTime.parse(data[i]["time"]);
    if (approximatelocal.difference(hour).inMinutes <= 0) {
      hourly.add(wapiWeatherHourFromJson(data[i], approximatelocal));
    }
  }
  return hourly;
}

WeatherHour wapiWeatherHourFromJson(item, approximatelocal) {
  return WeatherHour(
    condition: wapiTextCorrection(item["condition"]["code"], item["is_day"]),
    tempC: item["temp_c"],
    time: DateTime.parse(item["time"]),
    precipMm: item["precip_mm"] + (item["snow_cm"] / 10),

    windKph: item["wind_kph"],
    windGustKph: item["gust_kph"],

    precipProb: max(item["chance_of_rain"], item["chance_of_snow"]),
    uv: item["uv"].round(),
    windDirA: item["wind_degree"],
  );
}

WeatherSunStatus wapiWeatherSunStatusFromJson(item, localtime) {
  return WeatherSunStatus(
    sunrise: DateFormat('h:mm a').parse(item["forecast"]["forecastday"][0]["astro"]["sunrise"]),
    sunset: DateFormat('h:mm a').parse(item["forecast"]["forecastday"][0]["astro"]["sunset"]),
    sunstatus: getSunStatus(item["forecast"]["forecastday"][0]["astro"]["sunrise"],
        item["forecast"]["forecastday"][0]["astro"]["sunset"], localtime),
  );
}

WeatherAqi wapiWeatherAqiFromJson(item) {
  return WeatherAqi(
    aqiIndex: item["current"]["air_quality"]["us-epa-index"],
  );
}


List<WeatherAlert> wapiGetWeatherAlerts(item) {
  final List<WeatherAlert> alerts = [];
  final alertList = item["alerts"]["alert"];
  //for some reason weatherapi sometimes returns like 5 of the same alerts, so i have to manually remove duplicates
  List<String> seenDescs = [];
  for (int i = 0; i < alertList.length; i++) {
    String d = alertList[i]["desc"];
    if (!seenDescs.contains(d)) {
      alerts.add(wapiWeatherAlertFromJson(alertList[i]));
      seenDescs.add(d);
    }
  }
  return alerts;
}

WeatherAlert wapiWeatherAlertFromJson(item) {
  return WeatherAlert(
    headline: item["headline"].trim() ?? "No Headline",
    start: DateTime.parse(item["effective"]),
    end: DateTime.parse(item["expires"]),
    event: item["event"].trim() ?? "No Event",
    desc: item["desc"].trim() ?? "No Desc",
    urgency: item["urgency"] ?? "--",
    severity: item["severity"] ?? "--",
    certainty: item["certainty"] ?? "--",
    areas: item["areas"] ?? "--",
  );
}

WeatherRain15Minutes wapiWeatherRain15MinutesFromJson(item, day, hour) {

  //weatherapi doesn't actaully have 15 minute forecast(well it does but it's paid), but i figured i could just use the
  //hourly data and just use some smoothing between the hours to emulate the 15 minutes
  //still better than not having it

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

  int time = 0;
  String text = "";
  if (closest != 100) {
    if (closest <= 2) {
      if (end <= 1) {
        text = "rainInOneHour";
      }
      else {
        text = "rainInHours";
        time = end;
      }
    }
    else if (closest < 1) {
      text = "rainExpectedInOneHour";
    }
    else {
      text = "rainExpectedInHours";
      time = closest;
    }
  }

  sum = max(sum, 0.1); //if there is rain then it shouldn't write 0

  return WeatherRain15Minutes(
    text: text,
    timeTo: time,
    precipSumMm: sum,
    precipListMm: precips,
  );

}


Future<WeatherData> WapiGetWeatherData(lat, lng, placeName) async {

  var wapi = await WapiMakeRequest("$lat,$lng", placeName);

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

  List<WeatherDay> days = [];
  List<dynamic> hourly72 = [];

  for (int n = 0; n < wapi_body["forecast"]["forecastday"].length; n++) {
    WeatherDay day = wapiWeatherDayFromJson(
        wapi_body["forecast"]["forecastday"][n], approximateLocal);
    days.add(day);

    if (hourly72.length < 72) {
      if (n != 0) {
        hourly72.add(day.date);
      }
      for (int z = 0; z < day.hourly.length; z++) {
        if (hourly72.length < 72) {
          hourly72.add(day.hourly[z]);
        }
      }
    }
  }

  return WeatherData(
    provider: "weatherapi.com",

    place: placeName,
    lat: lat,
    lng: lng,

    hourly72: hourly72,

    current: wapiWeatherCurrentFromJson(wapi_body["forecast"]["forecastday"][0], start,),
    days: days,
    sunStatus: wapiWeatherSunStatusFromJson(wapi_body,
        DateTime(localtime.year, localtime.month, localtime.day, localtime.hour, localtime.minute)),
    aqi: wapiWeatherAqiFromJson(wapi_body),
    radar: await RainviewerRadar.getData(),

    dailyMinMaxTemp: weatherGetMaxMinTempForDaily(days),

    fetchDatetime: fetch_datetime,
    updatedTime: DateTime.now(),
    localTime: localtime,

    minutely15Precip: wapiWeatherRain15MinutesFromJson(wapi_body, 0, start),
    alerts: wapiGetWeatherAlerts(wapi_body),

    isOnline: isonline
  );
}

Future<dynamic> wapiGetCurrentResponse(settings, placeName, lat, lon) async {
  final params = {
    'key': wapi_Key,
    'q': "$lat, $lon",
    'aqi': 'no',
    'alerts': 'no',
  };
  final url = Uri.https('api.weatherapi.com', 'v1/current.json', params);

  final response = (await http.get(url)).body;

  return jsonDecode(response);
}

Future<LightCurrentWeatherData> wapiGetLightCurrentData(settings, placeName, lat, lon) async {
  final item = await wapiGetCurrentResponse(settings, placeName, lat, lon);

  DateTime now = DateTime.now();

  return LightCurrentWeatherData(
    condition: wapiTextCorrection(item["current"]["condition"]["code"], item["current"]["is_day"]),
    place: placeName,
    temp:  unitConversion(item["current"]["temp_c"], settings["Temperature"]).round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    dateString: getDateStringFromLocalTime(now),
  );
}

Future<LightWindData> wapiGetLightWindData(settings, placeName, lat, lon) async {
  final item = await wapiGetCurrentResponse(settings, placeName, lat, lon);

  return LightWindData(
      windDirAngle: item["current"]["wind_degree"],
      windSpeed:  unitConversion(item["current"]["wind_kph"], settings["Wind"]).round(),
      windUnit: settings["Wind"],
  );
}

Future<LightHourlyForecastData> wapiGetLightHourlyData(settings, placeName, lat, lon) async {
  final params = {
    'key': wapi_Key,
    'q': "$lat, $lon",
    'aqi': 'no',
    'days': '1',
    'alerts': 'no',
  };
  final url = Uri.https('api.weatherapi.com', 'v1/forecast.json', params);

  final response = (await http.get(url)).body;

  final item = jsonDecode(response);

  List<String> hourlyConditions = [];
  List<int> hourlyTemps = [];
  List<String> hourlyNames = [];

  DateTime now = DateTime.now();

  for (int i = 0; i < item["forecast"]["forecastday"][0]["hour"].length; i++) {
    final hour = item["forecast"]["forecastday"][0]["hour"][i];

    DateTime d = DateTime.parse(hour["time"]);

    if (d.hour % 6 == 0) {
      hourlyConditions.add(wapiTextCorrection(hour["condition"]["code"], hour["is_day"]));
      hourlyTemps.add(unitConversion(hour["temp_c"], settings["Temperature"]).round());
      hourlyNames.add("${d.hour}h");
    }
  }

  print(("wapi hourlytemp", hourlyTemps));

  return LightHourlyForecastData(
    place: placeName,
    currentCondition: wapiTextCorrection(item["current"]["condition"]["code"], item["current"]["is_day"]),
    currentTemp: unitConversion(item["current"]["temp_c"], settings["Temperature"]).round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    //i can't sync lists to widgets so i need to encode and then decode them
    hourlyConditions: jsonEncode(hourlyConditions),
    hourlyNames: jsonEncode(hourlyNames),
    hourlyTemps: jsonEncode(hourlyTemps),
  );
}
