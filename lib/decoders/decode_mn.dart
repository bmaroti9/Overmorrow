import 'dart:ui';

import 'package:hihi_haha/decoders/decode_wapi.dart';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';

String metNTextCorrection(String text, {language = 'English'}) {
  String p = metNWeatherToText[text] ?? 'Clear Sky';
  String t = translation(p, language);
  return t;
}

String metNBackdropCorrection(String text) {
  return textBackground[text] ?? 'very_clear.jpg';
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

class MetNCurrent {
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

  const MetNCurrent({
    required this.precip,
    required this.accentcolor,
    required this.backcolor,
    required this.backdrop,
    required this.contentColor,
    required this.humidity,
    required this.temp,
    required this.text,
    required this.uv,
    required this.wind,
  });

  static MetNCurrent fromJson(item, settings) => MetNCurrent(
    text: metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"], language: settings[0]),

    precip: unit_coversion(item["timeseries"][0]["data"]["next_1_hours"]["details"]["precipitation_amount"], settings[2]),
    temp: unit_coversion(item["timeseries"][0]["data"]["instant"]["details"]["air_temperature"], settings[1]).round(),
    humidity: item["timeseries"][0]["data"]["instant"]["details"]["relative_humidity"],
    wind: unit_coversion(item["timeseries"][0]["data"]["instant"]["details"]["wind_speed"] * 3.6, settings[3]).round(),
    uv: item["timeseries"][0]["data"]["instant"]["details"]["ultraviolet_index_clear_sky"],

    backdrop: metNBackdropCorrection(
      metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    ),
    backcolor: metNBackColorCorrection(
      metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    ),
    accentcolor: metNAccentColorCorrection(
      metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    ),
    contentColor: metNContentColorCorrection(
      metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    ),
  );
}

class MetNDay {
  final String date;
  final String text;
  final String icon;
  final String name;
  final String minmaxtemp;
  final List<WapiHour> hourly;
  final List<WapiHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;
  final int windspeed;
  final int avg_temp;
  final mm_precip;

  const MetNDay({
    required this.date,
    required this.text,
    required this.icon,
    required this.name,
    required this.minmaxtemp,
    required this.hourly,

    required this.precip_prob,
    required this.avg_temp,
    required this.total_precip,
    required this.windspeed,
    required this.hourly_for_precip,
    required this.mm_precip,
  });
}