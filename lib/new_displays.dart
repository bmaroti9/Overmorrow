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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';

import 'decoders/decode_OM.dart';

class WavePainter extends CustomPainter {
  final double waveValue;
  final Color firstColor;
  final Color secondColor;
  final double hihi;

  WavePainter(this.waveValue, this.firstColor, this.secondColor, this.hihi);

  @override
  void paint(Canvas canvas, Size size) {
    final firstPaint = Paint()
      ..color = firstColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secondPaint = Paint()
      ..color = secondColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path();

    final amplitude = 2.45;
    final frequency = 24.0;
    final splitPoint = hihi * size.width;

    for (double x = 0; x <= splitPoint; x++) {
      final y = size.height / 2 +
          amplitude * sin((x / frequency * 2 * pi) + (waveValue * 2 * pi));
      if (x == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }

    final path2 = Path();

    for (double x = splitPoint; x <= size.width; x++) {
      final y = size.height / 2 +
          amplitude * sin((x / frequency * 2 * pi) + (waveValue * 2 * pi));
      if (x == splitPoint) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }

    canvas.drawPath(path2, secondPaint);
    canvas.drawPath(path1, firstPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class NewSunriseSunset extends StatefulWidget {
  final data;
  final size;

  @override
  const NewSunriseSunset({super.key, required this.data, required this.size});

  @override
  _NewSunriseSunsetState createState() => _NewSunriseSunsetState();
}

class _NewSunriseSunsetState extends State<NewSunriseSunset> with SingleTickerProviderStateMixin {
  late int hourdif;

  late AnimationController _controller;

  @override
  void initState() {
    final List<String> absoluteLocalTime = widget.data.localtime.split(':');

    final currentTime = DateTime.now();

    final localtimeOld = currentTime.copyWith(
        hour: int.parse(absoluteLocalTime[0]),
        minute: int.parse(absoluteLocalTime[1]));

    hourdif = localtimeOld.hour - currentTime.hour;

    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        DateTime now = DateTime.now();
        DateTime localTime = now.add(Duration(hours: hourdif));

        final double progress = widget.data.sunstatus.sunstatus;

        String write = widget.data.settings["Time mode"] == "24 hour"
            ? OMConvertTime(
                "j T${localTime.hour.toString().padLeft(2, "0")}:${localTime.minute.toString().padLeft(2, "0")}") //the j is just added so when splitting
            : OMamPmTime(
                "j T${localTime.hour}:${localTime.minute}"); //it can grab the second item

        //this is all so that the text will be right above the progress
        final textPainter = TextPainter(
            text: TextSpan(
              text: write,
              style: GoogleFonts.comfortaa(
                  fontSize:
                      15.0 * getFontSize(widget.data.settings["Font size"]),
                  fontWeight: FontWeight.w500),
            ),
            textDirection: TextDirection.ltr);
        textPainter.layout();

        final textWidth = textPainter.width;

        return Padding(
          padding: const EdgeInsets.only(left: 25, right: 25, bottom: 11),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: min(
                        max((progress * (widget.size.width - 53)) - textWidth / 2 + 2, 0),
                        widget.size.width - 55 - textWidth)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: comfortatext(write, 15, widget.data.settings,
                      color: widget.data.current.onSurface,
                      weight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: 6,
                    left: min(max((progress * (widget.size.width - 53)), 2),
                        widget.size.width - 52)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.data.current.primarySecond,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 5),
                child: CustomPaint(
                  painter: WavePainter(
                      _controller.value,
                      widget.data.current.primarySecond,
                      darken(widget.data.current.surfaceVariant, 0.03),
                      progress),
                  child: Container(
                    width: double.infinity,
                    height: 8.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: widget.data.current.primarySecond,
                        size: 14,
                      ),
                    ),
                    comfortatext(
                        widget.data.sunstatus.sunrise, 15, widget.data.settings,
                        color: widget.data.current.primarySecond,
                        weight: FontWeight.w500),
                    const Spacer(),
                    comfortatext(
                        widget.data.sunstatus.sunset, 15, widget.data.settings,
                        color: widget.data.current.outline,
                        weight: FontWeight.w500),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.nightlight_outlined,
                          color: widget.data.current.outline, size: 14),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

Widget NewAirQuality(var data, context) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 59),
    child: Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0, left: 5),
              child: comfortatext(
                  translation('air quality', data.settings["Language"]),
                  16,
                  data.settings,
                  color: data.current.onSurface),
            ),
            const Spacer(),
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.only(top:2),
              onPressed: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllergensPage(data: data))
                );
              },
              icon: Icon(Icons.keyboard_arrow_right, color: data.current.primary, size: 20,))
          ],
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 0, right: 14),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: data.current.containerLow),
                width: 65,
                height: 65,
                child: Center(
                    child: comfortatext(
                        data.aqi.aqi_index.toString(), 32, data.settings,
                        color: data.current.primarySecond)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: comfortatext(
                      data.aqi.aqi_title, 19, data.settings, color: data.current.primarySecond, align: TextAlign.left,
                      weight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 2),
                    child: comfortatext(data.aqi.aqi_desc, 14, data.settings,
                        color: data.settings["Color mode"] == "light" ? data.current.primary : data.current.onSurface,
                        weight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15, left: 14, right: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NewAqiDataPoints("PM2.5", data.aqi.pm2_5, data),
              NewAqiDataPoints("PM10", data.aqi.pm10, data),
              NewAqiDataPoints("O3", data.aqi.o3, data),
              NewAqiDataPoints("NO2", data.aqi.no2, data),
            ],
          ),
        )
      ],
    ),
  );
}

