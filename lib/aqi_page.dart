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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/ui_helper.dart';


class SquigglyCirclePainter extends CustomPainter {

  final Color circleColor;

  SquigglyCirclePainter(this.circleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8;

    final Path path = Path();
    double radius = size.width / 2;
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    double waves = 10;
    double waveAmplitude = size.width / 50;

    for (double i = 0; i <= 360; i += 0.1) {
      double angle = i * pi / 180;
      double x = centerX + (radius + waveAmplitude * sin(waves * angle)) * cos(angle);
      double y = centerY + (radius + waveAmplitude * sin(waves * angle)) * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Widget pollenWidget(IconData icon, String name, double value, data) {
  const categoryBoundaries = [-1, 0, 20, 80, 200];
  const categoryNames = ["nA", "none", "low", "medium", "high"];

  int categoryIndex = 0;
  for (int i = 0; i < categoryBoundaries.length; i++) {
    if (value > categoryBoundaries[i]) {
      categoryIndex = i + 1;
    }
  }

  String severity = categoryNames[categoryIndex];

  return Padding(
    padding: const EdgeInsets.only(left: 10, right: 6, top:6, bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 22, color: data.current.primaryLight),
        Padding(
          padding: const EdgeInsets.only(left: 17),
          child: comfortatext(name, 17, data.settings, color: data.current.onSurface),
        ),
        const Spacer(),
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: data.current.primaryLighter,
            ),
            padding: const EdgeInsets.only(top: 6.5, bottom: 6.5),
            width: 65,
            child: Center(child: comfortatext(severity, 15, data.settings, color: data.current.onPrimaryLight))
        ),
      ],
    ),
  );
}


class ThreeQuarterCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color secondColor;

  ThreeQuarterCirclePainter({required this.percentage, required this.color, required this.secondColor});

  @override
  void paint(Canvas canvas, Size size) {
    double angle = 2 * 3.14159265359 * (percentage / 100) * 0.75; // 3 quarters of a circle

    // Background Circle
    Paint baseCircle = Paint()
      ..color = secondColor
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -3.14159265359 * 5 / 4,
      3.14159265359 * 1.5,
      false,
      baseCircle,
    );

    // Foreground Circle
    Paint progressCircle = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -3.14159265359 * 5 / 4,
      angle,
      false,
      progressCircle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

Widget pollutantWidget(data, name, value, percent) {
  return Padding(
    padding: EdgeInsets.all(4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        comfortatext(name, 14, data.settings, color: data.current.onSurface),
        Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 17, bottom: 7),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: ThreeQuarterCirclePainter(percentage: percent, color: data.current.primaryLight,
                    secondColor: data.current.containerHigh),
                    child: Center(
                      child: comfortatext(value.toString(), 18, data.settings, color: data.current.primary, weight: FontWeight.w600)
                  ),
                ),
                            ),
              ),
          ),
        ),
      ],
    ),
  );
}

class AllergensPage extends StatefulWidget {
  final data;

  const AllergensPage({Key? key, required this.data})
      : super(key: key);

  @override
  _AllergensPageState createState() =>
      _AllergensPageState(data:data);
}

class _AllergensPageState extends State<AllergensPage> {

  final data;

