import 'dart:ui';

import 'package:hihi_haha/decoders/decode_wapi.dart';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';

String oMGetName(index, settings, item) {
  if (index < 3) {
    const names = ['Today', 'Tomorrow', 'Overmorrow'];
    return translation(names[index], settings[0]);
  }
  String x = item["daily"]["time"][index].split("T")[0];
  List<String> z = x.split("-");
  DateTime time = DateTime(int.parse(z[0]), int.parse(z[1]), int.parse(z[2]));
  const weeks = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  return translation(weeks[time.weekday - 1], settings[0]);
}

String oMamPmTime(String time) {
  List<String> splited = time.split("T");
  List<String> num = splited[1].split(":");
  int hour = int.parse(num[0]);
  if (hour == 0) {
    return "12am";
  }
  if (hour < 12) {
    return "${hour}am";
  }
  if (hour == 12) {
    return "12pm";
  }
  return "${hour - 12}pm";
}

String oM24hour(String time) {
  List<String> splited = time.split("T");
  return splited[1];
}

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
    uv: item["daily"]["uv_index_max"][0].round(),
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


class OMDay {
  final String text;
  final String icon;
  final String name;
  final String minmaxtemp;
  final List<OMHour> hourly;
  final List<OMHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;
  final int windspeed;
  final int avg_temp;
  final double mm_precip;

  const OMDay({
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

  static OMDay build(item, settings, index) {
    return OMDay(
      icon: oMIconCorrection(oMTextCorrection(item["daily"]["weather_code"][index])),
      text: translation(oMTextCorrection(item["daily"]["weather_code"][index]), settings[0]),
      name: oMGetName(index, settings, item),
      windspeed: unit_coversion(item["daily"]["wind_speed_10m_max"][index], settings[3]).round(),
      total_precip: double.parse(unit_coversion(item["daily"]["precipitation_sum"][index], settings[2]).toStringAsFixed(1)),
      minmaxtemp: "${unit_coversion(item["daily"]["temperature_2m_min"][index], settings[1]).round().toString()}°"
          "/${unit_coversion(item["daily"]["temperature_2m_max"][index], settings[1]).round().toString()}°",
      precip_prob: item["daily"]["precipitation_probability_max"][index] ?? 0,
      mm_precip: item["daily"]["precipitation_sum"][index],
      hourly_for_precip: buildHours(index, false, item, settings),
      hourly: buildHours(index, true, item, settings),
      avg_temp: 0,
    );
  }

  static List<OMHour> buildHours(index, get_rid_first, item, settings) {
    int timenow = int.parse(item["current"]["time"].split("T")[1].split(":")[0]);
    List<OMHour> hourly = [];
    if (index == 0 && get_rid_first) {
      for (var i = 0; i < 23; i++) {
        if (index * 24 + i >= timenow) {
          hourly.add(OMHour.fromJson(item, i, settings));
        }
      }
      return hourly;
    }
    else {
      for (var i = 0; i < 24; i++) {
        hourly.add(OMHour.fromJson(item, index * 24 + i, settings));
      }
      return hourly;
    }
  }
}

class OMHour {
  final int temp;
  final String icon;
  final String time;
  final String text;
  final double precip;

  const OMHour({
    required this.temp,
    required this.time,
    required this.icon,
    required this.text,
    required this.precip,
  });

  static OMHour fromJson(item, index, settings) => OMHour(
    temp: unit_coversion(item["hourly"]["temperature_2m"][index], settings[1]).round(),
    text: translation(oMTextCorrection(item["hourly"]["weather_code"][index]), settings[0]),
    icon: oMIconCorrection(oMTextCorrection(item["hourly"]["weather_code"][index])),
    time: settings[6] == '12 hour'? oMamPmTime(item["hourly"]["time"][index]) : oM24hour(item["hourly"]["time"][index]),
    precip: unit_coversion(item["hourly"]["precipitation"][index], settings[2]),
  );
}