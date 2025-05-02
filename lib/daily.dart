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
            padding: const EdgeInsets.only(left: 1, top: 0, bottom: 6),
            child: comfortatext("daily", 16, data.settings, color: data.current.palette.onSurface),
          ),
          ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 5, bottom: 5),
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
                              top: Radius.circular(20),
                              bottom: Radius.circular(8))
                              : index == data.days.length - 1 ? const BorderRadius
                              .vertical(bottom: Radius.circular(20),
                              top: Radius.circular(8))
                              : BorderRadius.circular(8),
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
    padding: const EdgeInsets.all(20.0),
    child: Row(
      children: [
        SizedBox(
          width: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              comfortatext(day.name.split(", ")[0], 18,
                  data.settings,
                  color: palette.primary),
              comfortatext(day.name.split(", ")[1], 14,
                  data.settings,
                  color: palette.outline),
            ],
          ),
        ),
        Icon(day.icon, size: 37, color: palette.onSurface,),
        Expanded(
          child: Container(
            margin: EdgeInsets.all(13),
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: palette.surfaceContainerHighest
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: palette.secondary
                ),
              ),
            ),
          )
        )
      ],
    ),
  );
}


Widget dailyExpanded() {
  return Container();
}