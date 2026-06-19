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
import 'package:shared_preferences/shared_preferences.dart';

import '../services/caching_service.dart';
import '../services/weather_service.dart';
import 'decode_OM.dart';
import 'decode_RV.dart';
import 'weather_data.dart';

const String _mfApiHost = 'webservice.meteofrance.com';
const String _mfApiToken = '__Wj7dVSTjV9YGu1guveLyDq0g7S7TfTjaHBTPTpO0kj8__';

const Map<String, String> _mfWarningPhenomenons = {
  '1': 'Wind',
  '2': 'Rain-Flood',
  '3': 'Thunderstorms',
  '4': 'Flood',
  '5': 'Snow/Ice',
  '6': 'Heat wave',
  '7': 'Extreme cold',
  '8': 'Avalanches',
  '9': 'Coastal event',
};

const Map<int, String> _mfWarningColors = {
  1: 'green',
  2: 'yellow',
  3: 'orange',
  4: 'red',
};

const List<String> _mfProbabilityWindows = ['1h', '3h', '6h', '12h', '24h'];

double _mfDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int? _mfInt(dynamic value) {
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return double.tryParse(value)?.round();
  }
  return null;
}

DateTime _mfDateFromTimestamp(dynamic timestamp) {
  return DateTime.fromMillisecondsSinceEpoch(
    (_mfDouble(timestamp) * 1000).round(),
    isUtc: true,
  ).toLocal();
}

Duration _mfAbsoluteDifference(DateTime a, DateTime b) {
  return Duration(microseconds: a.difference(b).inMicroseconds.abs());
}

double _mfNestedDouble(dynamic item, String section, String key,
    [double fallback = 0]) {
  if (item is Map && item[section] is Map) {
    return _mfDouble(item[section][key], fallback);
  }
  return fallback;
}

int? _mfNestedInt(dynamic item, String section, String key) {
  if (item is Map && item[section] is Map) {
    return _mfInt(item[section][key]);
  }
  return null;
}

String _mfNormalizeText(dynamic value) {
  return (value ?? '')
      .toString()
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c');
}

bool _mfIsNight(DateTime time, WeatherSunStatus? sunStatus, String icon) {
  final normalizedIcon = icon.toLowerCase();
  if (normalizedIcon.endsWith('n') || normalizedIcon.contains('nuit')) {
    return true;
  }
  if (sunStatus == null) {
    return false;
  }

  final sameDayTime = sunStatus.sunrise.copyWith(
    hour: time.hour,
    minute: time.minute,
  );
  return sameDayTime.difference(sunStatus.sunrise).isNegative ||
      sunStatus.sunset.difference(sameDayTime).isNegative;
}

String mfTextCorrection(dynamic weather, DateTime time,
    {WeatherSunStatus? sunStatus}) {
  final String icon = weather is Map ? (weather['icon'] ?? '').toString() : '';
  final String desc =
      _mfNormalizeText(weather is Map ? weather['desc'] : weather);
  final bool isNight = _mfIsNight(time, sunStatus, icon);

  if (desc.contains('orage')) {
    return 'Thunderstorm';
  }
  if (desc.contains('neige')) {
    if (desc.contains('fort') || desc.contains('abond')) {
      return 'Heavy Snow';
    }
    return 'Snow';
  }
  if (desc.contains('gresil') ||
      desc.contains('verglas') ||
      desc.contains('verglac')) {
    return 'Sleet';
  }
  if (desc.contains('pluie') ||
      desc.contains('averse') ||
      desc.contains('precipitation')) {
    if (desc.contains('fort') ||
        desc.contains('intense') ||
        desc.contains('tres')) {
      return 'Heavy Rain';
    }
    if (desc.contains('faible') || desc.contains('bruine')) {
      return 'Drizzle';
    }
    return 'Rain';
  }
  if (desc.contains('bruine')) {
    return 'Drizzle';
  }
  if (desc.contains('brouillard') || desc.contains('brume')) {
    return 'Fog';
  }
  if (desc.contains('couvert') || desc.contains('tres nuageux')) {
    return 'Overcast';
  }
  if (desc.contains('eclaircie') ||
      desc.contains('peu nuageux') ||
      desc.contains('variable') ||
      desc.contains('nuage')) {
    return isNight ? 'Cloudy Night' : 'Partly Cloudy';
  }
  if (desc.contains('soleil') ||
      desc.contains('clair') ||
      desc.contains('ensoleille') ||
      desc.contains('beau temps')) {
    return isNight ? 'Clear Night' : 'Clear Sky';
  }
  return isNight ? 'Clear Night' : 'Clear Sky';
}

