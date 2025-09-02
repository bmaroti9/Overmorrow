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
import 'package:flutter_svg/svg.dart';
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/hourly.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';


Widget dayStat(IconData icon, number, addon, context, {addWind = false, windDir = 0, iconSize = 16.0}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: iconSize),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(number.toString(), style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 17),),
          ),
          Text(addon, style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 15),),
        ],
      ),
      if (addWind) Padding(
          padding: const EdgeInsets.only(left: 5, right: 3),
          child: RotationTransition(
              turns: AlwaysStoppedAnimation(windDir / 360),
              child: Icon(Icons.arrow_circle_right_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 18)
          )
      ),
    ],
  );
}

class BuildDays extends StatefulWidget {
  final WeatherData data;

  BuildDays({Key? key, required this.data}) : super(key: key);

  @override
  _BuildDaysState createState() => _BuildDaysState();
}

class _BuildDaysState extends State<BuildDays> with AutomaticKeepAliveClientMixin {

  static const int maxToShow = 7;

  bool isExpanded = false;
  int dayCap = maxToShow;

  late List<bool> expand = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) { //there will never be more days than 20
      expand.add(false);
    }
  }

  void _onExpandTapped(int index) {
    setState(() {
      HapticFeedback.lightImpact();
      expand[index] = !expand[index];
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    int daysToShow = min(dayCap, widget.data.days.length);
    bool showButton = maxToShow < widget.data.days.length;

    return Padding(
      padding: const EdgeInsets.only(left: 23, right: 23, bottom: 25, top: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 1, bottom: 14),
            child: Text(AppLocalizations.of(context)!.dailyLowercase, style: const TextStyle(fontSize: 17),)
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
                final day = widget.data.days[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: index == 0 ? const Radius.circular(33) : const Radius.circular(6),
                            bottom: index == daysToShow - 1  && !showButton
                                ? const Radius.circular(33) : const Radius.circular(6),
                        ),
                        color: Theme.of(context).colorScheme.surfaceContainer
                      ),
                      child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: expand[index] ? DailyExpanded(day: day, onExpandTapped:  _onExpandTapped, index: index)
                            : DailyCollapsed(data: widget.data, day: day, index: index, onExpandTapped:  _onExpandTapped)
                      )
                  ),
                );
              }
            ),
          ),
          if (showButton) GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (isExpanded) {
                setState(() {
                  dayCap = 7;
                  isExpanded = false;
                });
              }
              else {
                setState(() {
                  dayCap = 20;
                  isExpanded = true;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(33))
              ),
              padding: const EdgeInsets.only(left: 22, right: 22, top: 11, bottom: 11),
              margin: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? AppLocalizations.of(context)!.showLess : AppLocalizations.of(context)!.showMore,
                    style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 16),
                  ),
                  const SizedBox(width: 4,),
                  Icon(
                    isExpanded ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.onTertiaryContainer, size: 16,)
                ]
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DailyCollapsed extends StatelessWidget {
  final Function onExpandTapped;
  final int index;
  final WeatherDay day;
  final WeatherData data;

  const DailyCollapsed({super.key, required this.onExpandTapped,
    required this.index, required this.day, required this.data});


  @override
  Widget build(BuildContext context) {
    String dayName = getDayName(day.date, context, context.select((SettingsProvider p) => p.getDateFormat));
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onExpandTapped(index);
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 23, right: 23, top: 15, bottom: 15),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayName.split(', ')[0], style: const TextStyle(fontSize: 18, height: 1.15),),
                  Text(dayName.split(', ')[1], style: TextStyle(fontSize: 12,
                      color: Theme.of(context).colorScheme.outline, height: 1.15, fontWeight: FontWeight.w600),),
                ],
              ),
            ),

            Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  "assets/m3shapes/4_sided_cookie.svg",
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondaryContainer, BlendMode.srcIn),
                  width: 54,
                  height: 54,
                ),
                SvgPicture.asset(
                  weatherIconPathMap[day.condition] ?? "assets/weather_icons/clear_sky.svg",
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                  width: 35,
                  height: 35,
                )
              ],
            ),

            SizedBox(
              width: 40,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${unitConversion(day.minTempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
              ),
            ),
            Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 14, right: 14),
                  height: 16,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest
                  ),
                  child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double width = constraints.maxWidth;

                        final lowest = data.dailyMinMaxTemp[0];
                        final highest = data.dailyMinMaxTemp[1];
                        const double smallest = 18;
                        final double minPercent = min(max((day.minTempC - lowest) / (highest - lowest), 0), 1);
                        final double maxPercent = min(max((day.maxTempC - lowest) / (highest - lowest), 0), 1);
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(left: min(width * minPercent, width - smallest)),
                            width: max(smallest, (maxPercent - minPercent) * width),
                            height: 16,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Theme.of(context).colorScheme.secondaryFixedDim
                            ),
                          ),
                        );
                      }
                  ),
                )
            ),
            Text(
              "${unitConversion(day.maxTempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12,),
            Icon(Icons.expand_more, size: 23, color: Theme.of(context).colorScheme.onSurface,)
          ],
        ),
      ),
    );
  }
}


