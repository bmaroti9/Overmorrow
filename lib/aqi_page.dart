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
      ..strokeWidth = 3;

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
          child: comfortatext(name, 17.5, data.settings, color: data.current.onSurface),
        ),
        const Spacer(),
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: data.current.primaryLighter,
            ),
            padding: const EdgeInsets.only(top: 6.5, bottom: 6),
            width: 65,
            child: Center(child: comfortatext(severity, 16, data.settings, color: data.current.onPrimaryLight))
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
                        padding: const EdgeInsets.only(left: 47, right: 47, top: 50, bottom: 30),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            painter: SquigglyCirclePainter(data.current.primaryLight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: comfortatext("1", 55, data.settings, color: data.current.primary, weight: FontWeight.w300),
                                ),
                                comfortatext("good", 24, data.settings, color: data.current.primary, weight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: comfortatext(data.aqi.aqi_desc, 18, data.settings, color: data.current.onSurface, weight: FontWeight.w400, align: TextAlign.center),
                      ),


                      GridView.count(
                          padding: const EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
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

                      Padding(
                        padding: const EdgeInsets.only(top: 25, bottom: 40),
                        child: Container(
                          decoration: BoxDecoration(
                            color: data.current.containerLow,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(8),
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

                      /*
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(width: 1.5, color: data.current.containerHigh),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              height: 110,
                              padding: const EdgeInsets.only(left: 14, top: 14, right: 10, bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.grain, size: 18, color: data.current.primaryLight),
                                      Padding(
                                        padding: EdgeInsets.only(left: 5, bottom: 12),
                                        child: comfortatext("dust", 15, data.settings, color: data.current.onSurface),
                                      )
                                    ],
                                  ),
                                  const Spacer(),
                                  comfortatext(data.aqi.dust.toString(), 25, data.settings, color: data.current.primary, weight: FontWeight.w400),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2, top: 1),
                                    child: comfortatext("μg/m³", 15, data.settings, color: data.current.primary, weight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                      ),
                      Expanded(
                        flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(width: 1.5, color: data.current.containerHigh),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              height: 110,
                              padding: const EdgeInsets.only(left: 14, top: 14, right: 10, bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.grain, size: 18, color: data.current.primaryLight),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5, bottom: 12),
                                          child: comfortatext("aerosol optical depth", 15, data.settings, color: data.current.onSurface),
                                        ),
                                      )
                                    ],
                                  ),
                                  const Spacer(),
                                  comfortatext(data.aqi.aod.toString(), 25, data.settings, color: data.current.primary, weight: FontWeight.w400),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2, top: 1),
                                    child: comfortatext("extremely clear", 15, data.settings, color: data.current.primary, weight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                      )
                    ],
                  ),

                   */



                      const SizedBox(height: 100,)

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
          padding: const EdgeInsets.only(bottom: 10),
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
              ],
            ),
          ),
        ),
        Wrap(
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
                  return data.current.containerLow;
                }),
                side: BorderSide(color: data.current.primaryLighter, width: 1.5),
                label: comfortatext(
                    ['pm2.5', 'pm10', 'o3', 'no2'][index], 14, data.settings,
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
    [0, 100, 200, 300, 400, 500]
  ];

  double valueMax = hourValues.reduce((a, b) => max<double>(a, b));
  int currentChart = 0;

  for (int i = 0; i < chartTypes.length; i++) {
    print((valueMax, chartTypes[i][5], name));
    if (valueMax * 1.3 > chartTypes[i][5]) { //because it looks weird if it is close to the top
      currentChart = min(i + 1, chartTypes.length - 1); //just for null safety
    }
  }

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
                children: List.generate(6, (index) {
                  return Row(
                    children: [
                      comfortatext(chartTypes[currentChart][5 - index].toString(), 14, data.settings,
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
                  maxAQI: chartTypes[currentChart][5],
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
          padding: const EdgeInsets.only(top: 5, bottom: 14),
          child: Visibility(
            visible: data.settings["Time mode"] == "24 hour",
            replacement: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3am", 14,data. settings, color: data.current.outline),
                  comfortatext("9am", 14, data.settings, color: data.current.outline),
                  comfortatext("3pm", 14, data.settings, color: data.current.outline),
                  comfortatext("9pm", 14, data.settings, color: data.current.outline),
                ]
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3:00", 14, data.settings, color: data.current.outline),
                  comfortatext("9:00", 14, data.settings, color: data.current.outline),
                  comfortatext("15:00", 14, data.settings, color: data.current.outline),
                  comfortatext("21:00", 14, data.settings, color: data.current.outline),
                ]
            ),
          )
      ),
    ],
  );
}
