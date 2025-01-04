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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget dayStat(data, IconData icon, number, addon, {addWind = false, windDir = 0, iconSize = 21.0}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon,
          color: data.current.primaryLight, size: iconSize),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 3),
            child: comfortatext(number.toString(), 18, data.settings,
                color: data.current.primary),
          ),
          comfortatext(addon, 15, data.settings, color: data.current.primary)
        ],
      ),
      if (addWind) Padding(
          padding: const EdgeInsets.only(left: 5, right: 3),
          child: RotationTransition(
              turns: AlwaysStoppedAnimation(windDir / 360),
              child: Icon(Icons.arrow_circle_right_outlined,
                color: data.current.primaryLight, size: 20)
          )
      ),
    ],
  );
}

class NewDay extends StatefulWidget {
  final data;
  final index;
  final state;
  final onExpandTapped;
  final day;

  NewDay({Key? key, required this.data, required this.index, required this.state,
  required this.onExpandTapped, required this.day}) : super(key: key);

  @override
  _NewDayState createState() => _NewDayState(data, index, state, onExpandTapped, day);
}

class _NewDayState extends State<NewDay> with AutomaticKeepAliveClientMixin {
  final data;
  final day;
  final index;
  final bool state;
  final onExpandTapped;
  int _value = 0;

  PageController _pageController = PageController();

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
  }

  @override
  bool get wantKeepAlive => true;

  _NewDayState(this.data, this.index, this.state, this.onExpandTapped, this.day);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Color highlight = state ? data.current.containerHigh : data.current.container;

    return Stack(
      children: [
        if (state) GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            onExpandTapped(index);
          },
          child: const SizedBox(height: 70, width: double.infinity,)
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: state ? 15 : 5, top: state ? 20 : 0),
              child: Row(
                children: [
                  comfortatext(
                      day.name, 16,
                      data.settings,
                      color: data.current.onSurface),
                  const Spacer(),
                  if (state) Padding(
                    padding: const EdgeInsets.only(right: 13),
                    child: GestureDetector(
                      child: Icon(Icons.expand_less, color: data
                          .current.primaryLight, size: 20),
                      onTap: () {
                        onExpandTapped(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18, left: 23, right: 25, bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                      width: 35,
                      child: Icon(day.icon, size: 38.0 * day.iconSize, color: data.current.primary,)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 3),
                      child: comfortatext(day.text, 20, data.settings, color: data.current.onSurface,
                          weight: FontWeight.w400),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        comfortatext(day.minmaxtemp.split("/")[0], 20, data.settings, color: data.current.primary),
                        Padding(
                          padding: const EdgeInsets.only(left: 5, right: 7),
                          child: comfortatext("/", 19, data.settings, color: data.current.onSurface),
                        ),
                        comfortatext(day.minmaxtemp.split("/")[1], 20, data.settings, color: data.current.primary),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Visibility(
                visible: day.mm_precip > 0.1,
                child: RainWidget(data, day, highlight, data.current.containerHigh)
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 18, bottom: 8),
              child: Container(
                height: 87,
                padding: const EdgeInsets.only(top: 9, bottom: 9, left: 15, right: 15),
                decoration: BoxDecoration(
                  //border: Border.all(width: 1, color: data.current.outline),
                  color: state ? data.current.container : data.current.containerLow,
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
                            dayStat(data, Icons.umbrella_rounded, day.precip_prob, "%"),
                            dayStat(data, Icons.water_drop_outlined, day.total_precip, data.settings["Precipitation"]),
                            dayStat(data, Icons.air, day.windspeed, data.settings["Wind"], addWind: true,
                                windDir: day.wind_dir),
                            dayStat(data, Icons.wb_sunny_outlined, day.uv, "UV", iconSize: 20.0),
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

                    return ChoiceChip(
                      elevation: 0.0,
                      checkmarkColor: data.current.onPrimaryLight,
                      color: WidgetStateProperty.resolveWith((states) {
                        if (index == _value) {
                          return data.current.primaryLighter;
                        }
                        return state ? data.current.containerLow : data.current.surface;
                      }),
                      side: BorderSide(color: data.current.primaryLighter, width: 1.5),
                      //translation(['temp', 'precip', 'wind', 'uv'][index], data.settings["Language"])
                      label: comfortatext(
                          [
                            AppLocalizations.of(context)!.temp,
                            AppLocalizations.of(context)!.precipLowercase,
                            AppLocalizations.of(context)!.windLowercase,
                            AppLocalizations.of(context)!.uvLowercase,
                          ][index],
                          14, data.settings,
                          color: _value == index ? data.current.onPrimaryLight : data.current.onSurface),
                      selected: _value == index,
                      onSelected: (bool selected) {
                        _value = index;
                        setState(() {
                          HapticFeedback.lightImpact();
                          _onItemTapped(index);
                        });
                      },
                    );
                  },
                ).toList(),
              ),
            ),
            SizedBox(
              height: state? 280 : 260,
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                children: <Widget>[
                  buildTemp(day.hourly, data, data.current.containerHigh),
                  buildPrecip(day.hourly, data, data.current.containerHigh),
                  WindReport(hours: day.hourly, data: data, highlight: data.current.containerHigh,),
                  buildUV(day.hourly, data, data.current.containerHigh),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget buildNewDays(data) {
  return ListView.builder(
    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: min(3, data.days.length),
    itemBuilder: (BuildContext context, int index) {
      final day = data.days[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NewDay(data: data, index: index, key: Key("${data.place}, ${data.current.surface}"),
        state: false, onExpandTapped: null, day: day,),
      );
    },
  );
}

Widget buildTemp(List<dynamic> hours, data, Color highlight) => ListView(
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
            child: comfortatext('${hour.temp}°', 19, data.settings, color: data.current.primary),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 14,
                height: 105,
                decoration: BoxDecoration(
                  color: highlight,
                    //border: Border.all(color: data.current..outline,),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
              ),
              Container(
                width: 14,
                height: min(max(hour.raw_temp * 1.8 + 30, 14), 105),
                decoration: BoxDecoration(
                    color: data.current.primaryLight,
                  //border: Border.all(color: data.current.primaryLight, width: 2),
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
                color: data.current.primary,
                size: 31.0 * hour.iconSize,
              ),
            )
          ),
          Padding(
              padding: const EdgeInsets.only(top:13),
              child: comfortatext(hour.time, 15, data.settings, color: data.current.onSurface)
          )
        ],
      ),
    );
  }).toList(),
);

