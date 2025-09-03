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
import 'package:http/http.dart' as http;
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/services/weather_service.dart';

import '../api_key.dart';
import '../caching.dart';

import '../weather_refact.dart';
import 'decode_RV.dart';
import 'weather_data.dart';


String metNTextCorrection(String text) {
  String p = metNWeatherToText[text] ?? 'Clear Sky';
  return p;
}

int metNCalculateHourDif(DateTime timeThere) {
  DateTime now = DateTime.now().toUtc();

  return now.hour - timeThere.hour;
}

Duration metNCalculateTimeOffset(DateTime timeThere) {
  DateTime now = DateTime.now().toUtc();
  return now.difference(timeThere);
}

double metNcalculateFeelsLike(double t, double r, double v) {
  //unfortunately met norway has no feels like temperatures, so i have to calculate it myself based on:
  //temperature, relative humidity, and wind speed
  // https://meteor.geol.iastate.edu/~ckarsten/bufkit/apparent_temperature.html

  if (t >= 24) {
    t = (t * 1.8) + 32;

    double heat_index = -42.379 + (2.04901523 * t) + (10.14333127 * r)
        - (0.22475541 * t * r) - (0.00683783 * t * t)
        - (0.05481717 * r * r) + (0.00122874 * t * t * r)
        + (0.00085282 * t * r * r) - (0.00000199 * t * t * r * r);

    return ((heat_index - 32) / 1.8);
  }

  else if (t <= 13) {
    t = (t * 1.8) + 32;

    double wind_chill = 35.74 + (0.6215 * t) - (35.75 * pow(v, 0.16)) + (0.4275 * t * pow(v, 0.16));

    return ((wind_chill - 32) / 1.8);
  }

  else {
    return t;
  }

}

Future<DateTime> MetNGetLocalTime(lat, lng) async {
  /*
  return await XWorldTime.timeByLocation(
    latitude: lat,
    longitude: lng,
  );
   */
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

  var MnFile = await XCustomCacheManager.fetchData(MnUrl.toString(), "$real_loc, met.no", headers: headers);

  var MnResponse = await MnFile[0].readAsString();
  bool isonline = MnFile[1];

  final MnData = jsonDecode(MnResponse);

  DateTime fetch_datetime = await MnFile[0].lastModified();
  return [MnData, fetch_datetime, isonline];

}

WeatherCurrent metNWeatherCurrentFromJson(item, ) {
  var it = item["properties"]["timeseries"][0]["data"];

  return WeatherCurrent(
    condition: metNTextCorrection(it["next_1_hours"]["summary"]["symbol_code"],),
    precipMm: it["next_1_hours"]["details"]["precipitation_amount"],
    tempC: it["instant"]["details"]["air_temperature"],
    humidity: it["instant"]["details"]["relative_humidity"].round(),
    windKph: it["instant"]["details"]["wind_speed"] * 3.6,
    uv: it["instant"]["details"]["ultraviolet_index_clear_sky"].round(),
    feelsLikeC: metNcalculateFeelsLike(it["instant"]["details"]["air_temperature"],
        it["instant"]["details"]["relative_humidity"], it["instant"]["details"]["wind_speed"] * 3.6),
    windDirA: it["instant"]["details"]["wind_from_direction"].round(),

  );
}

WeatherDay metNWeatherDayFromJson(item, start, end, index, hourDif) {
  List<double> rawTemps = [];
  List<double> windspeeds = [];
  List<int> winddirs = [];
  List<double> precip = [];
  List<int> uvs = [];

  int precipProb = -10;

  List<int> oneSummary = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const weather_names = ['Clear Night', 'Partly Cloudy', 'Clear Sky', 'Overcast',
    'Haze', 'Rain', 'Sleet', 'Drizzle', 'Thunderstorm', 'Heavy Snow', 'Fog', 'Snow',
    'Heavy Rain', 'Cloudy Night'];

  List<WeatherHour> hours = [];

  for (int n = start; n < end; n++) {
    WeatherHour hour = metNWeatherHourFromJson(item["properties"]["timeseries"][n], hourDif);
    rawTemps.add(hour.tempC);
    windspeeds.add(hour.windKph);
    winddirs.add(hour.windDirA);
    uvs.add(hour.uv);

    precip.add(hour.precipMm);

    int index = weather_names.indexOf(hour.condition);
    int value = weatherConditionBiassTable[hour.condition] ?? 0;
    oneSummary[index] += value;

    if (hour.precipProb > precipProb) {
      precipProb = hour.precipProb.toInt();
    }
    hours.add(hour);
  }

  int largest_value = oneSummary.reduce(max);
  int BIndex = oneSummary.indexOf(largest_value);

  return WeatherDay(
      totalPrecipMm: precip.reduce((a, b) => a + b),
      precipProb: precipProb,
      minTempC: rawTemps.reduce(min),
      maxTempC:  rawTemps.reduce(max),
      hourly: hours,
      windKph: (windspeeds.reduce((a, b) => a + b) / windspeeds.length),
      date: DateTime.parse(item["properties"]["timeseries"][start]["time"]),
      condition: weather_names[BIndex],
      windDirA: (windspeeds.reduce((a, b) => a + b) / windspeeds.length).round(),
      uv: uvs.reduce(max)
  );
}

