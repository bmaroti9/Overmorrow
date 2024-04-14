/*
Copyright (C) <2024>  <Balint Maroti>

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

import 'dart:math';
import 'dart:ui';

import 'package:overmorrow/decoders/decode_wapi.dart';

import '../settings_page.dart';
import '../ui_helper.dart';

import '../weather_refact.dart';

String metNTextCorrection(String text, {language = 'English'}) {
  String p = metNWeatherToText[text] ?? 'Clear Sky';
  String t = translation(p, language);
  return t;
}

String metNBackdropCorrection(String text) {
  return textBackground[text] ?? 'very_clear_a.jpg';
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

String metNIconCorrection(String text) {
  return textIconMap[text] ?? 'sun.png';
}

String metNTimeCorrect(String date) {
  final realtime = date.split('T')[1];
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
    text: metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"], language: settings["Language"]),

    precip: unit_coversion(item["timeseries"][0]["data"]["next_1_hours"]["details"]["precipitation_amount"], settings["Precipitation"]),
    temp: unit_coversion(item["timeseries"][0]["data"]["instant"]["details"]["air_temperature"], settings["Temperature"]).round(),
    humidity: item["timeseries"][0]["data"]["instant"]["details"]["relative_humidity"],
    wind: unit_coversion(item["timeseries"][0]["data"]["instant"]["details"]["wind_speed"] * 3.6, settings["Wind"]).round(),
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
  final String text;
  final String icon;
  final String name;
  final String minmaxtemp;
  final List<MetNHour> hourly;
  final List<MetNHour> hourly_for_precip;

  final int precip_prob;
  final double total_precip;
  final int windspeed;
  final int avg_temp;
  final double mm_precip;

  const MetNDay({
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

  static Build(item, settings, index) {

    //finds the beggining of the day in question
    int days_found = 0;
    int index = 0;
    while (days_found < index) {
      String date = item[index]["time"];
      final realtime = date.split('T')[1];
      final realhour = realtime.split(':')[0];
      final num = int.parse(realhour);
      if (num == 0) {
        days_found += 1;
      }
      index += 1;
    }

    int begin = index.toInt();
    int end = 0;

    while (end == 0) {
      String date = item[index]["time"];
      final realtime = date.split('T')[1];
      final realhour = realtime.split(':')[0];
      final num = int.parse(realhour);
      if (num == 0) {
        end = index.toInt();
      }
      index += 1;
    }

    print(("hihihihihih", begin, end));

    //now we know the timestamps for the beginning and the end of the day
    
    List<int> temperatures = [];
    List<int> windspeeds = [];
    List<double> precip_mm = [];

    int precipProb = 0;

    List<int> oneSummary = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    const weather_names = ['Clear Night', 'Partly Cloudy', 'Clear Sky', 'Overcast',
      'Haze', 'Rain', 'Sleet', 'Drizzle', 'Thunderstorm', 'Heavy Snow', 'Fog', 'Snow',
      'Heavy Rain', 'Cloudy Night'];
    
    List<MetNHour> hours = [];
    
    for (int n = begin; n < end; n++) {
      MetNHour hour = MetNHour.fromJson(item[n], settings);
      temperatures.add(hour.temp);
      windspeeds.add(hour.wind);
      precip_mm.add(hour.precip);

      int index = weather_names.indexOf(hour.text);
      int value = weatherConditionBiassTable[hour.text] ?? 0;
      oneSummary[index] += value;

      if (hour.precip_prob > precipProb) {
        precipProb = hour.precip_prob.toInt();
      }
      hours.add(hour);
    }

    int largest_value = oneSummary.reduce(max);
    int BIndex = oneSummary.indexOf(largest_value);

    return MetNDay(
      mm_precip: precip_mm.reduce((a, b) => a + b),
      precip_prob: precipProb,
      avg_temp: (precip_mm.reduce((a, b) => a + b) / temperatures.length).round(),
      minmaxtemp: "${temperatures.reduce(max)}˚/${temperatures.reduce(min)}°",
      hourly: hours,
      hourly_for_precip: hours,
      total_precip: unit_coversion(precip_mm.reduce((a, b) => a + b), settings["Precipitation"]),
      windspeed: (windspeeds.reduce((a, b) => a + b) / windspeeds.length).round(),
      name: getName(index, settings),
      text: metNTextCorrection(weather_names[BIndex]),
      icon: metNIconCorrection(weather_names[BIndex]),
    );
  }
}

class MetNHour {
  final int temp;
  final String icon;
  final String time;
  final String text;
  final double precip;
  final int wind;
  final int precip_prob;

  const MetNHour(
      {
        required this.temp,
        required this.time,
        required this.icon,
        required this.text,
        required this.precip,
        required this.wind,
        required this.precip_prob,
      });

  static MetNHour fromJson(item, settings) => MetNHour(
    text: metNTextCorrection(item["data"]["next_1_hours"]["summary"]["symbol_code"], language: settings["Language"]),
    temp: unit_coversion(item["data"]["instant"]["details"]["air_temperature"], settings["Temperature"]).round(),
    precip: item["data"]["next_1_hours"]["details"]["precipitation_amount"],
    precip_prob : item["data"]["next_1_hours"]["details"]["probability_of_precipitation"].round(),
    icon: metNIconCorrection(
      metNTextCorrection(item["timeseries"][0]["data"]["next_1_hours"]["summary"]["symbol_code"]),
    ),
    time: metNTimeCorrect(item["time"]),
    wind: unit_coversion(item["data"]["instant"]["details"]["wind_speed"] * 3.6, settings["Wind"]).round(),
  );
}