class WindChartPainter extends CustomPainter {
  final List<dynamic> hours;
  final data;
  final highlight;
  final double dotRadius;
  final double smallDotRadius;
  final double spacing;
  final double maxHeight;

  WindChartPainter({
    required this.hours,
    required this.data,
    required this.highlight,
    this.dotRadius = 7.0,
    this.smallDotRadius = 1.8,
    this.spacing = 55.0,
    this.maxHeight = 105.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = data.current.primaryLight
      ..strokeWidth = 2.0;

    final smallDotPaint = Paint()
      ..color = highlight
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < hours.length; i++) {
      final x = 27.5 + i * spacing;
      final y = maxHeight - max(min(hours[i].raw_wind * 1.4, maxHeight), 0);

      canvas.drawCircle(Offset(x, y), dotRadius, paint);

      textPainter.text = TextSpan(
        text: String.fromCharCode(Icons.arrow_downward.codePoint),
        style: TextStyle(
          fontSize: dotRadius * 2,
          fontFamily: Icons.arrow_forward.fontFamily,
          color: data.current.primary,
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
        final nextY = maxHeight - max(min(hours[i + 1].raw_wind * 1.4, maxHeight), 0);

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
  final Color highlight;

  WindReport({required this.hours, required this.data, required this.highlight});

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
              painter: WindChartPainter(hours: hours, data: data, highlight: highlight),
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
                            comfortatext('${hour.wind}', 18, data.settings, color: data.current.primary,
                            weight: FontWeight.w500),
                            comfortatext('${data.settings["Wind"]}', 9, data.settings, color: data.current.primary),
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
                              color: data.current.primary,
                              size: 31.0 * hour.iconSize,
                            ),
                          )
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top:13),
                          child: comfortatext(hour.time, 15, data.settings, color: data.current.onSurface)
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

Widget buildUV(List<dynamic> hours, data, highlight) => ListView(
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
            child: comfortatext('${hour.uv}', 19, data.settings, color: data.current.primary),
          ),
          SizedBox(
            height: 105,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
                itemExtent: 10,
                itemBuilder: (BuildContext context, int index) {
                  if (index < min(max(10 - hour.uv, 0), 10)) {
                    return Center(
                      child: Container(
                        width: 14,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: highlight,
                        ),
                      ),
                    );
                  }
                  else {
                    return Center(
                      child: Container(
                        width: 14,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: data.current.primaryLight,
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
                  color: data.current.primary,
                  size: 31.0 * hour.iconSize,
                ),
              )
          ),
          Padding(
              padding: const EdgeInsets.only(top:13),
              child: comfortatext(hour.time, 15, data.settings, color: data.current.onSurface)
          )
        ],
      ),
    );
  }).toList(),
);


