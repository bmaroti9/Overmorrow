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
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/ui_helper.dart';

import 'aqi_page.dart';
import 'decoders/decode_OM.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          padding: const EdgeInsets.only(left: 25, right: 25, bottom: 13),
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
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AllergensPage(data: data))
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 0, left: 5),
                child: comfortatext(
                    AppLocalizations.of(context)!.airQualityLowercase,
                    16,
                    data.settings,
                    color: data.current.onSurface),
              ),
              const Spacer(),
              GestureDetector(
                  onTap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllergensPage(data: data))
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: SizedBox(
                        width: 40, height: 36,
                        child: Icon(Icons.keyboard_arrow_right, color: data.current.primary, size: 21,)),
                  )
              ),
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
                  width: 71,
                  height: 71,
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
                          color: data.settings["Color mode"] == "light2" ? data.current.primary : data.current.onSurface,
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
    ),
  );
}

Widget NewRain15MinuteIndicator(var data, context) {
  return Visibility(
    visible: data.minutely_15_precip.t_minus != "",
    child: Padding(
      padding: const EdgeInsets.only(left: 21, right: 21, bottom: 33, top: 13),
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
                      const EdgeInsets.only(left: 5, bottom: 2, right: 3, top: 1),
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
                  comfortatext(AppLocalizations.of(context)!.now, 13, data.settings, color: data.current.onSurface),
                  comfortatext('3${AppLocalizations.of(context)!.hr}', 13, data.settings, color: data.current.onSurface),
                  comfortatext('6${AppLocalizations.of(context)!.hr}', 13, data.settings, color: data.current.onSurface)
                ],
              ),
            )
          ],
        ),
      ),
    )
  );
}
