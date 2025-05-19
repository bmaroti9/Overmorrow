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
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/ui_helper.dart';

import 'alerts_page.dart';
import 'aqi_page.dart';
import 'decoders/decode_OM.dart';
import '../l10n/app_localizations.dart';

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

    const amplitude = 2.45;
    const frequency = 24.0;
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
    ColorScheme palette = widget.data.current.palette;
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
              style: GoogleFonts.outfit(
                  fontSize:
                      15.0 * 1.1 * getFontSize(widget.data.settings["Font size"]),
                  fontWeight: FontWeight.w300),
            ),
            textDirection: TextDirection.ltr);
        textPainter.layout();

        final textWidth = textPainter.width * 1.1;

        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 23, top: 13),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: min(
                        max((progress * (widget.size.width - 53)) - textWidth / 2  + 4, 0),
                        widget.size.width - 53 - textWidth)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: comfortatext(write, 15, widget.data.settings,
                      color: palette.onSurface),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: 6,
                    left: min(max((progress * (widget.size.width - 56)), 2),
                        widget.size.width - 56)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: palette.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 7),
                child: CustomPaint(
                  painter: WavePainter(
                      _controller.value,
                      palette.secondary,
                      palette.surfaceContainerHighest,
                      progress),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 8.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: palette.secondary,
                        size: 13,
                      ),
                    ),
                    comfortatext(
                        widget.data.sunstatus.sunrise, 15, widget.data.settings,
                        color: palette.secondary,
                        weight: FontWeight.w400),
                    const Spacer(),
                    comfortatext(
                        widget.data.sunstatus.sunset, 15, widget.data.settings,
                        color: palette.outline,
                        weight: FontWeight.w400),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Icon(Icons.nightlight_outlined,
                          color: palette.outline, size: 13),
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
        HapticFeedback.lightImpact();
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
                  child: SizedBox(
                      width: 40, height: 36,
                      child: Icon(Icons.keyboard_arrow_right, color: data.current.primary, size: 21,))
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

Widget AqiWidget(var data, ColorScheme palette, context) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 25, top: 15),
        child: Align(
          alignment: Alignment.centerLeft,
          child: comfortatext(
            AppLocalizations.of(context)!.airQualityLowercase, 17,
            data.settings,
            color: palette.onSurface
          ),
        ),
      ),
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: (){
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllergensPage(data: data))
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(left: 25, right: 25, top: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: palette.outlineVariant, width: 2)
          ),
          child: Row(
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: palette.secondaryContainer,
                ),
                margin: const EdgeInsets.only(right: 20),
                child: Center(
                    child: comfortatext(data.aqi.aqi_index.toString(), 24, data.settings,
                        color: palette.onSecondaryContainer)
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    comfortatext(
                      data.aqi.aqi_title, 19, data.settings, color: palette.secondary, align: TextAlign.left,
                      weight: FontWeight.w500,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 0),
                      child: comfortatext(data.aqi.aqi_desc, 14, data.settings,
                          color: palette.outline,
                          weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllergensPage(data: data))
                  );
                },
                icon: Icon(Icons.keyboard_arrow_right_rounded, color: palette.primary,),
              ),
            ],
          ),

        ),
      ),
    ],
  );
}

Widget alertWidget(var data, context, ColorScheme palette) {
  if (data.alerts.length > 0) {
    return Padding(
        padding: const EdgeInsets.only(
            left: 21, right: 21, bottom: 25, top: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: comfortatext(
                  AppLocalizations.of(context)!.alertsLowercase, 17,
                  data.settings,
                  color: palette.onSurface),
            ),
            Column(
              children: List.generate(data.alerts.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AlertsPage(data: data))
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 25, top: 23, bottom: 23, right: 22),
                      decoration: BoxDecoration(
                        color: palette.secondaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, //first time i realised this makes it wrap the content size
                              children: [
                                Flexible(
                                  child: comfortatext(data.alerts[index].event, 20,
                                      data.settings, color: palette.secondary,),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: comfortatext("${data.alerts[index].start} - ${data.alerts[index].end}", 14, data.settings,
                                      color: palette.outline),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5, left: 20),
                            child: Icon(Icons.warning_amber_rounded, color: palette.primary, size: 28,),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        )
    );
  }
  return Container();
}

Widget rain15MinuteChart(var data, ColorScheme palette, context) {
  if (data.minutely_15_precip.t_minus != "") {
    return Container(
      margin: const EdgeInsets.only(left: 23, right: 23, top: 15, bottom: 30),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(33),
        color: palette.secondaryContainer,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding:
                const EdgeInsets.only(right: 3),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: palette.onSecondaryContainer,
                  size: 20,
                ),
              ),
              comfortatext(data.minutely_15_precip.precip_sum.toStringAsFixed(1),
                  19, data.settings,
                  color: palette.primary),
              comfortatext(
                  data.settings["Precipitation"], 16, data.settings,
                  color: palette.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: comfortatext(
                    data.minutely_15_precip.t_minus,
                    16,
                    data.settings,
                    color: palette.onSecondaryContainer),
                ),
              ),

            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 15, right: 15),
            child: SizedBox(
                height: 45,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: List<Widget>.generate( data.minutely_15_precip.precips.length, (int index)  {
                    return Container(
                      width: 4.5,
                      //i'm doing this because otherwise you wouldn't be
                      // able to tell the 0mm rain apart from the 0.1mm, or just low values in general
                      height: data.minutely_15_precip.precips[index] == 0 ?
                        4.5 : 8.0 + data.minutely_15_precip.precips[index] * 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: data.minutely_15_precip.precips[index] == 0 ?
                        palette.outline : palette.primary,
                      ),
                    );
                  }
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                comfortatext(AppLocalizations.of(context)!.now, 13, data.settings, color: palette.onSurfaceVariant),
                comfortatext('3${AppLocalizations.of(context)!.hr}', 13, data.settings, color: palette.onSurfaceVariant),
                comfortatext('6${AppLocalizations.of(context)!.hr}', 13, data.settings, color: palette.onSurfaceVariant)
              ],
            ),
          )
        ],
      ),
    );
  }
  return Container();
}