Future<List<dynamic>> mfMakeForecastRequest(
    double lat, double lon, String place) async {
  final params = {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'lang': 'fr',
    'token': _mfApiToken,
  };
  final url = Uri.https(_mfApiHost, 'forecast', params);

  final file = await XCustomCacheManager.fetchData(
    url.toString(),
    '$place, meteo-france forecast',
  );

  final response = await file[0].readAsString();
  return [jsonDecode(response), await file[0].lastModified(), file[1]];
}

Future<dynamic> mfMakeObservationRequest(
    double lat, double lon, String place) async {
  final params = {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'lang': 'fr',
    'token': _mfApiToken,
  };
  final url = Uri.https(_mfApiHost, 'v2/observation', params);

  try {
    final file = await XCustomCacheManager.fetchData(
      url.toString(),
      '$place, meteo-france observation',
    );
    return jsonDecode(await file[0].readAsString());
  } catch (_) {
    return null;
  }
}

Future<dynamic> mfMakeRainRequest(double lat, double lon, String place) async {
  final params = {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'lang': 'fr',
    'token': _mfApiToken,
  };
  final url = Uri.https(_mfApiHost, 'rain', params);

  try {
    final file = await XCustomCacheManager.fetchData(
      url.toString(),
      '$place, meteo-france rain',
    );
    return jsonDecode(await file[0].readAsString());
  } catch (_) {
    return null;
  }
}

Future<dynamic> mfGetLightForecastResponse(double lat, double lon) async {
  final params = {
    'lat': lat.toString(),
    'lon': lon.toString(),
    'lang': 'fr',
    'token': _mfApiToken,
  };
  final url = Uri.https(_mfApiHost, 'forecast', params);
  final response = await http.get(url);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('Meteo France forecast failed: ${response.statusCode}');
  }
  return jsonDecode(response.body);
}

dynamic _mfFirstOrEmpty(List<dynamic> values) {
  return values.isEmpty ? <String, dynamic>{} : values.first;
}

WeatherSunStatus mfWeatherSunStatusFromDaily(
    dynamic daily, DateTime localTime) {
  final sun = daily is Map && daily['sun'] is Map ? daily['sun'] : null;
  final sunrise = sun == null
      ? DateTime(localTime.year, localTime.month, localTime.day, 6)
      : _mfDateFromTimestamp(sun['rise']);
  final sunset = sun == null
      ? DateTime(localTime.year, localTime.month, localTime.day, 18)
      : _mfDateFromTimestamp(sun['set']);
  final daylightMinutes = max(sunset.difference(sunrise).inMinutes, 1);

  return WeatherSunStatus(
    sunrise: sunrise,
    sunset: sunset,
    sunstatus: min(
      max(localTime.difference(sunrise).inMinutes / daylightMinutes, 0),
      1,
    ),
  );
}

dynamic _mfNearestForecast(List<dynamic> forecast, DateTime localTime) {
  if (forecast.isEmpty) {
    return {};
  }
  return forecast.reduce((a, b) {
    final aDiff =
        _mfAbsoluteDifference(_mfDateFromTimestamp(a['dt']), localTime);
    final bDiff =
        _mfAbsoluteDifference(_mfDateFromTimestamp(b['dt']), localTime);
    return aDiff.compareTo(bDiff) <= 0 ? a : b;
  });
}

Map<int, dynamic> _mfProbabilityByTimestamp(List<dynamic> probabilities) {
  return {
    for (final item in probabilities)
      if (item is Map && item['dt'] != null) _mfInt(item['dt']) ?? 0: item
  };
}

int? _mfPrecipProbabilityForWindow(dynamic item, String window) {
  if (item is! Map) {
    return null;
  }

  final values = <int>[];
  for (final section in ['rain', 'snow']) {
    if (item[section] is Map) {
      final value = _mfInt(item[section][window]);
      if (value != null) {
        values.add(value);
      }
    }
  }

  if (values.isEmpty) {
    return null;
  }
  return values.reduce(max);
}

