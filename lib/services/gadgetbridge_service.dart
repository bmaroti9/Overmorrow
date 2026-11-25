import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../decoders/weather_data.dart';
import 'timezone_service.dart';

class GadgetbridgeService {
  static const _action = 'nodomain.freeyourgadget.gadgetbridge.ACTION_GENERIC_WEATHER';
  static const _packages = [
    'nodomain.freeyourgadget.gadgetbridge',
    'com.espruino.gadgetbridge.banglejs',
    'nodomain.freeyourgadget.gadgetbridge.nightly',
    'com.espruino.gadgetbridge.banglejs.nightly',
    'nodomain.freeyourgadget.gadgetbridge.nightly_nopebble',
  ];

  static const _conditionCodes = <String, int>{
    'Clear Sky': 800,
    'Clear Night': 800,
    'Partly Cloudy': 802,
    'Cloudy Night': 802,
    'Overcast': 804,
    'Haze': 721,
    'Fog': 741,
    'Drizzle': 300,
    'Rain': 501,
    'Heavy Rain': 502,
    'Sleet': 611,
    'Snow': 601,
    'Heavy Snow': 602,
    'Thunderstorm': 200,
  };

  static int _conditionCode(String condition) => _conditionCodes[condition] ?? 3200;
  static int _kelvin(double celsius) => (celsius + 273.15).round();
  static int _seconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;
  static DateTime _date(DateTime time) => DateTime.utc(time.year, time.month, time.day);

  static Map<String, Object> weatherSpec(WeatherData data) {
    final todayDate = _date(data.localTime);
    final today = data.days.where((day) => _date(day.date) == todayDate).firstOrNull;
    if (today == null) {
      throw StateError('No forecast for the current day');
    }

    final futureDays = data.days.where((day) => _date(day.date).isAfter(todayDate)).toList()
      ..sort((a, b) => _date(a.date).compareTo(_date(b.date)));
    int localTimeSeconds(DateTime time) => data.provider == 'meteo-france'
        ? _seconds(time)
        : _seconds(TimezoneService.utcFromLocalDateTime(data.lat, data.lng, time));
    DateTime sunTime(DateTime time) => DateTime(
        data.localTime.year, data.localTime.month, data.localTime.day, time.hour, time.minute, time.second);

    return {
      'timestamp': _seconds(data.fetchDatetime),
      'location': data.place,
      'latitude': data.lat,
      'longitude': data.lng,
      'currentTemp': _kelvin(data.current.tempC),
      'feelsLikeTemp': _kelvin(data.current.feelsLikeC),
      'todayMinTemp': _kelvin(today.minTempC),
      'todayMaxTemp': _kelvin(today.maxTempC),
      'currentCondition': data.current.condition,
      'currentConditionCode': _conditionCode(data.current.condition),
      'currentHumidity': data.current.humidity,
      'windSpeed': data.current.windKmh,
      'windDirection': data.current.windDirA,
      'uvIndex': data.current.uv,
      if (today.precipProb != null) 'precipProbability': today.precipProb!,
      'sunRise': localTimeSeconds(data.provider == 'meteo-france'
          ? data.sunStatus.sunrise : sunTime(data.sunStatus.sunrise)),
      'sunSet': localTimeSeconds(data.provider == 'meteo-france'
          ? data.sunStatus.sunset : sunTime(data.sunStatus.sunset)),
      'forecasts': [
        for (final day in futureDays)
          {
            'minTemp': _kelvin(day.minTempC),
            'maxTemp': _kelvin(day.maxTempC),
            'conditionCode': _conditionCode(day.condition),
            'windSpeed': day.windKmh,
            if (day.windDirA != null) 'windDirection': day.windDirA!,
            if (day.uv != null) 'uvIndex': day.uv!,
            if (day.precipProb != null) 'precipProbability': day.precipProb!,
          },
      ],
      'hourly': [
        for (final hour in data.hourly72)
          {
            'timestamp': localTimeSeconds(hour.time),
            'temp': _kelvin(hour.tempC),
            'conditionCode': _conditionCode(hour.condition),
            'windSpeed': hour.windKmh,
            if (hour.windDirA != null) 'windDirection': hour.windDirA!,
            if (hour.uv != null) 'uvIndex': hour.uv!,
            if (hour.precipProb != null) 'precipProbability': hour.precipProb!,
          },
      ],
    };
  }

  static Uint8List payload(WeatherData data) =>
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode([weatherSpec(data)]))));

  static Future<void> update(SharedPreferences prefs) async {
    final location = prefs.getString('LastPlaceN') ?? 'New York';
    final latLon = prefs.getString('LastCord') ?? '40.7128, -74.0060';
    final provider = prefs.getString('Weather provider') ?? 'open-meteo';
    final data = await WeatherData.getFullData(location, latLon, provider);
    if (!data.isOnline) {
      throw StateError('GadgetBridge weather data could not be refreshed');
    }

    await sendIfSelected(data, prefs);
  }

  static Future<void> sendIfSelected(WeatherData data, SharedPreferences prefs, {
    Future<void> Function(String package, Uint8List payload)? send,
  }) async {
    await prefs.reload();
    final coordinates = (prefs.getString('LastCord') ?? '40.7128, -74.0060').split(',');
    final provider = switch (data.provider) {
      'met norway' => 'met-norway',
      'weatherapi.com' => 'weatherapi',
      _ => data.provider,
    };
    if (!(prefs.getBool('GadgetBridge enabled') ?? false) ||
        (prefs.getString('LastPlaceN') ?? 'New York') != data.place ||
        coordinates.length != 2 ||
        double.tryParse(coordinates[0].trim()) != data.lat ||
        double.tryParse(coordinates[1].trim()) != data.lng ||
        (prefs.getString('Weather provider') ?? 'open-meteo') != provider) {
      return;
    }

    final compressed = payload(data);
    for (final package in _packages) {
      if (send != null) {
        await send(package, compressed);
      } else {
        await AndroidIntent(
          action: _action,
          package: package,
          arguments: {'WeatherGz': compressed},
        ).sendBroadcast();
      }
    }
  }
}