  _AllergensPageState({required this.data});

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OMExtendedAqi>(
      future: OMExtendedAqi.fromJson(data.lat, data.lng, data.settings),
      builder: (BuildContext context,
          AsyncSnapshot<OMExtendedAqi> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        } else if (snapshot.hasError) {
          print((snapshot.error, snapshot.stackTrace));
          return Center(
            child: ErrorWidget(snapshot.error as Object),
          );
        }
        final OMExtendedAqi extendedAqi = snapshot.data!;
        final highestAqi = extendedAqi.dailyAqi.reduce(max);
        return Material(
          color: data.current.surface,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar.large(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: data.current.primary),
                  onPressed: () {
                    goBack();
                  },
                ),
                title: comfortatext("Air Quality", 30, data.settings, color: data.current.primary),
                backgroundColor: data.current.surface,
                pinned: false,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 50, right: 50, top: 50, bottom: 30),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            painter: SquigglyCirclePainter(data.current.primaryLight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: comfortatext(data.aqi.aqi_index.toString(), 52, data.settings, color: data.current.primary, weight: FontWeight.w300),
                                ),
                                comfortatext(data.aqi.aqi_title, 23, data.settings, color: data.current.primary, weight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20, left: 10, right: 10),
                        child: comfortatext(data.aqi.aqi_desc, 17, data.settings, color: data.current.onSurface, weight: FontWeight.w400, align: TextAlign.center),
                      ),


                      /*
                      GridView.count(
                          padding: const EdgeInsets.only(top: 15, bottom: 20, left: 10, right: 10),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          crossAxisCount: 3,
                          childAspectRatio: 4.8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            NewAqiDataPoints("PM2.5", data.aqi.pm2_5, data, 18.0),
                            NewAqiDataPoints("PM10", data.aqi.pm10, data, 18.0),
                            NewAqiDataPoints("O3", data.aqi.o3, data, 18.0),
                            NewAqiDataPoints("NO2", data.aqi.no2, data, 18.0),
                            NewAqiDataPoints("CO", extendedAqi.co, data, 18.0),
                            NewAqiDataPoints("SO2", extendedAqi.so2, data, 18.0),
                          ]
                      ),
                       */


                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: data.current.containerLow,
                            //border: Border.all(width: 1.5, color: data.current.containerHigh),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(17),
                          child: Row(
                            children: [
                              comfortatext("main pollutant", 16, data.settings, color: data.current.onSurface),
                              const Spacer(),
                              comfortatext(extendedAqi.mainPollutant, 18, data.settings, color: data.current.primaryLight, weight: FontWeight.w600)
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 40),
                        child: Container(
                          decoration: BoxDecoration(
                            //color: data.current.containerLow,
                            border: Border.all(width: 2, color: data.current.containerHigh),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            children: [
                              pollenWidget(Icons.forest_outlined, "Alder Pollen", extendedAqi.alder, data),
                              pollenWidget(Icons.eco_outlined, "Birch Pollen", extendedAqi.birch, data),
                              pollenWidget(Icons.grass_outlined, "Grass Pollen", extendedAqi.grass, data),
                              pollenWidget(Icons.local_florist_outlined, "Mugwort Pollen", extendedAqi.mugwort, data),
                              pollenWidget(Icons.park_outlined, "Olive Pollen", extendedAqi.olive, data),
                              pollenWidget(Icons.filter_vintage_outlined, "Ragweed Pollen", extendedAqi.ragweed, data),
                            ],
                          ),
                        ),
                      ),

                      NewHourlyAqi(data: data, extendedAqi: extendedAqi),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 50),
                        child: Container(
                          decoration: BoxDecoration(
                            //color: data.current.containerLow,
                            border: Border.all(width: 2, color: data.current.containerHigh),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.all(13),
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            childAspectRatio: 0.95,
                            children: <Widget>[
                              pollutantWidget(data, "pm2.5", data.aqi.pm2_5, extendedAqi.pm2_5_p),
                              pollutantWidget(data, "pm10", data.aqi.pm10, extendedAqi.pm10_p),
                              pollutantWidget(data, "o3", data.aqi.o3, extendedAqi.o3_p),
                              pollutantWidget(data, "no2", data.aqi.no2, extendedAqi.no2_p),
                              pollutantWidget(data, "co", extendedAqi.co, extendedAqi.co_p),
                              pollutantWidget(data, "so2", extendedAqi.so2, extendedAqi.so2_p),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 0),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: data.current.containerLow,
                                      //border: Border.all(width: 1.5, color: data.current.containerHigh),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    height: 115,
                                    padding: const EdgeInsets.only(left: 14, top: 14, right: 10, bottom: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        comfortatext("european aqi", 14, data.settings, color: data.current.onSurface),
                                        const Spacer(),
                                        comfortatext(extendedAqi.european_aqi.toString(), 25, data.settings, color: data.current.primary, weight: FontWeight.w400),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, top: 1),
                                          child: comfortatext("good", 15, data.settings, color: data.current.outline, weight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                            ),
                            Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: data.current.containerLow,
                                      //border: Border.all(width: 1.5, color: data.current.containerHigh),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    height: 115,
                                    padding: const EdgeInsets.only(left: 14, top: 14, right: 10, bottom: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        comfortatext("united states aqi", 14, data.settings, color: data.current.onSurface),
                                        const Spacer(),
                                        comfortatext(extendedAqi.us_aqi.toString(), 25, data.settings, color: data.current.primary, weight: FontWeight.w400),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, top: 1),
                                          child: comfortatext("good", 15, data.settings, color: data.current.outline, weight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                            )
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 35),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: comfortatext("daily aqi", 16, data.settings, color: data.current.primary)
                        ),
                      ),

                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(extendedAqi.dailyAqi.length, (index) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
                                  child: SizedBox(
                                    height: 130,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(22),
                                            color: extendedAqi.dailyAqi[index] == highestAqi ? data.current.surface : data.current.primaryLight,
                                            border: Border.all(color: extendedAqi.dailyAqi[index] == highestAqi ? data.current.primaryLight
                                                : data.current.surface, width: 2)
                                        ),
                                        width: 43,
                                        alignment: Alignment.topCenter,
                                        padding: const EdgeInsets.only(top: 12),
                                        height: 110 / highestAqi * extendedAqi.dailyAqi[index],
                                        child: comfortatext(extendedAqi.dailyAqi[index].toString(), 16, data.settings,
                                            color: extendedAqi.dailyAqi[index] == highestAqi ? data.current.primaryLight : data.current.surface,
                                            weight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                                comfortatext(index == 0 ? "now" : "${index}d", 14, data.settings, color: data.current.outline)
                              ],
                            );
                          }
                          )
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 45, bottom: 0),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //color: data.current.containerLow,
                                      border: Border.all(width: 1.5, color: data.current.containerHigh),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    height: 125,
                                    padding: const EdgeInsets.only(left: 14, top: 14, right: 10, bottom: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.grain, size: 18, color: data.current.primaryLight),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 5),
                                              child: comfortatext("dust", 14, data.settings, color: data.current.onSurface),
                                            )
                                          ],
                                        ),
                                        const Spacer(),
                                        comfortatext(extendedAqi.dust.toString(), 25, data.settings, color: data.current.primary, weight: FontWeight.w400),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, top: 1),
                                          child: comfortatext("μg/m³", 15, data.settings, color: data.current.outline, weight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                            ),
                            Expanded(
                                flex: 8,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //color: data.current.containerLow,
                                      border: Border.all(width: 1.5, color: data.current.containerHigh),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    height: 125,
                                    padding: const EdgeInsets.only(left: 14, top: 14, right: 10, bottom: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.grain, size: 18, color: data.current.primaryLight),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 5),
                                                child: comfortatext("aerosol \noptical depth", 14, data.settings, color: data.current.onSurface),
                                              ),
                                            )
                                          ],
                                        ),
                                        const Spacer(),
                                        comfortatext(extendedAqi.aod.toString(), 25, data.settings, color: data.current.primary, weight: FontWeight.w400),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, top: 1),
                                          child: comfortatext("extremely clear", 15, data.settings, color: data.current.outline, weight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                            )
                          ],
                        ),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60, bottom: 70),
                          child: comfortatext("powered by open-meteo", 15, data.settings, color: data.current.outline),
                        ),
                      )

                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class NewHourlyAqi extends StatefulWidget {
  final data;
  final extendedAqi;

  NewHourlyAqi({Key? key, required this.data, required this.extendedAqi}) : super(key: key);

  @override
  _NewHourlyAqiState createState() => _NewHourlyAqiState(data, extendedAqi);
}