int? _mfPrecipProbabilityForTimestamp(
  Map<int, dynamic> probabilityByDt,
  int timestamp,
) {
  int? bestValue;
  int? bestWindowSeconds;
  int? bestDistanceSeconds;

  for (final entry in probabilityByDt.entries) {
    final probabilityTimestamp = entry.key;

    for (final window in _mfProbabilityWindows) {
      final windowHours = int.tryParse(window.replaceAll('h', ''));
      final value = _mfPrecipProbabilityForWindow(entry.value, window);

      if (windowHours == null || value == null) {
        continue;
      }

      final windowSeconds = windowHours * 60 * 60;
      if (timestamp < probabilityTimestamp - windowSeconds ||
          timestamp > probabilityTimestamp) {
        continue;
      }

      final distanceSeconds = (probabilityTimestamp - timestamp).abs();
      final isBetter = bestValue == null ||
          windowSeconds < bestWindowSeconds! ||
          (windowSeconds == bestWindowSeconds &&
              distanceSeconds < bestDistanceSeconds!);

      if (isBetter) {
        bestValue = value;
        bestWindowSeconds = windowSeconds;
        bestDistanceSeconds = distanceSeconds;
      }
    }
  }

  return bestValue;
}

double _mfPrecipMm(dynamic item) {
  return _mfNestedDouble(item, 'rain', '1h') +
      _mfNestedDouble(item, 'snow', '1h');
}

WeatherHour mfWeatherHourFromJson(
  dynamic item,
  Map<int, dynamic> probabilityByDt,
  int? uv,
  WeatherSunStatus sunStatus,
) {
  final timestamp = _mfInt(item['dt']) ?? 0;
  final time = _mfDateFromTimestamp(timestamp);

  return WeatherHour(
    tempC: _mfNestedDouble(item, 'T', 'value'),
    time: time,
    condition: mfTextCorrection(item['weather'], time, sunStatus: sunStatus),
    precipMm: _mfPrecipMm(item),
    precipProb: _mfPrecipProbabilityForTimestamp(probabilityByDt, timestamp),
    windKmh: _mfNestedDouble(item, 'wind', 'speed'),
    windDirA: _mfNestedInt(item, 'wind', 'direction'),
    windGustKmh: _mfNestedDouble(item, 'wind', 'gust'),
    uv: uv,
  );
}

List<WeatherHour> mfBuildWeatherHourList(
  List<dynamic> forecast,
  Map<int, dynamic> probabilityByDt,
  DateTime dayDate,
  DateTime localTime,
  int? uv,
  WeatherSunStatus sunStatus,
) {
  final threshold =
      DateTime(localTime.year, localTime.month, localTime.day, localTime.hour);
  final hours = <WeatherHour>[];

  for (final item in forecast) {
    final time = _mfDateFromTimestamp(item['dt']);
    final isSameDay = time.year == dayDate.year &&
        time.month == dayDate.month &&
        time.day == dayDate.day;

    if (isSameDay && !time.isBefore(threshold)) {
      hours.add(mfWeatherHourFromJson(item, probabilityByDt, uv, sunStatus));
    }
  }

  return hours;
}

WeatherDay mfWeatherDayFromJson(
  dynamic item,
  List<dynamic> forecast,
  Map<int, dynamic> probabilityByDt,
  DateTime localTime,
) {
  final date = _mfDateFromTimestamp(item['dt']);
  final uv = _mfInt(item['uv']);
  final sunStatus = mfWeatherSunStatusFromDaily(item, localTime);
  final hours = mfBuildWeatherHourList(
    forecast,
    probabilityByDt,
    date,
    localTime,
    uv,
    sunStatus,
  );

  final windSpeeds = hours.map((hour) => hour.windKmh).toList();
  final windDirections =
      hours.map((hour) => hour.windDirA).whereType<int>().toList();
  final precipProbabilities =
      hours.map((hour) => hour.precipProb).whereType<int>().toList();

  return WeatherDay(
    condition: mfTextCorrection(item['weather12H'], date),
    date: DateTime(date.year, date.month, date.day),
    minTempC: _mfNestedDouble(item, 'T', 'min'),
    maxTempC: _mfNestedDouble(item, 'T', 'max'),
    hourly: hours,
    precipProb:
        precipProbabilities.isEmpty ? null : precipProbabilities.reduce(max),
    totalPrecipMm: _mfNestedDouble(item, 'precipitation', '24h'),
    windKmh: windSpeeds.isEmpty ? 0 : windSpeeds.reduce(max),
    windDirA: windDirections.isEmpty
        ? null
        : (windDirections.reduce((a, b) => a + b) / windDirections.length)
            .round(),
    uv: uv,
  );
}

