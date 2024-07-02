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

  WavePainter(this.waveValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;


    final path = Path();

    final amplitude = 2.0;
    final frequency = 20.0;

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + amplitude * sin((x / size.width * frequency * 2 * pi) + (waveValue * 2 * pi));
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

  @override
  WavySlider(this.color);

  @override
  _WavySliderState createState() => _WavySliderState();
}

class _WavySliderState extends State<WavySlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
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
        return CustomPaint(
          painter: WavePainter(_controller.value, widget.color),
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
    padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
    child: WavySlider(palette.secondary),
  );
}