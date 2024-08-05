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


import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'ui_helper.dart';


class NewDay extends StatefulWidget {
  final data;
  final index;

  NewDay({Key? key, required this.data, required this.index}) : super(key: key);

  @override
  _NewDayState createState() => _NewDayState(data);
}

class _NewDayState extends State<NewDay> with AutomaticKeepAliveClientMixin {
  final data;
  int _value = 0;

  PageController _pageController = PageController();

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 400),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
  }

  @override
  bool get wantKeepAlive => true;

  _NewDayState(this.data);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print(("here", _value));
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
                  day.name, 16,
                  data.settings,
                  color: data.palette.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 23, right: 25),
            child: Row(
              children: [
                SizedBox(
                    width: 35,
                    child: Icon(day.icon, size: 38.0 * day.iconSize, color: data.palette.primary,)),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 3),
                  child: comfortatext(day.text, 20, data.settings, color: data.palette.onSurface,
                      weight: FontWeight.w400),
                ),
                const Spacer(),
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
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 15),
            child: Wrap(
              spacing: 5.0,
              children: List<Widget>.generate(
                4,
                    (int index) {
                  print((_value, index));

                  return ChoiceChip(
                    elevation: 0.0,
                    checkmarkColor: data.palette.onPrimaryFixed,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (index == _value) {
                        return data.palette.primaryFixedDim;
                      }
                      return data.palette.surface;
                    }),
                    side: BorderSide(color: data.palette.primaryFixedDim, width: 1.0),
                    label: comfortatext(
                        ['temp', 'precip', 'wind', 'uv'][index], 14, data.settings,
                        color: _value == index ? data.palette.onPrimaryFixed : data.palette.onSurface),
                    selected: _value == index,
                    onSelected: (bool selected) {
                      //setState(() {
                      //  updateChip(index);
                      //});
                      _value = index;
                      setState(() {
                        _onItemTapped(index);
                      });
                      /*
                      setState(() {
                        _onItemTapped(index);
                      });
                       */
                    },
                  );
                },
              ).toList(),
            ),
          ),
          SizedBox(
            height: 260,
            child: PageView(
              controller: _pageController,
              children: <Widget>[
                buildTemp(day.hourly, data),
                buildPrecip(day.hourly, data),
                WindReport(hours: day.hourly, data: data,),
                buildUV(day.hourly, data),
              ],
            ),
          ),
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
      return NewDay(data: data, index: index, key: Key("${data.place}, ${data.current.backcolor}"),);
    },
  );
}

Widget buildTemp(List<dynamic> hours, data) => ListView(
  physics: const BouncingScrollPhysics(),
  scrollDirection: Axis.horizontal,
  shrinkWrap: true,
  children: hours.map<Widget>((hour) {
    return SizedBox(
      width: 55, //this is all to ensure that nothing shifts when you switch categories
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: comfortatext('${hour.temp}°', 19, data.settings, color: data.palette.primary),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 14,
                height: 105,
                decoration: BoxDecoration(
                  color: data.palette.surfaceContainer,
                    //border: Border.all(color: data.palette.outline,),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
              ),
              Container(
                width: 13,
                height: hour.raw_temp * 1.8 + 30,
                decoration: BoxDecoration(
                    color: data.palette.primaryFixedDim,
                  //border: Border.all(color: data.palette.primaryFixedDim, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 17, left: 3, right: 3),
            child: SizedBox(
              height: 30,
              child: Icon(
                hour.icon,
                color: data.palette.primary,
                size: 31.0 * hour.iconSize,
              ),
            )
          ),
          Padding(
              padding: const EdgeInsets.only(top:13),
              child: comfortatext(hour.time, 15, data.settings, color: data.palette.onSurface)
          )
        ],
      ),
    );
  }).toList(),
);

class WindChartPainter extends CustomPainter {
  final List<dynamic> hours;
  final data;
  final double dotRadius;
  final double smallDotRadius;
  final double spacing;
  final double maxHeight;