WeatherCurrent mfWeatherCurrentFromJson(
  dynamic forecast,
  dynamic observation,
  dynamic today,
  WeatherSunStatus sunStatus,
  DateTime localTime,
) {
  final gridded = observation is Map &&
          observation['properties'] is Map &&
          observation['properties']['gridded'] is Map
      ? observation['properties']['gridded']
      : null;

  final observedTemp =
      gridded == null ? null : _mfDouble(gridded['T'], double.nan);
  final observedWind =
      gridded == null ? null : _mfDouble(gridded['wind_speed'], double.nan);
  final observedWindDir =
      gridded == null ? null : _mfInt(gridded['wind_direction']);
  final observedWeather = gridded == null
      ? null
      : {
          'icon': gridded['weather_icon'],
          'desc': gridded['weather_description'],
        };

  final temp = observedTemp == null || observedTemp.isNaN
      ? _mfNestedDouble(forecast, 'T', 'value')
      : observedTemp;

  return WeatherCurrent(
    condition: mfTextCorrection(
        observedWeather ?? forecast['weather'], localTime,
        sunStatus: sunStatus),
    tempC: temp,
    humidity: _mfInt(forecast['humidity']) ?? 0,
    feelsLikeC: _mfNestedDouble(forecast, 'T', 'windchill', temp),
    uv: _mfInt(today['uv']) ?? 0,
    precipMm: _mfNestedDouble(today, 'precipitation', '24h'),
    windKmh: observedWind == null || observedWind.isNaN
        ? _mfNestedDouble(forecast, 'wind', 'speed')
        : observedWind,
    windDirA:
        observedWindDir ?? _mfNestedInt(forecast, 'wind', 'direction') ?? 0,
  );
}

WeatherRain15Minutes mfWeatherRain15MinutesFromRain(dynamic item) {
  final rawForecast = item is Map && item['forecast'] is List
      ? List<dynamic>.from(item['forecast'])
      : <dynamic>[];
  final chunks = List<double>.filled(4, 0);

  if (rawForecast.isNotEmpty) {
    final firstTime = _mfDateFromTimestamp(rawForecast.first['dt']);

    for (final item in rawForecast) {
      final minutes = max(
        0,
        _mfDateFromTimestamp(item['dt']).difference(firstTime).inMinutes,
      );
      final index = min(3, minutes ~/ 15);
      final rainCode = _mfInt(item['rain']) ?? 1;
      final value = switch (rainCode) {
        2 => 0.2,
        3 => 0.8,
        4 => 1.6,
        _ => 0.0,
      };

      chunks[index] = max(chunks[index], value);
    }
  }

  final sum = chunks.reduce((a, b) => a + b);

  int closest = 100;
  int end = -1;
  for (int i = 0; i < chunks.length; i++) {
    if (chunks[i] > 0) {
      closest = min(closest, i);
      end = max(end, i);
    }
  }

  String text = '';
  int time = 0;
  if (closest != 100) {
    if (closest <= 1) {
      if (end == 1) {
        text = 'rainInHalfHour';
      } else if (end <= 2) {
        time = [15, 30, 45][end];
        text = 'rainInMinutes';
      } else if (end ~/ 4 == 1) {
        text = 'rainInOneHour';
      } else {
        time = (end + 2) ~/ 4;
        text = 'rainInHours';
      }
    } else if (closest < 4) {
      time = [15, 30, 45][closest - 1];
      text = 'rainExpectedInMinutes';
    } else if ((closest + 2) ~/ 4 == 1) {
      text = 'rainExpectedInOneHour';
    } else {
      time = (closest + 2) ~/ 4;
      text = 'rainExpectedInHours';
    }
  }

  return WeatherRain15Minutes(
    text: text,
    timeTo: time,
    precipSumMm: sum > 0 ? max(sum, 0.1) : 0,
    precipListMm: chunks,
  );
}