WeatherHour metNWeatherHourFromJson(item, hourDif) {
  var nextHours = item["data"]["next_1_hours"] ?? item["data"]["next_6_hours"];

  return WeatherHour(
    windGustKph: 0, //met norway sadly doesn't have any gust data
    condition: metNTextCorrection(nextHours["summary"]["symbol_code"]),
    tempC: item["data"]["instant"]["details"]["air_temperature"],
    precipMm: nextHours["details"]["precipitation_amount"],
    precipProb: nextHours["details"]["probability_of_precipitation"] ?? 0,
    time: DateTime.parse(item["time"]),
    windKph: item["data"]["instant"]["details"]["wind_speed"] * 3.6,
    windDirA: item["data"]["instant"]["details"]["wind_from_direction"].round(),
    uv: (item["data"]["instant"]["details"]["ultraviolet_index_clear_sky"] ?? 0)
        .round(),
  );
}

Future<WeatherSunStatus> metNGetWeatherSunStatus(item, lat, lng, int dif, DateTime timeThere, DateTime fetchDate) async {
  final MnParams = {
    "lat" : lat.toString(),
    "lon" : lng.toString(),
    "date" : "${fetchDate.year}-${fetchDate.month.toString().padLeft(2, "0")}-${fetchDate.day.toString().padLeft(2, "0")}",
  };
  final headers = {
    "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
  };
  final MnUrl = Uri.https("api.met.no", 'weatherapi/sunrise/3.0/sun', MnParams);

  var MnFile = await XCustomCacheManager.fetchData(MnUrl.toString(), "$lat, $lng met.no aqi", headers: headers);
  var MnResponse = await MnFile[0].readAsString();
  final item = jsonDecode(MnResponse);

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

  return WeatherSunStatus(
    sunrise: sunrise,
    sunset: sunset,
    sunstatus: min(max(timeThere.difference(sunrise).inMinutes / sunset.difference(sunrise).inMinutes, 0), 1),
  );
}

