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
      ..strokeWidth = 3.2;

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


class AQIGraphPainter extends CustomPainter {
  final List<double> aqiData;
  final double maxAQI;
  final Color color;

  AQIGraphPainter({required this.aqiData, required this.maxAQI, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

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
        return AqiMain(data, goBack, snapshot.data);
      },
    );
  }
}

Widget AqiMain(data, goBack, extendedAqi) {
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

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Icon(Icons.grain, size: 20, color: data.current.primaryLight),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: comfortatext("PM2.5", 16, data.settings, color: data.current.onSurface),
                      )
                    ]
                  ),
                ),

                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, right: 10),
                      child: SizedBox(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            comfortatext('60', 14, data.settings, color: data.current.onSurface),
                            comfortatext('40', 14, data.settings, color: data.current.onSurface),
                            comfortatext('20', 14, data.settings, color: data.current.onSurface),
                            comfortatext('0', 14, data.settings, color: data.current.onSurface),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: AQIGraphPainter(aqiData: extendedAqi.pm2_5_h, maxAQI: 60,
                            color: data.current.primaryLight),
                        child: const SizedBox(
                          height: 200.0,
                        ),
                      ),
                    ),
                  ],
                ),

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
}