Widget buildPrecip(List<dynamic> hours, data, Color highlight) => ListView(
  physics: const BouncingScrollPhysics(),
  scrollDirection: Axis.horizontal,
  shrinkWrap: true,
  children: hours.map<Widget>((hour) {
    return SizedBox(
      width: 55, //this is all to ensure that nothing shifts when you switch categories
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                comfortatext('${hour.precip}', 18, data.settings, color: data.current.primary,
                    weight: FontWeight.w500),
                comfortatext('${data.settings["Precipitation"]}', 9, data.settings, color: data.current.primary),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: comfortatext('${hour.precip_prob}%', 14, data.settings, color: data.current.primaryLight,
                  weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 99,
            width: 15.5,
            child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 24,
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
                          color: highlight,
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
                          color: data.current.primaryLight,
                        ),
                      ),
                    );
                  }
                }
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 5, left: 3, right: 3),
              child: SizedBox(
                height: 30,
                child: Icon(
                  hour.icon,
                  color: data.current.primary,
                  size: 31.0 * hour.iconSize,
                ),
              )
          ),
          Padding(
              padding: const EdgeInsets.only(top:13),
              child: comfortatext(hour.time, 15, data.settings, color: data.current.onSurface)
          )
        ],
      ),
    );
  }).toList(),
);


class buildNewGlanceDay extends StatefulWidget {
  final data;

  buildNewGlanceDay({Key? key, required this.data}) : super(key: key);

  @override
  _buildNewGlanceDayState createState() => _buildNewGlanceDayState(data);
}

class _buildNewGlanceDayState extends State<buildNewGlanceDay> with AutomaticKeepAliveClientMixin {
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

  _buildNewGlanceDayState(this.data);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (data.days.length > 3) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 25),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 1, top: 0, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(
                    "daily", 16,
                    data.settings,
                    color: data.current.onSurface),
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(
                    top: 5, bottom: 5, left: 0, right: 0),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.days.length - 3,
                itemBuilder: (context, index) {
                  final day = data.days[index + 3];
                  return Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 3),
                    child: AnimatedContainer(
                      height: expand[index] ? (day.mm_precip > 0.1
                          ? (MediaQuery.of(context).size.width - 110) / 2.2 + 610: 528.0) : 73.0,
                      duration: const Duration(milliseconds:250),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: expand[index] ? Container(
                          decoration: BoxDecoration(
                              borderRadius:
                              index == 0 ? const BorderRadius.vertical(
                                  top: Radius.circular(18.0),
                                  bottom: Radius.circular(8))
                                  : index == data.days.length - 4 ? const BorderRadius
                                  .vertical(bottom: Radius.circular(18.0),
                                  top: Radius.circular(8))
                                  : BorderRadius.circular(8),
                              color: data.current.containerLow),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, left: 3, right: 3),
                            child: NewDay(data: data, index: index, state: true,
                              onExpandTapped: _onExpandTapped, day: day,),
                          ),
                        )
                            : GlanceDayEntry(data, index, day, _onExpandTapped),
                      ),
                    ),
                  );
                }
            ),
          ],
        ),
      );
    }
    else {
      return Container();
    }
  }
}


Widget GlanceDayEntry(data, index, day, onExpandTapped) {
  return GestureDetector(
    onTap: () {
      onExpandTapped(index);
    },
    child: Container(
      decoration: BoxDecoration(
          borderRadius:
          index == 0 ? const BorderRadius.vertical(
              top: Radius.circular(18.0),
              bottom: Radius.circular(8))
              : index == data.days.length - 4 ? const BorderRadius
              .vertical(bottom: Radius.circular(18.0),
              top: Radius.circular(8))
              : BorderRadius.circular(8),
          color: data.current.containerLow),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 73,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      comfortatext(day.name.split(", ")[0], 18,
                          data.settings,
                          color: data.current.primary),
                      comfortatext(day.name.split(", ")[1], 14,
                          data.settings,
                          color: data.current.onSurface),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
                width: 43,
                child: Icon(
                  day.icon,
                  color: data.current.primary,
                  size: 31.0 * day.iconSize,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 10, top: 2, bottom: 2),
                child: Container(
                  height: 56,
                  width: 43,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      //border: Border.all(width: 1.5, color: data.current.primaryLight)
                      color: data.current.primaryLighter
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 2),
                            child: Icon(Icons.keyboard_arrow_up,
                              color: data.current.onPrimaryLight,
                              size: 14,),
                          ),
                          Icon(Icons.keyboard_arrow_down,
                            color: data.current.onPrimaryLight, size: 14,),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 2),
                              child: comfortatext(
                                  day.minmaxtemp.split("/")[1], 14,
                                  data.settings,
                                  color: data.current.onPrimaryLight),
                            ),
                            comfortatext(
                                day.minmaxtemp.split("/")[0], 14,
                                data.settings,
                                color: data.current.onPrimaryLight),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          dayStat(data, Icons.umbrella_rounded, day.precip_prob, "%", iconSize: 20.0),
                          const SizedBox(width: 6,),
                          dayStat(data, Icons.water_drop_outlined, day.total_precip,
                              data.settings["Precipitation"], iconSize: 20.0),
                        ]
                      ),
                    ),
                    dayStat(data, Icons.air, day.windspeed, data.settings["Wind"], addWind: true,
                        windDir: day.wind_dir),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.expand_more, color: data
                        .current.primaryLight, size: 20,),
                    onPressed: () {
                      onExpandTapped(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}