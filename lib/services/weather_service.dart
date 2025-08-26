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

import '../weather_refact.dart' as weather_refactor;

String convertTime(DateTime time, BuildContext context) {
  if (context.select((SettingsProvider p) => p.getTimeMode) == "12 hour") {
    return DateFormat('h:mm a').format(time).toLowerCase();
  }
  return DateFormat('hh:mm').format(time);
}

String convertToShortTime(DateTime time, BuildContext context) {
  if (context.select((SettingsProvider p) => p.getTimeMode) == "12 hour") {
    return DateFormat('ha').format(time).toLowerCase();
  }
  return DateFormat('hh').format(time);
}

String getDateStringFromLocalTime(DateTime now) {
  final List<String> weekNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final List<String> monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  return "${weekNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}";
}

num unitConversion(double value, String unit, {decimals = 2}) {
  List<double> p = weather_refactor.conversionTable[unit] ?? [0, 0];
  double a = p[0] + value * p[1];
  if (decimals == 0) {
    return a.round();
  }
  return double.parse(a.toStringAsFixed(decimals));
}

String getDayName(settings, DateTime time, localizations) {
  List<String> weeks = [
    localizations.mon,
    localizations.tue,
    localizations.wed,
    localizations.thu,
    localizations.fri,
    localizations.sat,
    localizations.sun
  ];
  String weekname = weeks[time.weekday - 1];
  final String date = settings["Date format"] == "mm/dd" ? "${time.month}/${time.day}"
      :"${time.day}/${time.month}";
  return "$weekname, $date";
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