class _NewHourlyAqiState extends State<NewHourlyAqi> with AutomaticKeepAliveClientMixin {
  final data;
  final extendedAqi;
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

  _NewHourlyAqiState(this.data, this.extendedAqi);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: SizedBox(
            height: 300,
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: <Widget>[
                HourlyQqi(data, extendedAqi.pm2_5_h, "PM2.5"),
                HourlyQqi(data, extendedAqi.pm10_h, "PM10"),
                HourlyQqi(data, extendedAqi.o3_h, "O3"),
                HourlyQqi(data, extendedAqi.no2_h, "NO2"),
                HourlyQqi(data, extendedAqi.co_h, "CO"),
                HourlyQqi(data, extendedAqi.so2_h, "SO2"),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 5.0,
          children: List<Widget>.generate(
            6,
                (int index) {

              return ChoiceChip(
                elevation: 0.0,
                checkmarkColor: data.current.onPrimaryLight,
                color: WidgetStateProperty.resolveWith((states) {
                  if (index == _value) {
                    return data.current.primaryLighter;
                  }
                  return data.current.surface;
                }),
                side: BorderSide(color: data.current.primaryLighter, width: 1.5),
                label: comfortatext(
                    ['pm2.5', 'pm10', 'o3', 'no2', 'co', 'so2'][index], 14, data.settings,
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
      ],
    );

  }
}

class AQIGraphPainter extends CustomPainter {
  final List<double> aqiData;
  final int maxAQI;
  final Color color;

  AQIGraphPainter({required this.aqiData, required this.maxAQI, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final double chartHeight = size.height;
    final double chartWidth = size.width;
    final double yScale = chartHeight / maxAQI;
    final double xSpacing = chartWidth / (aqiData.length - 1);

    for (int i = 0; i < aqiData.length - 1; i++) {
      final startX = i * xSpacing;
      final startY = chartHeight - (aqiData[i] * yScale);
      final endX = (i + 1) * xSpacing;
      final endY = chartHeight - (aqiData[i + 1] * yScale);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; //if data changes -> repaints
  }
}

Widget HourlyQqi(data, hourValues, name) {

  const List<List<int>> chartTypes = [
    [0, 5, 10, 15, 20, 25],
    [0, 10, 20, 30, 40, 50],
    [0, 20, 40, 60, 80, 100],
    [0, 30, 60, 90, 120, 150],
    [0, 50, 100, 150, 200, 250],
    [0, 100, 200, 300, 400, 500],
    [0, 200, 400, 600, 800, 1000]
  ];

  double valueMax = hourValues.reduce((a, b) => max<double>(a, b));
  int currentChart = 0;

  for (int i = 0; i < chartTypes.length; i++) {
    if (valueMax * 1.3 > chartTypes[i][chartTypes[i].length - 1]) { //because it looks weird if it is close to the top
      currentChart = min(i + 1, chartTypes.length - 1); //just for null safety
    }
  }

  int len = chartTypes[currentChart].length;

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
            children: [
              Icon(Icons.grain, size: 20, color: data.current.primaryLight),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: comfortatext(name, 17, data.settings, color: data.current.primary),
              )
            ]
        ),
      ),

      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 10),
            child: SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(len, (index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      comfortatext(chartTypes[currentChart][len - 1 - index].toString(), 14, data.settings,
                          color: data.current.outline),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Container(
                            color: data.current.containerHigh,
                            height: 1,
                          ),
                        ),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 20),
            child: CustomPaint(
              painter: AQIGraphPainter(aqiData: hourValues,
                  maxAQI: chartTypes[currentChart][len - 1],
                  color: data.current.primaryLight),
              child: const SizedBox(
                width: double.infinity,
                height: 220.0,
              ),
            ),
          ),
        ],
      ),
      Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            comfortatext("now", 14,data. settings, color: data.current.outline),
            comfortatext("1d", 14, data.settings, color: data.current.outline),
            comfortatext("2d", 14, data.settings, color: data.current.outline),
            comfortatext("3d", 14, data.settings, color: data.current.outline),
            comfortatext("4d", 14, data.settings, color: data.current.outline),
            comfortatext("5d", 14, data.settings, color: data.current.outline),
        ])
      )
    ]
  );
}