Widget NewRain15MinuteIndicator(var data) {
  return Visibility(
    visible: data.minutely_15_precip.t_minus != "",
    child: Padding(
      padding: const EdgeInsets.only(left: 21, right: 21, bottom: 38),
      child: Container(
        decoration: BoxDecoration(
          color: data.current.containerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 5, bottom: 2, right: 3),
                  child: Icon(
                    Icons.water_drop_outlined,
                    color: data.current.primary,
                    size: 20,
                  ),
                ),
                comfortatext(data.minutely_15_precip.precip_sum.toStringAsFixed(1),
                    20, data.settings,
                    color: data.current.primary, weight: FontWeight.w500),
                comfortatext(
                    data.settings["Precipitation"], 20, data.settings,
                    color: data.current.primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: comfortatext(
                        data.minutely_15_precip.t_minus,
                        14,
                        data.settings,
                        color: data.current.onSurface, weight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: SizedBox(
                height: 30,
                child: ListView.builder(
                  itemExtent: 11,
                  scrollDirection: Axis.horizontal,
                  itemCount: data.minutely_15_precip.precips.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return Center(
                      child: Container(
                        width: 3.5,
                        height: 3.5 + data.minutely_15_precip.precips[index] * 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: data.minutely_15_precip.precips[index] == 0
                              ? data.current.primaryLight : data.current.primary,
                        ),
                      ),
                    );
                  }
                )
              ),
            ),
            SizedBox(
              width: 11.0 * data.minutely_15_precip.precips.length + 11,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  comfortatext(translation('now', data.settings["Language"]), 13, data.settings, color: data.current.onSurface),
                  comfortatext('3${translation("hr", data.settings["Language"])}', 13, data.settings, color: data.current.onSurface),
                  comfortatext('6${translation("hr", data.settings["Language"])}', 13, data.settings, color: data.current.onSurface)
                ],
              ),
            )
          ],
        ),
      ),
    )
  );
}

class SquigglyCirclePainter extends CustomPainter {

  final Color circleColor;

  SquigglyCirclePainter(this.circleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
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
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, top:10, bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 22, color: data.current.primaryLight),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: comfortatext(name, 20, data.settings, color: data.current.primary),
        ),
        const Spacer(),
        comfortatext(value.toString(), 20, data.settings, color: data.current.primaryLight),
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
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 55, right: 55, top: 50, bottom: 30),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CustomPaint(
                        painter: SquigglyCirclePainter(data.current.primaryLight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: comfortatext("1", 63, data.settings, color: data.current.primary, weight: FontWeight.w300),
                            ),
                            comfortatext("good", 25, data.settings, color: data.current.primary, weight: FontWeight.w600),
                            ],
                          ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: comfortatext(data.aqi.aqi_desc, 18, data.settings, color: data.current.primarySecond, weight: FontWeight.w600, align: TextAlign.center),
                  ),

                  GridView.count(
                    primary: false,
                    padding: const EdgeInsets.all(20),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 3,
                    childAspectRatio: 5,
                    shrinkWrap: true,
                    children: [
                      NewAqiDataPoints("PM2.5", data.aqi.pm2_5, data, 19.0),
                      NewAqiDataPoints("PM10", data.aqi.pm10, data, 19.0),
                      NewAqiDataPoints("O3", data.aqi.o3, data, 19.0),
                      NewAqiDataPoints("NO2", data.aqi.no2, data, 19.0),
                      NewAqiDataPoints("CO", data.aqi.co, data, 19.0),
                      NewAqiDataPoints("SO2", data.aqi.so2, data, 19.0),
                    ]
                  ),

                  const SizedBox(height: 30),


                  pollenWidget(CupertinoIcons.tree, "Alder Pollen", data.aqi.alder, data),
                  pollenWidget(Icons.eco_outlined, "Birch Pollen", data.aqi.birch, data),
                  pollenWidget(Icons.grass_outlined, "Grass Pollen", data.aqi.grass, data),
                  pollenWidget(Icons.local_florist_outlined, "Mugwort Pollen", data.aqi.mugwort, data),
                  pollenWidget(Icons.park_outlined, "Olive Pollen", data.aqi.olive, data),
                  pollenWidget(Icons.grain_outlined, "Ragweed Pollen", data.aqi.ragweed, data),

                  const SizedBox(height: 100)

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}