class DailyExpanded extends StatelessWidget {
  final Function onExpandTapped;
  final int index;
  final WeatherDay day;

  const DailyExpanded({super.key, required this.onExpandTapped,
    required this.index, required this.day});

  @override
  Widget build(BuildContext context) {
    String dayName = getDayName(day.date, context, context.select((SettingsProvider p) => p.getDateFormat));
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 0, bottom: 16),
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
                  Text(dayName, style: const TextStyle(fontSize: 17),),
                  const Spacer(),
                  Icon(Icons.expand_less, size: 23, color: Theme.of(context).colorScheme.onSurface,),
                  const SizedBox(width: 9,),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 6, right: 10),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/m3shapes/4_sided_cookie.svg",
                      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondaryContainer, BlendMode.srcIn),
                      width: 60,
                      height: 60,
                    ),
                    SvgPicture.asset(
                      weatherIconPathMap[day.condition] ?? "assets/weather_icons/clear_sky.svg",
                      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                      width: 38,
                      height: 38,
                    )
                  ],
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      conditionTranslation(day.condition, AppLocalizations.of(context)!) ?? "Translation Err",
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 22),
                    )
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(9),
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_double_arrow_down, size: 16, color: Theme.of(context).colorScheme.onTertiaryContainer,),
                      Text(
                        "${unitConversion(day.minTempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                        style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 17),
                      ),
                      const SizedBox(width: 6,),
                      Icon(Icons.keyboard_double_arrow_up, size: 16, color: Theme.of(context).colorScheme.onTertiaryContainer,),
                      Text(
                        "${unitConversion(day.maxTempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                        style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 17),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              //color: Theme.of(context).colorScheme.tertiaryContainer,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
            margin: const EdgeInsets.all(2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                dayStat(
                  Icons.umbrella_rounded,
                  day.precipProb, "%",
                  context
                ),
                dayStat(
                  Icons.water_drop_outlined,
                  unitConversion(day.totalPrecipMm, context.select((SettingsProvider p) => p.getPrecipUnit), decimals: 1),
                  context.select((SettingsProvider p) => p.getPrecipUnit),
                  context,
                  iconSize: 16.5
                ),
                dayStat(
                  Icons.air,
                  unitConversion(day.windKph, context.select((SettingsProvider p) => p.getWindUnit), decimals: 1),
                  context.select((SettingsProvider p) => p.getWindUnit),
                  context,
                  addWind: true,
                  windDir: day.windDirA
                ),
                dayStat(
                  Icons.wb_sunny_outlined,
                  day.uv,
                  "uv",
                  context
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: NewHourly(hours: day.hourly, elevated: true,),
          )

        ],
      ),
    );
  }
}