WeatherRain15Minutes metNWeatherRain15MinutesFromJson(item) {
  //met norway doesn't actaully have 15 minute forecast but i figured i could just use the
  //hourly data and just use some smoothing between the hours to emulate the 15 minutes
  //still better than not having it

  int closest = 100;
  int end = -1;
  double sum = 0;

  List<double> precips = [];
  List<double> hourly = [];

  for (int i = 0; i < 6; i++) {
    double x = double.parse(item["properties"]["timeseries"][i]["data"]["next_1_hours"]["details"]["precipitation_amount"].toStringAsFixed(1));

    if (x > 0.0) {
      if (closest == 100) {
        closest = i + 1;
      }
      if (i >= end) {
        end = i + 1;
      }
    }

    hourly.add(x);
  }

  //smooth the hours into 15 minute segments

  for (int i = 0; i < hourly.length - 1; i++) {
    double now = hourly[i];
    double next = hourly[i + 1];

    double dif = next - now;
    for (double x = 0; x <= 1; x += 0.25) {
      double g = (now + dif * x) / 4; //because we are dividing the sum of 1 hour into quarters
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

Future<WeatherData> MetNGetWeatherData(lat, lng, placeName) async {

  print("fetching with metN");

  var Mn = await MetNMakeRequest(lat, lng, placeName);
  var MnBody = Mn[0];

  DateTime lastKnowTime = await MetNGetLocalTime(lat, lng);
  DateTime fetch_datetime = Mn[1];

  //this gives us the time passed since last fetch, this is all basically for offline mode
  Duration realTimeOffset = DateTime.now().difference(fetch_datetime);

  //now we just need to apply this time offset to get the real current time
  DateTime localTime = lastKnowTime.add(realTimeOffset);

  int hourDif = metNCalculateHourDif(localTime);

  bool isonline = Mn[2];

  //removes the outdated hours
  int start = localTime.difference(DateTime(lastKnowTime.year, lastKnowTime.month,
      lastKnowTime.day, lastKnowTime.hour)).inHours;

  //make sure that there is data left
  if (start >= MnBody["properties"]["timeseries"].length) {
    throw const SocketException("Cached data expired");
  }

  //remove outdated hours
  MnBody["properties"]["timeseries"] = MnBody["properties"]["timeseries"].sublist(start);

  List<WeatherDay> days = [];
  List<dynamic> hourly72 = [];

  int begin = 0;
  int index = 0;

  int previous_hour = 0;
  for (int n = 0; n < MnBody["properties"]["timeseries"].length; n++) {
    int hour = (int.parse(MnBody["properties"]["timeseries"][n]["time"].split("T")[1].split(":")[0]) - hourDif) % 24;
    if (n > 0 && hour - previous_hour < 1) {
      WeatherDay day = metNWeatherDayFromJson(MnBody, begin, n, index, hourDif);
      days.add(day);

      if (hourly72.length < 72) {
        if (begin != 0) {
          hourly72.add(day.date);
        }
        for (int z = 0; z < day.hourly.length; z++) {
          if (hourly72.length < 72) {
            hourly72.add(day.hourly[z]);
          }
        }
      }

      index += 1;
      begin = n;
    }
    previous_hour = hour;
  }

  return WeatherData(
    provider: "met norway",

    lat: lat,
    lng: lng,

    place: placeName,

    radar: await RainviewerRadar.getData(),
    aqi: await oMGetWeatherAqi(lat, lng),
    sunStatus: await metNGetWeatherSunStatus(MnBody, lat, lng, hourDif, localTime, fetch_datetime),
    alerts: [],
    minutely15Precip: metNWeatherRain15MinutesFromJson(MnBody),

    current: metNWeatherCurrentFromJson(MnBody),
    days: days,

    dailyMinMaxTemp: weatherGetMaxMinTempForDaily(days),

    hourly72: hourly72,

    fetchDatetime: fetch_datetime,
    updatedTime: DateTime.now(),
    localTime: localTime,
    isOnline: isonline,
  );
}


Future<dynamic> metNGetLightResponse(settings, placeName, lat, lon) async {
  final params = {
    "lat" : lat.toString(),
    "lon" : lon.toString(),
    "altitude" : "100",
  };

  final headers = {
    "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
  };
  final url = Uri.https("api.met.no", 'weatherapi/locationforecast/2.0/compact', params);

  final response = (await http.get(url, headers: headers)).body;

  return jsonDecode(response);
}

Future<LightCurrentWeatherData> metNGetLightCurrentData(settings, placeName, lat, lon) async {
  final item = await metNGetLightResponse(settings, placeName, lat, lon);

  DateTime now = DateTime.now();

  return LightCurrentWeatherData(
    condition: metNTextCorrection(item["properties"]["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    place: placeName,
    temp: unitConversion(
        item["properties"]["timeseries"][0]["data"]["instant"]["details"]["air_temperature"],
        settings["Temperature"]).round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    dateString: getDateStringFromLocalTime(now),
  );
}

Future<LightWindData> metNGetLightWindData(settings, placeName, lat, lon) async {
  final item = await metNGetLightResponse(settings, placeName, lat, lon);

  return LightWindData(
    windDirAngle: item["properties"]["timeseries"][0]["data"]["instant"]["details"]["wind_from_direction"].round(),
    windSpeed: unitConversion(item["properties"]["timeseries"][0]["data"]["instant"]["details"]["wind_speed"] * 3.6,settings["Wind"]).round(),
    windUnit: settings["Wind"],
  );
}


Future<LightHourlyForecastData> metNGetLightHourlyData(settings, placeName, lat, lon) async {
  final item = await metNGetLightResponse(settings, placeName, lat, lon);

  List<String> hourlyConditions = [];
  List<int> hourlyTemps = [];
  List<String> hourlyNames = [];

  DateTime now = DateTime.now();

  for (int i = 0; i < min(item["properties"]["timeseries"].length, 23); i++) {
    final hour = item["properties"]["timeseries"][i];

    DateTime d = DateTime.parse(hour["time"]);

    if (d.hour % 6 == 0) {
      hourlyConditions.add(metNTextCorrection(
          hour["data"]["next_1_hours"]["summary"]["symbol_code"]));
      hourlyTemps.add(unitConversion(
          hour["data"]["instant"]["details"]["air_temperature"], settings["Temperature"]).round(),);
      hourlyNames.add("${d.hour}h");
    }
  }

  return LightHourlyForecastData(
    place: placeName,
    currentCondition: metNTextCorrection(item["properties"]["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    currentTemp: unitConversion(
        item["properties"]["timeseries"][0]["data"]["instant"]["details"]["air_temperature"],
        settings["Temperature"]).round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    //i can't sync lists to widgets so i need to encode and then decode them
    hourlyConditions: jsonEncode(hourlyConditions),
    hourlyNames: jsonEncode(hourlyNames),
    hourlyTemps: jsonEncode(hourlyTemps),
  );
}