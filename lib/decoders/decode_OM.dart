import 'dart:math';
import 'dart:ui';

import 'package:hihi_haha/decoders/decode_wapi.dart';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';

String oMTextCorrection(int code) {
  return OMCodes[code] ?? 'Clear Sky';
}

String oMBackdropCorrection(String text) {
  return textBackground[text] ?? 'very_clear.jpg';
}

Color oMBackColorCorrection(String text) {
  return textBackColor[text] ?? BLACK;
}

Color oMAccentColorCorrection(String text) {
  return accentColors[text] ?? WHITE;
}

List<Color> oMContentColorCorrection(String text) {
  return textFontColor[text] ?? [WHITE, WHITE];
}

String oMIconCorrection(String text) {
  return textIconMap[text] ?? 'sun.png';
}


class OMCurrent {
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

  const OMCurrent({
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

  static OMCurrent fromJson(item, settings) => OMCurrent(
    text: translation(oMTextCorrection(item["current"]["weather_code"]), settings[0]),
    uv: item["daily"]["uv_index_max"][0],
    accentcolor: oMAccentColorCorrection(
      oMTextCorrection(item["current"]["weather_code"]),
    ),
    backcolor: oMBackColorCorrection(
      oMTextCorrection(item["current"]["weather_code"]),
    ),
    backdrop: oMBackdropCorrection(
      oMTextCorrection(item["current"]["weather_code"]),
    ),
    contentColor: oMContentColorCorrection(
      oMTextCorrection(item["current"]["weather_code"]),
    ),
    precip: unit_coversion(item["current"]["precipitation"], settings[2]),
    wind: unit_coversion(item["current"]["precipitation"], settings[3]).round(),
    humidity: item["current"]["relative_humidity_2m"],
    temp: unit_coversion(item["current"]["temperature_2m"], settings[1]).round(),
  );
}

