/*
Copyright (C) <2026>  <Balint Maroti>

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
import 'package:shared_preferences/shared_preferences.dart';

import '../services/caching_service.dart';
import '../services/timezone_service.dart';

import '../weather_refact.dart';
import 'decode_RV.dart';
import 'weather_data.dart';

String metNTextCorrection(String text) {
  String p = metNWeatherToText[text] ?? 'Clear Sky';
  return p;
}

double metNcalculateFeelsLike(double t, double r, double v) {
  //unfortunately met norway has no feels like temperatures, so i have to calculate it myself based on:
  //temperature, relative humidity, and wind speed
  // https://meteor.geol.iastate.edu/~ckarsten/bufkit/apparent_temperature.html

  if (t >= 24) {
    t = (t * 1.8) + 32;

    double heat_index = -42.379 +
        (2.04901523 * t) +
        (10.14333127 * r) -
        (0.22475541 * t * r) -
        (0.00683783 * t * t) -
        (0.05481717 * r * r) +
        (0.00122874 * t * t * r) +
        (0.00085282 * t * r * r) -
        (0.00000199 * t * t * r * r);

    return ((heat_index - 32) / 1.8);
  } else if (t <= 13) {
    t = (t * 1.8) + 32;

    double wind_chill = 35.74 +
        (0.6215 * t) -
        (35.75 * pow(v, 0.16)) +
        (0.4275 * t * pow(v, 0.16));

    return ((wind_chill - 32) / 1.8);
  } else {
    return t;
  }
}

DateTime metNLocalTimeFromJson(item, double lat, double lng) {
  return TimezoneService.localDateTimeFromUtc(
      lat, lng, DateTime.parse(item["time"]));
}

bool metNIsSameLocalDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

dynamic metNNextForecastBlock(item) {
  final data = item["data"];
  if (data == null) {
    return null;
  }

  for (final key in ["next_1_hours", "next_6_hours", "next_12_hours"]) {
    final block = data[key];
    if (block != null && block["summary"] != null && block["details"] != null) {
      return block;
    }
  }

  return null;
}

String metNConditionFromJson(item) {
  final summary = metNNextForecastBlock(item)?["summary"];
  final symbolCode = summary == null ? null : summary["symbol_code"];

  if (symbolCode == null) {
    return 'Clear Sky';
  }
  return metNTextCorrection(symbolCode);
}

double metNPrecipAmountFromJson(item) {
  final details = metNNextForecastBlock(item)?["details"];
  final precip = details == null ? null : details["precipitation_amount"];

  if (precip is num) {
    return precip.toDouble();
  }
  return 0.0;
}

int? metNPrecipProbabilityFromJson(item) {
  final details = metNNextForecastBlock(item)?["details"];
  final probability =
      details == null ? null : details["probability_of_precipitation"];

  if (probability is num) {
    return probability.round();
  }
  return null;
}

Future<List<dynamic>> MetNMakeRequest(
    double lat, double lng, String real_loc) async {
  final MnParams = {
    "lat": lat.toString(),
    "lon": lng.toString(),
    "altitude": "100",
  };

  final headers = {
    "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
  };
  final MnUrl = Uri.https(
      "api.met.no", 'weatherapi/locationforecast/2.0/complete', MnParams);

  var MnFile = await XCustomCacheManager.fetchData(
      MnUrl.toString(), "$real_loc, met.no",
      headers: headers);

  var MnResponse = await MnFile[0].readAsString();
  bool isonline = MnFile[1];

  final MnData = jsonDecode(MnResponse);

  DateTime fetch_datetime = await MnFile[0].lastModified();
  return [MnData, fetch_datetime, isonline];
}

WeatherCurrent metNWeatherCurrentFromJson(
  item,
) {
  final firstTimeseries = item["properties"]["timeseries"][0];
  var it = firstTimeseries["data"];

  return WeatherCurrent(
    condition: metNConditionFromJson(firstTimeseries),
    precipMm: metNPrecipAmountFromJson(firstTimeseries),
    tempC: it["instant"]["details"]["air_temperature"],
    humidity: it["instant"]["details"]["relative_humidity"].round(),
    windKmh: it["instant"]["details"]["wind_speed"] * 3.6,
    uv: it["instant"]["details"]["ultraviolet_index_clear_sky"].round(),
    feelsLikeC: metNcalculateFeelsLike(
        it["instant"]["details"]["air_temperature"],
        it["instant"]["details"]["relative_humidity"],
        it["instant"]["details"]["wind_speed"] * 3.6),
    windDirA: it["instant"]["details"]["wind_from_direction"].round(),
  );
}

WeatherDay metNWeatherDayFromJson(
    item, start, end, index, double lat, double lng) {
  List<double> rawTemps = [];
  List<double> windspeeds = [];
  List<int?> winddirs = [];
  List<double> precip = [];

  int? uv;
  int? precipProb;

  List<int> oneSummary = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const weather_names = [
    'Clear Night',
    'Partly Cloudy',
    'Clear Sky',
    'Overcast',
    'Haze',
    'Rain',
    'Sleet',
    'Drizzle',
    'Thunderstorm',
    'Heavy Snow',
    'Fog',
    'Snow',
    'Heavy Rain',
    'Cloudy Night'
  ];

  List<WeatherHour> hours = [];

  for (int n = start; n < end; n++) {
    WeatherHour hour =
        metNWeatherHourFromJson(item["properties"]["timeseries"][n], lat, lng);
    rawTemps.add(hour.tempC);
    windspeeds.add(hour.windKmh);
    winddirs.add(hour.windDirA);

    precip.add(hour.precipMm);

    int index = weather_names.indexOf(hour.condition);
    int value = weatherConditionBiassTable[hour.condition] ?? 0;
    oneSummary[index] += value;

    if ((hour.precipProb ?? 0) > (precipProb ?? 0)) {
      precipProb = hour.precipProb?.toInt();
    }
    if ((hour.uv ?? 0) > (uv ?? 0)) {
      uv = hour.uv?.toInt();
    }

    hours.add(hour);
  }

  int largest_value = oneSummary.reduce(max);
  int BIndex = oneSummary.indexOf(largest_value);

  return WeatherDay(
    totalPrecipMm: precip.reduce((a, b) => a + b),
    precipProb: precipProb,
    minTempC: rawTemps.reduce(min),
    maxTempC: rawTemps.reduce(max),
    hourly: hours,
    windKmh: (windspeeds.reduce((a, b) => a + b) / windspeeds.length),
    date: metNLocalTimeFromJson(
        item["properties"]["timeseries"][start], lat, lng),
    condition: weather_names[BIndex],
    windDirA: (winddirs.whereType<int>().reduce((a, b) => a + b) /
            winddirs.whereType<int>().length)
        .round(),
    uv: uv,
  );
}

WeatherHour metNWeatherHourFromJson(item, double lat, double lng) {
  return WeatherHour(
    windGustKmh: null,
    condition: metNConditionFromJson(item),
    tempC: item["data"]["instant"]["details"]["air_temperature"],
    precipMm: metNPrecipAmountFromJson(item),
    precipProb: metNPrecipProbabilityFromJson(item),
    time: metNLocalTimeFromJson(item, lat, lng),
    windKmh: item["data"]["instant"]["details"]["wind_speed"] * 3.6,
    windDirA:
        item["data"]["instant"]["details"]["wind_from_direction"]?.round(),
    uv: item["data"]["instant"]["details"]["ultraviolet_index_clear_sky"]
        ?.round(),
  );
}

Future<WeatherSunStatus> metNGetWeatherSunStatus(
    item, double lat, double lng, DateTime timeThere) async {
  final date =
      "${timeThere.year}-${timeThere.month.toString().padLeft(2, "0")}-${timeThere.day.toString().padLeft(2, "0")}";
  final MnParams = {
    "lat": lat.toString(),
    "lon": lng.toString(),
    "date": date,
  };
  final headers = {
    "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
  };
  final MnUrl = Uri.https("api.met.no", 'weatherapi/sunrise/3.0/sun', MnParams);

  var MnFile = await XCustomCacheManager.fetchData(
      MnUrl.toString(), "$lat, $lng $date met.no sun",
      headers: headers);
  var MnResponse = await MnFile[0].readAsString();
  final item = jsonDecode(MnResponse);

  DateTime sunrise = TimezoneService.localDateTimeFromUtc(
      lat, lng, DateTime.parse(item["properties"]["sunrise"]["time"]));
  DateTime sunset = TimezoneService.localDateTimeFromUtc(
      lat, lng, DateTime.parse(item["properties"]["sunset"]["time"]));

  return WeatherSunStatus(
    sunrise: sunrise,
    sunset: sunset,
    sunstatus: min(
        max(
            timeThere.difference(sunrise).inMinutes /
                sunset.difference(sunrise).inMinutes,
            0),
        1),
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

  for (int i = 0; i < min(item["properties"]["timeseries"].length, 6); i++) {
    double x = double.parse(
        metNPrecipAmountFromJson(item["properties"]["timeseries"][i])
            .toStringAsFixed(1));

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
      double g = (now + dif * x) /
          4; //because we are dividing the sum of 1 hour into quarters
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
      } else {
        text = "rainInHours";
        time = end;
      }
    } else if (closest < 1) {
      text = "rainExpectedInOneHour";
    } else {
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
  final double latitude = (lat as num).toDouble();
  final double longitude = (lng as num).toDouble();

  var Mn = await MetNMakeRequest(latitude, longitude, placeName);
  var MnBody = Mn[0];

  DateTime localTime = TimezoneService.getLocalTime(latitude, longitude);
  DateTime fetch_datetime = Mn[1];

  bool isonline = Mn[2];

  //removes the outdated hours
  DateTime approximateLocal =
      DateTime(localTime.year, localTime.month, localTime.day, localTime.hour);
  int start = (MnBody["properties"]["timeseries"] as List).indexWhere((item) {
    final itemLocalTime = metNLocalTimeFromJson(item, latitude, longitude);
    return !itemLocalTime.isBefore(approximateLocal);
  });

  //make sure that there is data left
  if (start < 0 || start >= MnBody["properties"]["timeseries"].length) {
    throw const SocketException("Cached data expired");
  }

  //remove outdated hours
  MnBody["properties"]["timeseries"] =
      MnBody["properties"]["timeseries"].sublist(start);

  List<WeatherDay> days = [];
  List<WeatherHour> hourly72 = [];

  int begin = 0;
  int index = 0;

  DateTime previousLocalTime = metNLocalTimeFromJson(
      MnBody["properties"]["timeseries"][0], latitude, longitude);
  for (int n = 1; n < MnBody["properties"]["timeseries"].length; n++) {
    final localForecastTime = metNLocalTimeFromJson(
        MnBody["properties"]["timeseries"][n], latitude, longitude);
    if (!metNIsSameLocalDate(localForecastTime, previousLocalTime)) {
      WeatherDay day =
          metNWeatherDayFromJson(MnBody, begin, n, index, latitude, longitude);
      days.add(day);

      if (hourly72.length < 72) {
        for (int z = 0; z < day.hourly.length; z++) {
          if (hourly72.length < 72) {
            hourly72.add(day.hourly[z]);
          }
        }
      }

      index += 1;
      begin = n;
    }
    previousLocalTime = localForecastTime;
  }

  if (begin < MnBody["properties"]["timeseries"].length) {
    WeatherDay day = metNWeatherDayFromJson(MnBody, begin,
        MnBody["properties"]["timeseries"].length, index, latitude, longitude);
    days.add(day);

    if (hourly72.length < 72) {
      for (int z = 0; z < day.hourly.length; z++) {
        if (hourly72.length < 72) {
          hourly72.add(day.hourly[z]);
        }
      }
    }
  }

  return WeatherData(
    provider: "met norway",
    lat: latitude,
    lng: longitude,
    place: placeName,
    radar: await RainviewerRadar.getData(),
    aqi: await oMGetWeatherAqi(latitude, longitude),
    sunStatus:
        await metNGetWeatherSunStatus(MnBody, latitude, longitude, localTime),
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

Future<dynamic> metNGetLightResponse(lat, lon, {bool isCompact = true}) async {
  final params = {
    "lat": lat.toString(),
    "lon": lon.toString(),
    "altitude": "100",
  };

  final headers = {
    "User-Agent": "Overmorrow weather (com.marotidev.overmorrow)"
  };
  final url = Uri.https(
      "api.met.no",
      'weatherapi/locationforecast/2.0/${isCompact ? "compact" : "complete"}',
      params);

  final response = (await http.get(url, headers: headers)).body;

  return jsonDecode(response);
}

Future<LightCurrentWeatherData> metNGetLightCurrentData(
    placeName, lat, lon, SharedPreferences prefs) async {
  final item = await metNGetLightResponse(lat, lon);

  DateTime now = DateTime.now();
  final firstTimeseries = item["properties"]["timeseries"][0];

  return LightCurrentWeatherData(
    condition: metNConditionFromJson(firstTimeseries),
    place: placeName,
    temp: unitConversion(
            item["properties"]["timeseries"][0]["data"]["instant"]["details"]
                ["air_temperature"],
            prefs.getString("Temperature") ?? "˚C")
        .round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    dateString: getDateStringFromLocalTime(now),
  );
}

Future<LightWindData> metNGetLightWindData(
    lat, lon, SharedPreferences prefs) async {
  final item = await metNGetLightResponse(lat, lon);

  return LightWindData(
    windDirAngle: item["properties"]["timeseries"][0]["data"]["instant"]
            ["details"]["wind_from_direction"]
        .round(),
    windSpeed: unitConversion(
            item["properties"]["timeseries"][0]["data"]["instant"]["details"]
                    ["wind_speed"] *
                3.6,
            prefs.getString("Wind") ?? "m/s")
        .round(),
    windUnit: prefs.getString("Wind") ?? "m/s",
  );
}

Future<LightUvData> metNGetLightUvData(
    lat, lon, SharedPreferences prefs) async {
  final item = await metNGetLightResponse(lat, lon, isCompact: false);

  return LightUvData(
    uv: item["properties"]["timeseries"][0]["data"]["instant"]["details"]
            ["ultraviolet_index_clear_sky"]
        .round(),
  );
}

Future<LightHourlyForecastData> metNGetLightHourlyData(
    placeName, lat, lon, SharedPreferences prefs) async {
  final item = await metNGetLightResponse(lat, lon);

  List<String> hourly6Conditions = [];
  List<int> hourly6Temps = [];
  List<String> hourly6Names = [];

  List<String> hourly1Conditions = [];
  List<int> hourly1Temps = [];
  List<String> hourly1Names = [];

  DateTime now = DateTime.now();

  final String tempUnit = prefs.getString("Temperature") ?? "˚C";
  final String timeMode = prefs.getString("Time mode") ?? "12 hour";

  for (int i = 0; i < min(item["properties"]["timeseries"].length, 23); i++) {
    final hour = item["properties"]["timeseries"][i];

    DateTime d = DateTime.parse(hour["time"]).toLocal();

    if (d.hour % 6 == 0) {
      hourly6Conditions.add(metNConditionFromJson(hour));
      hourly6Temps.add(
        unitConversion(
                hour["data"]["instant"]["details"]["air_temperature"], tempUnit)
            .round(),
      );
      hourly6Names.add(formatHourByTimeMode(d, timeMode));
    }

    if (i < 4) {
      hourly1Conditions.add(metNConditionFromJson(hour));
      hourly1Temps.add(
        unitConversion(
                hour["data"]["instant"]["details"]["air_temperature"], tempUnit)
            .round(),
      );
      hourly1Names.add(formatHourByTimeMode(d, timeMode));
    }
  }

  return LightHourlyForecastData(
    place: placeName,
    currentCondition:
        metNConditionFromJson(item["properties"]["timeseries"][0]),
    currentTemp: unitConversion(
            item["properties"]["timeseries"][0]["data"]["instant"]["details"]
                ["air_temperature"],
            tempUnit)
        .round(),
    updatedTime: "${now.hour}:${now.minute.toString().padLeft(2, "0")}",
    //i can't sync lists to widgets so i need to encode and then decode them
    hourly6Conditions: jsonEncode(hourly6Conditions),
    hourly6Names: jsonEncode(hourly6Names),
    hourly6Temps: jsonEncode(hourly6Temps),

    hourly1Conditions: jsonEncode(hourly1Conditions),
    hourly1Names: jsonEncode(hourly1Names),
    hourly1Temps: jsonEncode(hourly1Temps),
  );
}
