import 'dart:math';
import 'dart:ui';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';
/*
class WeatherDataN {
  final List<String> settings;
  final String place;
  final String provider;
  final String real_loc;

  WeatherDataN({
    required this.place,
    required this.settings,
    required this.provider,
    required this.real_loc,
  });

  static WeatherDataN fromJson(jsonbody, settings, radar, placeName, real_loc) {

    return WeatherDataN(
        settings: settings,
        provider: 'met.norway',
        real_loc: real_loc,
        place: placeName,
    );
  }
}


class Current {
  final String text;
  final String backdrop;
  final int temp;
  final List<Color> contentColor;
  final int humidity;
  final int uv;
  final double precip;
  final int wind;
  final Color backcolor;
  final Color accentcolor;

  final double lat;
  final double lng;

  final List<String> radar;

  final String sunrise;
  final String sunset;
  final double sunstatus;

  final int aqi_index;
  final double pm2_5;
  final double pm10;
  final double o3;
  final double no2;

  const Current({
    required this.text,
    required this.backdrop,
    required this.temp,
    required this.contentColor,
    required this.precip,
    required this.humidity,
    required this.uv,
    required this.wind,
    required this.backcolor,
    required this.accentcolor,
    required this.sunrise,
    required this.sunset,
    required this.sunstatus,
    required this.aqi_index,
    required this.no2,
    required this.o3,
    required this.pm2_5,
    required this.pm10,
    required this.radar,
    required this.lat,
    required this.lng,
  });

  static Current fromJson(item, settings, radar) => Current(

    text: item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"],
    precip: item["timeseries"][0]["data"]["next_1_hours"]["details"]["precipitation_amount"],
    lng: item["geometry"]["coordinates"][0],
    lat: item["geometry"]["coordinates"][1],
    radar: radar,
    sunstatus: 'none'
  );
*/