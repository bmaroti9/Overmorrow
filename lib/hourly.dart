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
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'l10n/app_localizations.dart';
import 'ui_helper.dart';
import 'package:provider/provider.dart';

class NewHourly extends StatefulWidget {
  final data;
  final hours;
  final elevated;

  NewHourly({Key? key, required this.data, required this.hours, required this.elevated}) : super(key: key);

  @override
  _NewHourlyState createState() => _NewHourlyState();
}

class _NewHourlyState extends State<NewHourly> with AutomaticKeepAliveClientMixin {

  int _value = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: widget.elevated ? const EdgeInsets.all(0)
          : const EdgeInsets.only(left: 21, right: 21, top: 0, bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            height: 195,
            child: hourBoxes(widget.hours, widget.data, _value, widget.elevated, context),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 0, left: 5),
            child: Wrap(
              spacing: 5.0,
              children: List<Widget>.generate(4, (int index) {
                  return ChoiceChip(
                    elevation: 0.0,
                    side: BorderSide(
                        color: index == _value ? Theme.of(context).colorScheme.secondaryContainer
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: 1.6),
                    label: Text(
                      [
                      AppLocalizations.of(context)!.sumLowercase,
                      AppLocalizations.of(context)!.precipLowercase,
                      AppLocalizations.of(context)!.windLowercase,
                      AppLocalizations.of(context)!.uvLowercase,
                      ][index],
                    ),
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

Widget hourBoxes(hours, data, _value, elevated, context) {

  return AnimationLimiter(
    child: ListView.builder(
      itemCount: hours.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        var hour = hours[index];
        if (hour is DateTime) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              horizontalOffset: 100.0,
              child: FadeInAnimation(
                child: dividerWidget(hour.day.toString(), data, context)
              ),
            ),
          );
        }

        List<Widget> childWidgets = [
          HourlySum(hour: hour, data: data,),
          HourlyPrecip(hour: hour, data: data),
          HourlyWind(hour: hour, data : data),
          HourlyUv(hour: hour, data : data),
        ];
    
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            horizontalOffset: 100.0,
            child: FadeInAnimation(
              child: hourlyDataBuilder(hour, elevated, childWidgets[_value], data, context)
            ),
          ),
        );
      },
    ),
  );
}

Widget hourlyDataBuilder(hour, elevated, childWidget, data, context) {
  return Padding(
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
                color: elevated ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: child,
            ),
          ),
        );
      },
      child: childWidget,
    ),
  );
}

Widget dividerWidget(String name, data, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3, left: 6, right: 6),
    child: RotatedBox(
      quarterTurns: -1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 10),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 17,
            ),
          )
        )
      )
    ),
  );
}

class HourlySum extends StatelessWidget {
  final hour;
  final WeatherData data;

  const HourlySum({super.key, required this.hour, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("sum"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              "${unitConversion(hour.temp, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600
              ),
            )
        ),

        Icon(
          hour.icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 37.0,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 1.5),
              child: Icon(Icons.umbrella, size: 14, color: Theme.of(context).colorScheme.tertiary),
            ),
            Text("${hour.precip_prob}%",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 13, fontWeight: FontWeight.w600),)
          ],
        ),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),),
      ],
    );
  }
}


class HourlyPrecip extends StatelessWidget {
  final hour;
  final WeatherData data;

  const HourlyPrecip({super.key, required this.hour, required this.data});

  @override
  Widget build(BuildContext context) {
    String precipUnit = context.select((SettingsProvider p) => p.getPrecipUnit);
    return Column(
      key: const ValueKey("precip"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${unitConversion(hour.precip, precipUnit)}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18),),
            Text(precipUnit,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9),),
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
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.umbrella, size: 14, color: Theme.of(context).colorScheme.primary),
            Text("${hour.precip_prob}%", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),)
          ],
        ),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),),
      ],
    );
  }
}


class HourlyWind extends StatelessWidget {
  final hour;
  final WeatherData data;

  const HourlyWind({super.key, required this.hour, required this.data});

  @override
  Widget build(BuildContext context) {

    String windUnit = context.select((SettingsProvider p) => p.getPrecipUnit);

    return Column(
      key: const ValueKey("wind"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${unitConversion(hour.wind, windUnit)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18),),
            Text(windUnit, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9),)
          ],
        ),

        Transform.rotate(
            angle: (hour.wind_dir + 180) * pi / 180,
            child: Icon(Icons.navigation_outlined, color: Theme.of(context).colorScheme.onSurface, size: 18,)
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.trending_up, size: 13, color: Theme.of(context).colorScheme.primary),
            Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text("${unitConversion(hour.wind_gusts, windUnit)}", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),)
            ),
            Text(windUnit, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9),)
          ],
        ),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),),
      ],
    );
  }
}


class HourlyUv extends StatelessWidget {
  final hour;
  final WeatherData data;

  const HourlyUv({super.key, required this.hour, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("uv"),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${hour.uv}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 19),),
            Text('UV', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9),)
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
                        color: Theme.of(context).colorScheme.outlineVariant,
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
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  );
                }
              }
          ),
        ),

        Text(convertToShortTime(hour.time, context),
          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),),
      ],
    );
  }
}
