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


import 'package:intl/intl.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../decoders/weather_data.dart';
import '../l10n/app_localizations.dart';

import '../weather_refact.dart';


List<double> weatherGetMaxMinTempForDaily(List<WeatherDay> days) {
  double minTemp = 100;
  double maxTemp = -100;
  for (int i = 0; i < days.length; i++) {
    if (days[i].minTempC < minTemp) {
      minTemp = days[i].minTempC;
    }
    if (days[i].maxTempC > maxTemp) {
      maxTemp = days[i].maxTempC;
    }
  }
  return [minTemp, maxTemp];
}

String convertTime(DateTime time, BuildContext context) {
  if (context.select((SettingsProvider p) => p.getTimeMode) == "12 hour") {
    return DateFormat('h:mm a').format(time).toLowerCase();
  }
  return DateFormat('HH:mm').format(time);
}

String convertToShortTime(DateTime time, BuildContext context) {
  if (context.select((SettingsProvider p) => p.getTimeMode) == "12 hour") {
    return DateFormat('ha').format(time).toLowerCase();
  }
  return DateFormat('H:mm').format(time);
}

String translateCondition(String condition, localizations) {
  return conditionTranslation(condition, localizations) ?? "translateErr";
}

String getDateStringFromLocalTime(DateTime now) {
  final List<String> weekNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final List<String> monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  return "${weekNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}";
}

String getDayName(DateTime day, BuildContext context, String dateFormat) {
  List<String> weeks = [
    AppLocalizations.of(context)!.mon,
    AppLocalizations.of(context)!.tue,
    AppLocalizations.of(context)!.wed,
    AppLocalizations.of(context)!.thu,
    AppLocalizations.of(context)!.fri,
    AppLocalizations.of(context)!.sat,
    AppLocalizations.of(context)!.sun
  ];
  String weekName = weeks[day.weekday - 1];
  final String format = dateFormat == "mm/dd" ? "M/dd" : "dd/MM";
  final String date = DateFormat(format).format(day);
  return "$weekName, $date";
}

num unitConversion(double value, String unit, {decimals = 2}) {
  List<double> p = conversionTable[unit] ?? [0, 0];
  double a = p[0] + value * p[1];
  if (decimals == 0) {
    return a.round();
  }
  return double.parse(a.toStringAsFixed(decimals));
}

String aqiDescLocalization(index, localizations) {
  return [
    localizations.goodAqiDesc,
    localizations.fairAqiDesc,
    localizations.moderateAqiDesc,
    localizations.poorAqiDesc,
    localizations.veryPoorAqiDesc,
    localizations.unhealthyAqiDesc,
  ][index];
}

String aqiTitleLocalization(index, localizations) {
  return [
    localizations.good,
    localizations.fair,
    localizations.moderate,
    localizations.poor,
    localizations.veryPoor,
    localizations.unhealthy,
  ][index];
}

String aerosolOpticalDepthLocalizations(index, localizations) {
  return [
    localizations.good,
    localizations.fair,
    localizations.moderate,
    localizations.poor,
    localizations.veryPoor,
    localizations.unhealthy,
  ][index - 1];
}