  WindChartPainter({
    required this.hours,
    required this.data,
    this.dotRadius = 7.0,
    this.smallDotRadius = 1.8,
    this.spacing = 55.0,
    this.maxHeight = 105.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = data.palette.primaryFixedDim
      ..strokeWidth = 2.0;

    final smallDotPaint = Paint()
      ..color = data.palette.surfaceContainerHigh
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < hours.length; i++) {
      final x = 27.5 + i * spacing;
      final y = maxHeight - max(min(hours[i].raw_wind * 1.8, maxHeight), 0);

      canvas.drawCircle(Offset(x, y), dotRadius, paint);

      textPainter.text = TextSpan(
        text: String.fromCharCode(Icons.arrow_forward.codePoint),
        style: TextStyle(
          fontSize: dotRadius * 2,
          fontFamily: Icons.arrow_forward.fontFamily,
          color: data.palette.primary,
        ),
      );
      textPainter.layout();

      //this is all so it can be rotated
      canvas.save();
      canvas.translate(x, (y < 30) ? y + dotRadius * 2.4 : y - dotRadius * 2.4);
      canvas.rotate(pi / 180 * hours[i].wind_dir);
      textPainter.paint(canvas, Offset(-dotRadius, -dotRadius));
      canvas.restore();

      if (i < hours.length - 1) {
        final nextX = 27.5 + (i + 1) * spacing;
        final nextY = maxHeight - max(min(hours[i + 1].raw_wind * 1.8, maxHeight), 0);

        int numDots = 4;
        double dx = (nextX - x) / numDots;
        double dy = (nextY - y) / numDots;

        for (int j = 1; j < numDots; j++) {
          double startX = x + dx * j;
          double startY = y + dy * j;
          canvas.drawCircle(Offset(startX, startY), smallDotRadius, smallDotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class WindReport extends StatelessWidget {
  final hours;
  final data;

  WindReport({required this.hours, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 45, bottom: 20),
            child: CustomPaint(
              size: Size(hours.length * 55.0, 105.0),
              painter: WindChartPainter(hours: hours, data: data),
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: hours.map<Widget>((hour) {
                return SizedBox(
                  width: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            comfortatext('${hour.wind}', 18, data.settings, color: data.palette.primary,
                            weight: FontWeight.w500),
                            comfortatext('${data.settings["Wind"]}', 9, data.settings, color: data.palette.primary),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 114,
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 3, right: 3),
                          child: SizedBox(
                            height: 30,
                            child: Icon(
                              hour.icon,
                              color: data.palette.primary,
                              size: 31.0 * hour.iconSize,
                            ),
                          )
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top:13),
                          child: comfortatext(hour.time, 15, data.settings, color: data.palette.onSurface)
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildUV(List<dynamic> hours, data) => ListView(
  physics: const BouncingScrollPhysics(),
  scrollDirection: Axis.horizontal,
  shrinkWrap: true,
  children: hours.map<Widget>((hour) {
    return SizedBox(
      width: 55, //this is all to ensure that nothing shifts when you switch categories
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 15),
            child: comfortatext('${hour.uv}', 19, data.settings, color: data.palette.primary),
          ),
          SizedBox(
            height: 105,
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: 10,
                itemExtent: 10,
                itemBuilder: (BuildContext context, int index) {
                  if (index < min(max(10 - hour.uv, 0), 10)) {
                    return Center(
                      child: Container(
                        width: 10,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: data.palette.surfaceContainerHigh,
                        ),
                      ),
                    );
                  }
                  else {
                    return Center(
                      child: Container(
                        width: 10,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: data.palette.primaryFixedDim,
                        ),
                      ),
                    );
                  }
                }
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 12, left: 3, right: 3),
              child: SizedBox(
                height: 30,
                child: Icon(
                  hour.icon,
                  color: data.palette.primary,
                  size: 31.0 * hour.iconSize,
                ),
              )
          ),
          Padding(
              padding: const EdgeInsets.only(top:13),
              child: comfortatext(hour.time, 15, data.settings, color: data.palette.onSurface)
          )
        ],
      ),
    );
  }).toList(),
);


Widget buildPrecip(List<dynamic> hours, data) => ListView(
  physics: const BouncingScrollPhysics(),
  scrollDirection: Axis.horizontal,
  shrinkWrap: true,
  children: hours.map<Widget>((hour) {
    return SizedBox(
      width: 55, //this is all to ensure that nothing shifts when you switch categories
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                comfortatext('${hour.precip}', 18, data.settings, color: data.palette.primary,
                    weight: FontWeight.w500),
                comfortatext('${data.settings["Precipitation"]}', 9, data.settings, color: data.palette.primary),
              ],
            ),
          ),
          SizedBox(
            height: 101,
            width: 15.5,
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                physics: NeverScrollableScrollPhysics(),
                itemCount: 26,
                reverse: true,
                itemBuilder: (BuildContext context, int index) {
                  double prec = hour.precip > 0 ? 1 : 0;
                  prec += hour.precip * 2.0;
                  if (index >= prec) {
                    return Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: data.palette.surfaceContainerHigh,
                        ),
                      ),
                    );
                  }
                  else {
                    return Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: data.palette.primaryFixedDim,
                        ),
                      ),
                    );
                  }
                }
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 12, left: 3, right: 3),
              child: SizedBox(
                height: 30,
                child: Icon(
                  hour.icon,
                  color: data.palette.primary,
                  size: 31.0 * hour.iconSize,
                ),
              )
          ),
          Padding(
              padding: const EdgeInsets.only(top:13),
              child: comfortatext(hour.time, 15, data.settings, color: data.palette.onSurface)
          )
        ],
      ),
    );
  }).toList(),
);


