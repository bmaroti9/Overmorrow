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

class WavePainter extends CustomPainter {
  final double waveValue;
  final Color color;
  double hihi;

  WavePainter(this.waveValue, this.color, this.hihi);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;


    final path = Path();

    final amplitude = 2.2;
    final frequency = 20.0;

    for (double x = 0; x <= hihi * size.width; x++) {
      final y = size.height / 2 + amplitude * sin((x / frequency * 2 * pi) + (waveValue * 2 * pi));
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class WavySlider extends StatefulWidget {
  final Color color;
  final data;

  @override
  const WavySlider({super.key, required this.color, required this.data});

  @override
  _WavySliderState createState() => _WavySliderState();
}

class _WavySliderState extends State<WavySlider> with SingleTickerProviderStateMixin {

  late DateTime riseDT;
  late int offset;
  late int total;

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
    offset = currentTime.difference(localtimeOld).inSeconds;

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

        final thisdif = DateTime.now().difference(riseDT).inSeconds - offset;
        final double progress = min(max(thisdif, 0) / total, 1);

        print(progress);

        return CustomPaint(
          painter: WavePainter(_controller.value, widget.color, progress),
          child: Container(
            width: double.infinity,
            height: 8.0,
          ),
        );
      },
    );
  }
}

Widget NewSunriseSunset(var data, ColorScheme palette) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
    child: WavySlider(color: palette.primaryFixedDim, data: data, key: Key(data.place),),
  );
}