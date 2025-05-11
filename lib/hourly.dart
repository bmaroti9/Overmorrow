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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'ui_helper.dart';


class NewHourly extends StatefulWidget {
  final data;
  final hours;
  final addDayDivider;
  final elevated;

  NewHourly({Key? key, required this.data, required this.hours, required this.addDayDivider, required this.elevated}) : super(key: key);

  @override
  _NewHourlyState createState() => _NewHourlyState(data, hours, addDayDivider, elevated);
}

class _NewHourlyState extends State<NewHourly> with AutomaticKeepAliveClientMixin {
  final data;
  final hours;
  final addDayDivider;
  final elevated;

  int _value = 0;

  @override
  bool get wantKeepAlive => true;

  _NewHourlyState(this.data, this.hours, this.addDayDivider, this.elevated);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ColorScheme palette = data.current.palette;
    return Padding(
      padding: elevated ? const EdgeInsets.all(0)
          : const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            height: 196,
            child: hourBoxes(hours, data, _value, addDayDivider, elevated),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 0, left: 5),
            child: Wrap(
              spacing: 5.0,
              children: List<Widget>.generate(4, (int index) {
                  return ChoiceChip(
                    elevation: 0.0,
                    checkmarkColor: palette.onSecondaryContainer,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (index == _value) {
                        return palette.secondaryContainer;
                      }
                      return elevated ? palette.surfaceContainer : palette.surface;
                    }),
                    side: BorderSide(
                        color: index == _value ? palette.secondaryContainer : palette.outlineVariant,
                        width: 1.6),
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

Widget hourBoxes(hours, data, _value, addDayDivider, elevated) {
  ColorScheme palette = data.current.palette;

  return AnimationLimiter(
    child: ListView.builder(
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
    
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            horizontalOffset: 60.0,
            child: FadeInAnimation(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.decelerate,
                      transitionBuilder: (Widget child,
                          Animation<double> animation) {
                        final  offsetAnimation =
                        Tween<Offset>(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0)).animate(animation);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: Container(
                              padding: const EdgeInsets.only(top: 7, bottom: 5),
                              width: 67,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: elevated ? palette.surfaceContainerHighest : palette.surfaceContainer,
                              ),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: childWidgets[_value],
                    ),
                  ),
                  dividerWidget(hour, palette, data, addDayDivider)
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget dividerWidget(hour, ColorScheme palette, data, addDayDivider) {
  if (addDayDivider && hour.time == "11pm" || hour.time == "11:00") {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
      child: RotatedBox(
        quarterTurns: -1,
        child: comfortatext("tomorrow", 18, data.settings, color: palette.secondary, weight: FontWeight.w500)
      ),
    );
  }
  return Container();
}

Widget buildHourlySum(var hour, ColorScheme palette, data) {
  return Column(
    key: const ValueKey("sum"),
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2),
        child: comfortatext("${hour.temp}°", 19, data.settings, color: palette.primary,
            weight: FontWeight.w400),
      ),

      Icon(
        hour.icon,
        color: palette.onSurface,
        size: 37.0,
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
  return Stack(
    children: [
      Column(
        key: const ValueKey("precip"),
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              comfortatext('${hour.precip}', 17, data.settings, color: palette.primary,
                  weight: FontWeight.w400),
              comfortatext('${data.settings["Precipitation"]}', 9, data.settings, color: palette.primary,
                  weight: FontWeight.w500),
            ],
          ),

          SizedBox(
            width: 33,
            height: 33,
            child: Center(
              child: CircularProgressIndicator(
                //this seems to be falsely depreciated, wrapping it in the CircularProgressIndicatorTheme
                //as instructed also trows the same exception
                year2023: false,
                value: hour.precip_prob / 100,
                strokeWidth: 3.5,
                backgroundColor: palette.outlineVariant,
                color: palette.secondary,
              ),
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
      ),
    ],
  );
}


Widget buildHourlyWind(var hour, ColorScheme palette, data) {
  return Column(
    key: const ValueKey("wind"),
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
          angle: (hour.wind_dir + 180) * pi / 180,
          child: Icon(Icons.navigation_outlined, color: palette.onSurface, size: 18,)
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.trending_up, size: 13, color: palette.primary),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: comfortatext("${hour.wind_gusts}", 14, data.settings, color: palette.primary,
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
    key: const ValueKey("uv"),
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

      SizedBox(
        height: 65,
        child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemExtent: 6.5,
            itemBuilder: (BuildContext context, int index) {
              if (index < min(max(10 - hour.uv, 0), 10)) {
                return Center(
                  child: Container(
                    width: 13,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: palette.outlineVariant,
                    ),
                  ),
                );
              }
              else {
                return Center(
                  child: Container(
                    width: 13,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: palette.secondary,
                    ),
                  ),
                );
              }
            }
        ),
      ),
  
      comfortatext(hour.time, 14, data.settings, color: palette.outline, weight: FontWeight.w400)
    ],
  );
}