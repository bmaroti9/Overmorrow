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
import 'package:overmorrow/hourly.dart';
import 'l10n/app_localizations.dart';
import 'ui_helper.dart';



Widget dayStat(data, IconData icon, number, addon, {addWind = false, windDir = 0, iconSize = 16.0}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon,
          color: data.current.palette.primary, size: iconSize),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: comfortatext(number.toString(), 17, data.settings,
                color: data.current.palette.onSecondaryContainer),
          ),
          comfortatext(addon, 15, data.settings, color: data.current.palette.onSecondaryContainer)
        ],
      ),
      if (addWind) Padding(
          padding: const EdgeInsets.only(left: 5, right: 3),
          child: RotationTransition(
              turns: AlwaysStoppedAnimation(windDir / 360),
              child: Icon(Icons.arrow_circle_right_outlined,
                  color: data.current.palette.primary, size: 18)
          )
      ),
    ],
  );
}

class buildDays extends StatefulWidget {
  final data;

  buildDays({Key? key, required this.data}) : super(key: key);

  @override
  _buildDaysState createState() => _buildDaysState(data);
}

class _buildDaysState extends State<buildDays> with AutomaticKeepAliveClientMixin {
  final data;

  int daysToShow = 0;
  bool isDaysListExpanded = false;
  bool isDaysExpandable = false;

  late List<bool> expand = [];

  @override
  void initState() {
    super.initState();
    if (data.days.length > 7) {
      isDaysExpandable = true;
      daysToShow = 7;
    }
    else {
      daysToShow = data.days.length;
    }
    for (int i = 0; i < data.days.length; i++) {
      expand.add(false);
    }
  }

  void _onExpandTapped(int index) {
    setState(() {
      HapticFeedback.lightImpact();
      expand[index] = !expand[index];
    });
  }

  void toggleMoreDays() {
    setState(() {
      isDaysListExpanded = !isDaysListExpanded;
      if (isDaysListExpanded) {
        daysToShow = data.days.length;
      }
      else {
        daysToShow = 7;
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  _buildDaysState(this.data);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 25, top: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 1, bottom: 14),
            child: comfortatext(AppLocalizations.of(context)!.dailyLowercase, 17,
                data.settings,
                color: data.current.palette.onSurface),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ListView.builder(
              key: ValueKey(daysToShow),
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysToShow,
              itemBuilder: (context, index) {
                final day = data.days[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius:
                          index == 0 ? const BorderRadius.vertical(
                              top: Radius.circular(33),
                              bottom: Radius.circular(6))
                              : index == daysToShow - 1 ? const BorderRadius
                              .vertical(bottom: Radius.circular(6),
                              top: Radius.circular(6))
                              : BorderRadius.circular(6),
                          color: data.current.palette.surfaceContainer),
                      child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: expand[index] ? dailyExpanded(day, data, data.current.palette, _onExpandTapped, index)
                              : dailyCollapsed(data, day, data.current.palette, index, daysToShow, _onExpandTapped)
                      )
                  ),
                );
              }
            ),
          ),
          if (isDaysExpandable) GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              toggleMoreDays();
            },
            child: Container(
              decoration: BoxDecoration(
                color: data.current.palette.secondaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(33))
              ),
              padding: const EdgeInsets.only(left: 22, right: 22, top: 13, bottom: 13),
              margin: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  comfortatext(
                      isDaysListExpanded ? AppLocalizations.of(context)!.showLess : AppLocalizations.of(context)!.showMore
                      , 16, data.settings, color: data.current.palette.onSecondaryContainer),
                  const SizedBox(width: 4,),
                  Icon(
                    isDaysListExpanded ? Icons.arrow_upward : Icons.arrow_downward,
                    color: data.current.palette.onSecondaryContainer, size: 16,)
                ]
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget dailyCollapsed(var data, var day, ColorScheme palette, int index, int daysToShow, onExpandTapped) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      onExpandTapped(index);
    },
    child: Padding(
      padding: EdgeInsets.only(left: 21, right: 20,
        top: index == 0 ? 22 : 21, //evens out the top and bottom sizes with bigger border radii
        bottom: index == (daysToShow - 1) ? 22 : 21
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                comfortatext(day.name.split(", ")[0], 19,
                    data.settings,
                    color: palette.secondary),
                comfortatext(day.name.split(", ")[1], 13,
                    data.settings,
                    color: palette.outline),
              ],
            ),
          ),
          Icon(day.icon, size: 37, color: palette.onSurface,),
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: comfortatext("${day.minTemp.toString()}°", 18, data.settings, color: palette.primary, weight: FontWeight.w500)
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 14, right: 14),
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: palette.surfaceContainerHighest
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;

                  final lowest = data.dailyMinMaxTemp[0];
                  final highest = data.dailyMinMaxTemp[1];
                  const double smallest = 18;
                  final double minPercent = min(max((day.rawMinTemp - lowest) / (highest - lowest), 0), 1);
                  final double maxPercent = min(max((day.rawMaxTemp - lowest) / (highest - lowest), 0), 1);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(left: min(width * minPercent, width - smallest)),
                      width: max(smallest, (maxPercent - minPercent) * width),
                      height: 16,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: palette.secondaryFixedDim
                      ),
                    ),
                  );
                }
              ),
            )
          ),
          comfortatext("${day.maxTemp.toString()}°", 18, data.settings, color: palette.primary, weight: FontWeight.w500),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.expand_more, size: 22, color: palette.secondary,),
          )
        ],
      ),
    ),
  );
}


Widget dailyExpanded(var day, data, ColorScheme palette, onExpandTapped, index) {

  return Padding(
    padding: const EdgeInsets.only(left: 13, right: 13, top: 0, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            onExpandTapped(index);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 23, bottom: 23),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(width: 8,),
                comfortatext("${day.name.split(", ")[0]}, ", 19, data.settings, color: palette.secondary),
                comfortatext(day.name.split(", ")[1], 14, data.settings, color: palette.outline),
                const Spacer(),
                Icon(Icons.expand_less, size: 22, color: palette.secondary,),
                const SizedBox(width: 9,),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 6, right: 10),
          child: Row(
            children: [
              Icon(day.icon, size: 38, color: palette.onSurface,),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: comfortatext(day.text, 22, data.settings, color: palette.primary),
              ),
              const Spacer(),
              Icon(Icons.keyboard_double_arrow_down, size: 16, color: palette.outline,),
              comfortatext("${day.minTemp.toString()}°", 19, data.settings, color: palette.primary),
              const SizedBox(width: 6,),
              Icon(Icons.keyboard_double_arrow_up, size: 16, color: palette.outline,),
              comfortatext("${day.maxTemp.toString()}°", 19, data.settings, color: palette.primary)
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            //color: palette.secondaryContainer,
            border: Border.all(color: palette.outlineVariant, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.only(left: 10, right: 10, top: 25, bottom: 25),
          margin: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              dayStat(data, Icons.umbrella_rounded, day.precip_prob, "%"),
              dayStat(data, Icons.water_drop_outlined, day.total_precip, data.settings["Precipitation"], iconSize: 16.5),
              dayStat(data, Icons.air, day.windspeed, data.settings["Wind"], addWind: true,
                  windDir: day.wind_dir),
              dayStat(data, Icons.wb_sunny_outlined, day.uv, "uv"),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: NewHourly(data: data, hours: day.hourly, addDayDivider: false, elevated: true,),
        )

      ],
    ),
  );
}