WeatherRain15Minutes mfWeatherRain15MinutesFromHours(List<WeatherHour> hourly) {
  int closest = 100;
  int end = -1;
  double sum = 0;

  final precips = <double>[];
  final source = hourly
      .take(6)
      .map((hour) => double.parse(hour.precipMm.toStringAsFixed(1)))
      .toList();

  for (int i = 0; i < source.length; i++) {
    if (source[i] > 0) {
      closest = min(closest, i + 1);
      end = max(end, i + 1);
    }
  }

  for (int i = 0; i < source.length - 1; i++) {
    final now = source[i];
    final next = source[i + 1];
    final dif = next - now;

    for (double x = 0; x <= 1; x += 0.25) {
      final value = (now + dif * x) / 4;
      sum += value;
      precips.add(value);
    }
  }

  int time = 0;
  String text = '';
  if (closest != 100) {
    if (closest <= 2) {
      if (end <= 1) {
        text = 'rainInOneHour';
      } else {
        text = 'rainInHours';
        time = end;
      }
    } else {
      text = 'rainExpectedInHours';
      time = closest;
    }
  }

  return WeatherRain15Minutes(
    text: text,
    timeTo: time,
    precipSumMm: sum > 0 ? max(sum, 0.1) : 0,
    precipListMm: precips,
  );
}

String _mfWarningDescription(dynamic full, String phenomenonId) {
  final parts = <String>[];

  if (full is Map &&
      full['comments'] is Map &&
      full['comments']['text'] is List) {
    parts.addAll((full['comments']['text'] as List).whereType<String>());
  }

  final blocs = full is Map && full['text'] is Map
      ? full['text']['text_bloc_item']
      : null;
  if (blocs is List) {
    for (final bloc in blocs) {
      final textItems = bloc is Map ? bloc['text_items'] : null;
      if (textItems is! List) {
        continue;
      }
      for (final textItem in textItems) {
        if (textItem is! Map ||
            textItem['hazard_code']?.toString() != phenomenonId) {
          continue;
        }
        final termItems = textItem['term_items'];
        if (termItems is! List) {
          continue;
        }
        for (final term in termItems) {
          final subdivisions = term is Map ? term['subdivision_text'] : null;
          if (subdivisions is! List) {
            continue;
          }
          for (final subdivision in subdivisions) {
            if (subdivision is! Map) {
              continue;
            }
            final title = (subdivision['bold_text'] ?? '').toString().trim();
            final texts = subdivision['text'];
            if (title.isNotEmpty) {
              parts.add(title);
            }
            if (texts is List) {
              parts.addAll(texts
                  .whereType<String>()
                  .where((text) => text.trim().isNotEmpty));
            }
          }
        }
      }
    }
  }

  return parts.isEmpty ? 'Meteo France vigilance bulletin.' : parts.join('\n');
}

Future<List<WeatherAlert>> mfGetWeatherAlerts(dynamic position) async {
  if (position is! Map || position['dept'] == null) {
    return [];
  }

  final dept = position['dept'].toString();
  final params = {
    'domain': dept,
    'token': _mfApiToken,
  };

  try {
    final fullUrl = Uri.https(_mfApiHost, 'v3/warning/full', params);
    final fullFile = await XCustomCacheManager.fetchData(
      fullUrl.toString(),
      '$dept, meteo-france warnings',
    );
    final full = jsonDecode(await fullFile[0].readAsString());

    final dictionaryUrl = Uri.https(_mfApiHost, 'v3/warning/dictionary', {
      'lang': 'fr',
      'token': _mfApiToken,
    });
    final dictionaryFile = await XCustomCacheManager.fetchData(
      dictionaryUrl.toString(),
      'meteo-france warning dictionary',
    );
    final dictionary = jsonDecode(await dictionaryFile[0].readAsString());

    final phenomenonNames = Map<String, String>.from(_mfWarningPhenomenons);
    final colorNames = Map<int, String>.from(_mfWarningColors);

    if (dictionary is Map && dictionary['phenomenons'] is List) {
      for (final phenomenon in dictionary['phenomenons']) {
        if (phenomenon is Map) {
          phenomenonNames[phenomenon['id'].toString()] =
              phenomenon['name'].toString();
        }
      }
    }
    if (dictionary is Map && dictionary['colors'] is List) {
      for (final color in dictionary['colors']) {
        if (color is Map) {
          final id = _mfInt(color['id']);
          if (id != null) {
            colorNames[id] = color['name'].toString();
          }
        }
      }
    }

    final alerts = <WeatherAlert>[];
    final phenomenons = full is Map && full['phenomenons_items'] is List
        ? full['phenomenons_items'] as List
        : [];

    for (final item in phenomenons) {
      if (item is! Map) {
        continue;
      }
      final colorId = _mfInt(item['phenomenon_max_color_id']) ?? 1;
      if (colorId <= 1) {
        continue;
      }

      final phenomenonId = item['phenomenon_id'].toString();
      final phenomenonName = phenomenonNames[phenomenonId] ?? 'Weather alert';
      final colorName = colorNames[colorId] ?? 'unknown';
      DateTime? start;
      DateTime? end;

      if (full['timelaps'] is List) {
        for (final timelaps in full['timelaps']) {
          if (timelaps is! Map ||
              timelaps['phenomenon_id'].toString() != phenomenonId) {
            continue;
          }
          final timelapsItems = timelaps['timelaps_items'];
          if (timelapsItems is! List || timelapsItems.isEmpty) {
            continue;
          }
          final first = timelapsItems.first;
          final last = timelapsItems.last;
          if (first is Map) {
            start = _mfDateFromTimestamp(first['begin_time']);
          }
          if (last is Map) {
            end = _mfDateFromTimestamp(last['end_time']);
          }
        }
      }

      alerts.add(
        WeatherAlert(
          headline: 'Vigilance $colorName: $phenomenonName',
          start: start,
          end: end,
          desc: _mfWarningDescription(full, phenomenonId),
          event: phenomenonName,
          urgency: colorName,
          severity: colorName,
          certainty: '--',
          areas: '${position['name'] ?? 'Meteo France'} ($dept)',
        ),
      );
    }

    return alerts;
  } catch (_) {
    return [];
  }
}

