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
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/ui_helper.dart';

import 'decoders/decode_wapi.dart';

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
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secondPaint = Paint()
      ..color = secondColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final amplitude = 2.45;
    final frequency = 24.0;
    final splitPoint = hihi * size.width;

    for (double x = 0; x <= splitPoint; x++) {
      final y = size.height / 2 + amplitude * sin((x / frequency * 2 * pi) + (waveValue * 2 * pi));
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, firstPaint);

    path.reset();
    for (double x = splitPoint; x <= size.width; x++) {
      final y = size.height / 2 + amplitude * sin((x / frequency * 2 * pi) + (waveValue * 2 * pi));
      if (x == splitPoint) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, secondPaint);
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

  late DateTime riseDT;
  late int total;
  late int hourdif;

  late AnimationController _controller;

  @override
  void initState() {
    final List<String> absoluteSunriseSunset = widget.data.sunstatus.absoluteSunriseSunset.split('/');

    final List<String> absoluteRise = absoluteSunriseSunset[0].split(':');
    final List<String> absoluteSet = absoluteSunriseSunset[1].split(':');
    final List<String> absoluteLocalTime = widget.data.localtime.split(':');

    print(("riseSet", absoluteRise, absoluteSet, absoluteLocalTime));

    final currentTime = DateTime.now();
    riseDT = currentTime.copyWith(hour: int.parse(absoluteRise[0]), minute: int.parse(absoluteRise[1]));
    final setDT = currentTime.copyWith(hour: int.parse(absoluteSet[0]), minute: int.parse(absoluteSet[1]));

    final localtimeOld = currentTime.copyWith(hour: int.parse(absoluteLocalTime[0]), minute: int.parse(absoluteLocalTime[1]));

    hourdif = localtimeOld.hour - currentTime.hour;

    total = setDT.difference(riseDT).inSeconds;

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

        final thisdif = localTime.difference(riseDT).inSeconds;
        final double progress = min(max(thisdif / total, 0), 1);

        print((progress, thisdif, total));

        String write = widget.data.settings["Time mode"] == "24 hour"
            ? convertTime("${localTime.hour}:${localTime.minute} j") //the j is just added so when splitting
            : amPmTime("${localTime.hour}:${localTime.minute} j"); //it can grab the first item


        return Padding(
          padding: const EdgeInsets.only(left: 25, right: 25, top: 4),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: max(progress * (widget.size.width - 50), 0)), //because the width is 70
                child: Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    child: comfortatext(write, 15, widget.data.settings, color: widget.data.palette.primary),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: CustomPaint(
                  painter: WavePainter(_controller.value, widget.data.palette.primaryFixedDim,
                      widget.data.palette.surfaceContainerHigh, progress),
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
                    comfortatext(widget.data.sunstatus.sunrise, 15, widget.data.settings,
                        color: widget.data.palette.onSurface),
                    Spacer(),
                    comfortatext(widget.data.sunstatus.sunset, 15, widget.data.settings,
                        color: widget.data.palette.onSurface),
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