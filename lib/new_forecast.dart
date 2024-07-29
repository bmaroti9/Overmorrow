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


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/settings_page.dart';
import 'decoders/decode_wapi.dart';
import 'ui_helper.dart';


class NewDay extends StatefulWidget {
  final data;
  final index;

  NewDay({Key? key, required this.data, required this.index}) : super(key: key);

  @override
  _NewDayState createState() => _NewDayState(data);
}

class _NewDayState extends State<NewDay> {
  final data;

  int _value = 0;
  
  _NewDayState(this.data);

  @override
  Widget build(BuildContext context) {
    final day = data.days[widget.index];

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: comfortatext(
                  translation(day.name, data.settings["Language"]), 16,
                  data.settings,
                  color: data.palette.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 25, right: 25),
            child: Row(
              children: [
                SizedBox(
                    width: 35,
                    child: Icon(day.icon, size: 37.0 * day.iconSize, color: data.palette.primary,)),
                Padding(
                  padding: EdgeInsets.only(left: 12.0 / day.iconSize, top: 3),
                  child: comfortatext(day.text, 20, data.settings, color: data.palette.onSurface,
                      weight: FontWeight.w400),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      comfortatext(day.minmaxtemp.split("/")[0], 19, data.settings, color: data.palette.primary),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 4),
                        child: comfortatext("/", 19, data.settings, color: data.palette.onSurface),
                      ),
                      comfortatext(day.minmaxtemp.split("/")[1], 19, data.settings, color: data.palette.primary),
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 20, bottom: 10),
            child: Container(
              height: 85,
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 10, right: 10),
              decoration: BoxDecoration(
                //border: Border.all(width: 1, color: data.palette.outline),
                color: data.palette.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child:  LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GridView.count(
                        padding: const EdgeInsets.all(0),
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                        crossAxisCount: 2,
                        childAspectRatio: constraints.maxWidth / constraints.maxHeight,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.water_drop_outlined,
                                    color: data.palette.primaryFixedDim, size: 21),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10, top: 3),
                                  child: comfortatext('${day.precip_prob}%', 18, data.settings,
                                      color: data.palette.primary),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    Icons.water_drop, color: data.palette.primaryFixedDim, size: 21),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3, left: 10),
                                  child: comfortatext(day.total_precip.toString() +
                                      data.settings["Precipitation"], 18, data.settings,
                                      color: data.palette.primary),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.wind, color: data.palette.primaryFixedDim, size: 21,),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3, left: 10),
                                  child: comfortatext('${day.windspeed} ${data
                                      .settings["Wind"]}', 18, data.settings,
                                      color: data.palette.primary),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(left: 5, right: 3),
                                    child: RotationTransition(
                                        turns: AlwaysStoppedAnimation(day.wind_dir / 360),
                                        child: Icon(CupertinoIcons.arrow_up_circle,
                                          color: data.palette.primaryFixedDim, size: 18,)
                                    )
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.sun_max,
                                    color: data.palette.primaryFixedDim, size: 21),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3, left: 10),
                                  child: comfortatext('${day.uv} UV', 18, data.settings,
                                      color: data.palette.primary),
                                ),
                              ],
                            ),
                          ),
                        ]
                    );
                  }
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
            child: Wrap(
              spacing: 5.0,
              children: List<Widget>.generate(
                4,
                    (int index) {
                  return ChoiceChip(
                    elevation: 0.0,
                    checkmarkColor: data.palette.onPrimaryFixed,
                    selectedColor: data.palette.primaryFixedDim,
                    backgroundColor: data.palette.surfaceContainerLow,
                    side: BorderSide(color: data.palette.surfaceContainerLow, width: 0),
                    label: comfortatext(['temp', 'precip', 'wind', 'uv'][index], 14, data.settings,
                        color: _value == index ? data.palette.onPrimaryFixed : data.palette.onSurface),
                    selected: _value == index,
                    onSelected: (bool selected) {
                      setState(() {
                        _value = (selected ? index : null)!;
                      });
                    },
                  );
                },
              ).toList(),
            ),
          ),
          buildNewHours(day.hourly, data),
        ],
      ),
    );
  }
}

Widget buildNewDays(data) {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 3,
    itemBuilder: (BuildContext context, int index) {
      return NewDay(data: data, index: index);
    },
  );
}


Widget buildNewHours(List<dynamic> hours, data) => Padding(
  padding: const EdgeInsets.only(top: 15),
  child: SizedBox(
    height: 270,
    child: ListView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      children: hours.map<Widget>((hour) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: comfortatext('${hour.temp}°', 19, data.settings, color: data.palette.primary),
            ),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 15,
                  height: 105,
                  decoration: BoxDecoration(
                    color: data.palette.surfaceContainer,
                      //border: Border.all(color: data.palette.outline,),
                      borderRadius: const BorderRadius.all(Radius.circular(20))
                  ),
                ),
                Container(
                  width: 15,
                  height: temp_multiply_for_scale(hour.temp, data.settings['Temperature']!),
                  decoration: BoxDecoration(
                      color: data.palette.primaryFixedDim,
                      borderRadius: const BorderRadius.all(Radius.circular(20))
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 3, right: 3),
              child: SizedBox(
                height: 30,
                child: Icon(
                  hour.icon,
                  color: data.palette.primary,
                  size: 30.0 * hour.iconSize,
                ),
              )
            ),
            Padding(
                padding: const EdgeInsets.only(top:15, left: 9, right: 9),
                child: comfortatext(hour.time, 15, data.settings, color: data.palette.onSurface)
            )
          ],
        );
      }).toList(),
    ),
  ),
);