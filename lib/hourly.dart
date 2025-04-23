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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui_helper.dart';

class NewHourly extends StatefulWidget {
  final data;

  NewHourly({Key? key, required this.data}) : super(key: key);

  @override
  _NewHourlyState createState() => _NewHourlyState(data);
}

class _NewHourlyState extends State<NewHourly> with AutomaticKeepAliveClientMixin {
  final data;
  int _value = 0;

  @override
  bool get wantKeepAlive => true;

  _NewHourlyState(this.data);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ColorScheme palette = data.current.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 19, right: 19, top: 0, bottom: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 196,
            child: hourBoxes(data.days[1].hourly, data, _value),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 0, left: 5),
            child: Wrap(
              spacing: 5.0,
              children: List<Widget>.generate(
                4,
                    (int index) {

                  return ChoiceChip(
                    elevation: 0.0,
                    checkmarkColor: palette.onSecondaryContainer,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (index == _value) {
                        return palette.secondaryContainer;
                      }
                      return palette.surface;
                    }),
                    side: BorderSide(
                        color: index == _value ? palette.secondaryContainer : palette.outlineVariant,
                        width: 1.6),
                    //translation(['temp', 'precip', 'wind', 'uv'][index], data.settings["Language"])
                    label: comfortatext(
                        [
                          "sum",
                          "precip",
                          "wind",
                          "uv",
                        ][index],
                        14, data.settings,
                        color: _value == index ? palette.onSecondaryContainer : palette.onSurface),
                    selected: _value == index,
                    onSelected: (bool selected) {
                      setState(() {
                        _value = index;
                        HapticFeedback.lightImpact();
                      });
                    },
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget hourBoxes(hours, data, _value) {
  ColorScheme palette = data.current.palette;

  return ListView.builder(
    itemCount: hours.length,
    scrollDirection: Axis.horizontal,
    itemBuilder: (BuildContext context, int index) {
      var hour = hours[index];
      List<Widget> childWidgets = [
        buildHourlySum(hour, palette, data),
        buildHourlyPrecip(hour, palette, data),
        buildHourlyWind(hour, palette, data),
        buildHourlyUv(hour, palette, data),
      ];
      return Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.only(top: 6, bottom: 5),
        width: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: palette.surfaceContainer,
        ),

        child: childWidgets[_value],

      );
    },
  );
}

Widget buildHourlySum(var hour, ColorScheme palette, data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2),
        child: comfortatext("${hour.temp}°", 19, data.settings, color: palette.primary,
            weight: FontWeight.w400),
      ),

      SizedBox(
        height: 30,
        child: Icon(
          hour.icon,
          color: palette.onSurface,
          size: 29.0 * hour.iconSize,
        ),
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.umbrella, size: 14, color: palette.primary),
          comfortatext("${hour.precip_prob}%", 14, data.settings, color: palette.primary,
              weight: FontWeight.w400)
        ],
      ),

      comfortatext(hour.time, 14, data.settings, color: palette.outline, weight: FontWeight.w400)
    ],
  );
}


Widget buildHourlyPrecip(var hour, ColorScheme palette, data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      comfortatext('${hour.precip}', 18, data.settings, color: palette.primary,
          weight: FontWeight.w500),
      comfortatext('${data.settings["Precipitation"]}', 9, data.settings, color: palette.primary),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.umbrella, size: 14, color: palette.primary),
          comfortatext("${hour.precip_prob}%", 14, data.settings, color: palette.primary,
              weight: FontWeight.w400)
        ],
      ),

      SizedBox(
        height: 30,
        child: Icon(
          hour.icon,
          color: palette.onSurface,
          size: 29.0 * hour.iconSize,
        ),
      ),

      comfortatext(hour.time, 14, data.settings, color: palette.outline, weight: FontWeight.w400)
    ],
  );
}


Widget buildHourlyWind(var hour, ColorScheme palette, data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [

      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          comfortatext('${hour.wind}', 18, data.settings, color: palette.primary,
              weight: FontWeight.w400),
          comfortatext('${data.settings["Wind"]}', 9, data.settings, color: palette.primary,
              weight: FontWeight.w500),
        ],
      ),

      Transform.rotate(
          angle: hour.wind_dir * pi / 180,
          child: Icon(Icons.navigation_outlined, color: palette.onSurface, size: 18,)
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.air, size: 13, color: palette.primary),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: comfortatext("${hour.precip_prob}", 14, data.settings, color: palette.primary,
                weight: FontWeight.w400),
          ),
          comfortatext('${data.settings["Wind"]}', 9, data.settings, color: palette.primary,
              weight: FontWeight.w500),
        ],
      ),

      comfortatext(hour.time, 14, data.settings, color: palette.outline, weight: FontWeight.w400)
    ],
  );
}


Widget buildHourlyUv(var hour, ColorScheme palette, data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [

      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          comfortatext('${hour.uv}', 18, data.settings, color: palette.primary,
              weight: FontWeight.w400),
          comfortatext('UV', 9, data.settings, color: palette.primary,
              weight: FontWeight.w500),
        ],
      ),

      Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: hour.uv > 7 ? palette.error
              : hour.uv > 3 ? palette.primary
              : palette.primaryFixedDim,
        ),
      ),

      SizedBox(
        height: 30,
        child: Icon(
          hour.icon,
          color: palette.onSurface,
          size: 29.0 * hour.iconSize,
        ),
      ),

      comfortatext(hour.time, 14, data.settings, color: palette.outline, weight: FontWeight.w400)
    ],
  );
}