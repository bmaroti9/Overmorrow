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

import 'package:flutter/material.dart';
import 'package:overmorrow/ui_helper.dart';

Widget settingEntry(String title, String desc, Color highlight, Color primary, Color onSurface,
    IconData icon, settings) {
  return Padding(
    padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: highlight,
      ),
      padding: EdgeInsets.all(23),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Icon(icon, color: primary, size: 24,),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              comfortatext(title, 21, settings, color: onSurface),
              comfortatext(desc, 16, settings, color: onSurface)
            ],
          )
        ],
      )
    ),
  );
}

Widget NewSettings(Map<String, String> settings, Function updatePage, Image image, List<Color> colors,
    allColors) {

  Color containerLow = colors[6];
  Color onSurface = colors[4];
  Color primary = colors[1];
  Color primaryLight = colors[2];
  Color surface = colors[0];

  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 20),
    child: Column(
      children: [
        settingEntry("Appearance", "color theme, image source", containerLow, primary, onSurface,
            Icons.palette_outlined, settings),
        settingEntry("General", "time mode, font size", containerLow, primary, onSurface,
            Icons.settings_applications, settings),
        settingEntry("Language", "the language used", containerLow, primary, onSurface,
            Icons.language, settings),
        settingEntry("Units", "the units used in the app", containerLow, primary, onSurface,
            Icons.pie_chart_outline, settings),
        settingEntry("Layout", "widget order, customization", containerLow, primary, onSurface,
            Icons.grid_view, settings),
      ],
    ),
  );
}