Future<WeatherData> MfGetWeatherData(lat, lng, placeName) async {
  final mf = await mfMakeForecastRequest(lat, lng, placeName);
  final body = mf[0];
  final fetchDatetime = mf[1];
  final isOnline = mf[2];

  final forecast = List<dynamic>.from(body['forecast'] ?? []);
  final dailyForecast = List<dynamic>.from(body['daily_forecast'] ?? []);

  if (forecast.isEmpty || dailyForecast.isEmpty) {
    throw const SocketException('Meteo France forecast unavailable');
  }

  final localTime = DateTime.now();
  final today = dailyForecast.first;
  final sunStatus = mfWeatherSunStatusFromDaily(today, localTime);
  final probabilityByDt = _mfProbabilityByTimestamp(
    List<dynamic>.from(body['probability_forecast'] ?? []),
  );

  final days = <WeatherDay>[];
  final hourly72 = <WeatherHour>[];

  for (final item in dailyForecast) {
    final day =
        mfWeatherDayFromJson(item, forecast, probabilityByDt, localTime);
    days.add(day);

    for (final hour in day.hourly) {
      if (hourly72.length < 72) {
        hourly72.add(hour);
      }
    }
  }

  if (hourly72.isEmpty) {
    throw const SocketException('Meteo France cached data expired');
  }

  final currentForecast = _mfNearestForecast(forecast, localTime);
  final observation = await mfMakeObservationRequest(lat, lng, placeName);
  final rain =
      body['position'] is Map && body['position']['rain_product_available'] == 1
          ? await mfMakeRainRequest(lat, lng, placeName)
          : null;

  return WeatherData(
    place: placeName,
    lat: lat,
    lng: lng,
    provider: 'meteo-france',
    updatedTime: DateTime.now(),
    fetchDatetime: fetchDatetime,
    localTime: localTime,
    isOnline: isOnline,
    days: days,
    hourly72: hourly72,
    current: mfWeatherCurrentFromJson(
        currentForecast, observation, today, sunStatus, localTime),
    aqi: await oMGetWeatherAqi(lat, lng),
    sunStatus: sunStatus,
    minutely15Precip: rain == null
        ? mfWeatherRain15MinutesFromHours(hourly72)
        : mfWeatherRain15MinutesFromRain(rain),
    alerts: await mfGetWeatherAlerts(body['position']),
    radar: await RainviewerRadar.getData(),
    dailyMinMaxTemp: weatherGetMaxMinTempForDaily(days),
  );
}

