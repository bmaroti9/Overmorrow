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


class buildDays extends StatefulWidget {
  final data;

  buildDays({Key? key, required this.data}) : super(key: key);

  @override
  _buildDaysState createState() => _buildDaysState(data);
}

class _buildDaysState extends State<buildDays> with AutomaticKeepAliveClientMixin {
  final data;

  late List<bool> expand = [];

  @override
  void initState() {
    super.initState();
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

  @override
  bool get wantKeepAlive => true;

  _buildDaysState(this.data);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 1, bottom: 14),
            child: comfortatext("daily", 17,
                data.settings,
                color: data.current.palette.onSurface),
          ),
          ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.days.length,
              itemBuilder: (context, index) {
                final day = data.days[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius:
                          index == 0 ? const BorderRadius.vertical(
                              top: Radius.circular(33),
                              bottom: Radius.circular(10))
                              : index == data.days.length - 1 ? const BorderRadius
                              .vertical(bottom: Radius.circular(33),
                              top: Radius.circular(10))
                              : BorderRadius.circular(10),
                          color: data.current.palette.surfaceContainer),
                      child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: expand[index] ? dailyExpanded()
                              : dailyCollapsed(data, day, data.current.palette)
                      )
                  ),
                );
              }
          ),
        ],
      ),
    );
  }
}

Widget dailyCollapsed(var data, var day, ColorScheme palette) {
  return Padding(
    padding: const EdgeInsets.only(left: 22, right: 22, top: 22, bottom: 22),
    child: Row(
      children: [
        SizedBox(
          width: 45,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              comfortatext(day.name.split(", ")[0], 18,
                  data.settings,
                  color: palette.secondary),
              comfortatext(day.name.split(", ")[1], 14,
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
            child: comfortatext("${day.minTemp.toString()}°", 18, data.settings, color: palette.primary)
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 12, right: 12),
            height: 18,
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
                    height: 18,
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
        comfortatext("${day.maxTemp.toString()}°", 18, data.settings, color: palette.primary),
      ],
    ),
  );
}


Widget dailyExpanded() {
  return Container();
}