Widget buildNewGlanceDay(var data) => Padding(
  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 10),
  child: Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 1, top: 0, bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: comfortatext(
              "daily", 16,
              data.settings,
              color: data.palette.onSurface),
        ),
      ),
      ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 5, bottom: 5, left: 0, right: 0),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.days.length - 3,
          itemBuilder: (context, index) {
            final day = data.days[index + 3];
            return Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: data.palette.surfaceContainerLow),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 65,
                          height: 73,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                comfortatext(day.name.split(", ")[0], 18, data.settings, color: data.palette.primary),
                                comfortatext(day.name.split(", ")[1], 14, data.settings, color: data.palette.primaryFixedDim),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          width: 40,
                          child: Icon(
                            day.icon,
                            color: data.palette.primary,
                            size: 31.0 * day.iconSize,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                          child: Container(
                            height: 58,
                            width: 43,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: data.palette.primaryFixedDim),
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_drop_up, color: data.palette.primary, size: 14,),
                                    Icon(Icons.arrow_drop_down, color: data.palette.primary, size: 14,),
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      comfortatext(day.minmaxtemp.split("/")[1], 14, data.settings, color: data.palette.primary),
                                      comfortatext(day.minmaxtemp.split("/")[0], 14, data.settings,color: data.palette.primary),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.water_drop_outlined,
                                    color: data.current.secondary, size: 18,),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2, right: 5),
                                    child: comfortatext('${day.precip_prob}%', 17, data.settings,
                                        color: data.current.secondary),
                                  ),
                                  Icon(
                                    Icons.water_drop, color: data.current.secondary, size: 18,),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2, right: 2),
                                    child: comfortatext(day.total_precip.toString() +
                                        data.settings["Precipitation"], 17, data.settings, color: data.current.secondary),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.wind, color: data.current.secondary, size: 18,),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2, right: 2),
                                    child: comfortatext('${day.windspeed} ${data
                                        .settings["Wind"]}', 17, data.settings, color: data.current.secondary),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.only(left: 3, right: 3, bottom: 1),
                                      child: RotationTransition(
                                          turns: AlwaysStoppedAnimation(day.wind_dir / 360),
                                          child: Icon(CupertinoIcons.arrow_up_circle_fill,
                                            color: data.current.secondary, size: 16,)
                                      )
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Icon(Icons.arrow_forward_ios, color: data.palette.primaryFixedDim, size: 14,),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    ],
  ),
);