Future<LightCurrentWeatherData> mfGetLightCurrentData(
  placeName,
  lat,
  lon,
  SharedPreferences prefs,
) async {
  final item = await mfGetLightForecastResponse(lat, lon);
  final forecast = List<dynamic>.from(item['forecast'] ?? []);
  final daily = List<dynamic>.from(item['daily_forecast'] ?? []);
  final now = DateTime.now();
  final current = _mfNearestForecast(forecast, now);
  final sunStatus = mfWeatherSunStatusFromDaily(_mfFirstOrEmpty(daily), now);

  return LightCurrentWeatherData(
    place: placeName,
    temp: unitConversion(
      _mfNestedDouble(current, 'T', 'value'),
      prefs.getString('Temperature') ?? 'ËšC',
    ).round(),
    condition: mfTextCorrection(current['weather'], now, sunStatus: sunStatus),
    updatedTime: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    dateString: getDateStringFromLocalTime(now),
  );
}

Future<LightWindData> mfGetLightWindData(
    lat, lon, SharedPreferences prefs) async {
  final item = await mfGetLightForecastResponse(lat, lon);
  final forecast = List<dynamic>.from(item['forecast'] ?? []);
  final current = _mfNearestForecast(forecast, DateTime.now());

  return LightWindData(
    windSpeed: unitConversion(
      _mfNestedDouble(current, 'wind', 'speed'),
      prefs.getString('Wind') ?? 'm/s',
    ).round(),
    windDirAngle: _mfNestedInt(current, 'wind', 'direction') ?? 0,
    windUnit: prefs.getString('Wind') ?? 'm/s',
  );
}

Future<LightUvData> mfGetLightUvData(lat, lon, SharedPreferences prefs) async {
  final item = await mfGetLightForecastResponse(lat, lon);
  final daily = List<dynamic>.from(item['daily_forecast'] ?? []);

  return LightUvData(
    uv: _mfInt(_mfFirstOrEmpty(daily)['uv']) ?? 0,
  );
}

Future<LightHourlyForecastData> mfGetLightHourlyData(
  placeName,
  lat,
  lon,
  SharedPreferences prefs,
) async {
  final item = await mfGetLightForecastResponse(lat, lon);
  final forecast = List<dynamic>.from(item['forecast'] ?? []);
  final daily = List<dynamic>.from(item['daily_forecast'] ?? []);
  final now = DateTime.now();
  final current = _mfNearestForecast(forecast, now);
  final sunStatus = mfWeatherSunStatusFromDaily(_mfFirstOrEmpty(daily), now);

  final hourly6Conditions = <String>[];
  final hourly6Temps = <int>[];
  final hourly6Names = <String>[];

  final hourly1Conditions = <String>[];
  final hourly1Temps = <int>[];
  final hourly1Names = <String>[];

  final tempUnit = prefs.getString('Temperature') ?? 'ËšC';
  final timeMode = prefs.getString('Time mode') ?? '12 hour';

  for (final hour in forecast) {
    final time = _mfDateFromTimestamp(hour['dt']);

    if (time.hour % 6 == 0 && hourly6Conditions.length < 4) {
      hourly6Conditions
          .add(mfTextCorrection(hour['weather'], time, sunStatus: sunStatus));
      hourly6Temps.add(
          unitConversion(_mfNestedDouble(hour, 'T', 'value'), tempUnit)
              .round());
      hourly6Names.add(formatHourByTimeMode(time, timeMode));
    }

    if (!time.isBefore(now) && hourly1Conditions.length < 4) {
      hourly1Conditions
          .add(mfTextCorrection(hour['weather'], time, sunStatus: sunStatus));
      hourly1Temps.add(
          unitConversion(_mfNestedDouble(hour, 'T', 'value'), tempUnit)
              .round());
      hourly1Names.add(formatHourByTimeMode(time, timeMode));
    }
  }

  return LightHourlyForecastData(
    currentTemp:
        unitConversion(_mfNestedDouble(current, 'T', 'value'), tempUnit)
            .round(),
    currentCondition:
        mfTextCorrection(current['weather'], now, sunStatus: sunStatus),
    place: placeName,
    updatedTime: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    hourly6Conditions: jsonEncode(hourly6Conditions),
    hourly6Temps: jsonEncode(hourly6Temps),
    hourly6Names: jsonEncode(hourly6Names),
    hourly1Conditions: jsonEncode(hourly1Conditions),
    hourly1Temps: jsonEncode(hourly1Temps),
    hourly1Names: jsonEncode(hourly1Names),
  );
}
