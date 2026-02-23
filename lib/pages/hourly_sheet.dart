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
import 'package:flutter_svg/svg.dart';
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../services/preferences_service.dart';
import '../weather_refact.dart';


double transformToConcentrated(double delta, int span) {
  double absDelta = delta.abs();
  double fisheye = pow(absDelta, 0.75).toDouble();
  double exitBoost = pow((absDelta - 0.8) / span, 8).toDouble() * span;
  double result = fisheye + exitBoost;
  return result * delta.sign;
}

class CustomTempChartPainter extends CustomPainter {
  final Color lineColor;
  final Color circleColor;
  final List<WeatherHour> hours;

  final double maxTemp;
  final double minTemp;

  final double index;

  CustomTempChartPainter({
    required this.lineColor,
    required this.circleColor,
    required this.hours,
    required this.index,
    required this.maxTemp,
    required this.minTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final Paint circlePaint = Paint()
      ..color = circleColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    const double pointRadius = 5.0;
    const int span = 5;

    final double centerX = size.width / 2;
    final double w = size.width * 0.13;

    final List<Offset> points = [];

    final int startI = (index - span - 1).floor().clamp(0, hours.length - 1);
    final int endI = (index + span + 3).floor().clamp(0, hours.length);

    for (int i = startI; i < endI; i++) {
      double closeness = transformToConcentrated(i - index, span);

      double x = centerX + closeness * w;

      double normalizedTemp = (hours[i].tempC - minTemp) / (maxTemp - minTemp);

      double y = (1 - normalizedTemp) * size.height;
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length; i++) {
      final Offset currentPoint = points[i];

      if (i > 0) {
        final Offset previousPoint = points[i - 1];

        final double dx = currentPoint.dx - previousPoint.dx;
        final double dy = currentPoint.dy - previousPoint.dy;

        final double distance = sqrt(dx * dx + dy * dy);

        if (distance > 2 * pointRadius) {
          final double unitDx = dx / distance;
          final double unitDy = dy / distance;

          final double startX = previousPoint.dx + unitDx * pointRadius;
          final double startY = previousPoint.dy + unitDy * pointRadius;

          final double endX = currentPoint.dx - unitDx * pointRadius;
          final double endY = currentPoint.dy - unitDy * pointRadius;

          path.moveTo(startX, startY);
          path.lineTo(endX, endY);
        }
      }
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, pointRadius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomTempChartPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.hours != hours;
  }
}


class HourlyBottomSheet extends StatefulWidget {
  final int initialIndex;
  final List<WeatherHour> hours;

  HourlyBottomSheet({Key? key, required this.initialIndex, required this.hours}) : super(key: key);

  @override
  _HourlyBottomSheetState createState() => _HourlyBottomSheetState(hours: hours, index: initialIndex);
}

class _HourlyBottomSheetState extends State<HourlyBottomSheet> {
  final List<WeatherHour> hours;
  int index;

  double minTemp = 100;
  double maxTemp = -100;

  _HourlyBottomSheetState({required this.hours, required this.index});

  @override
  void initState() {
    super.initState();
    for (WeatherHour hour in hours) {
      minTemp = min(minTemp, hour.tempC);
      maxTemp = max(maxTemp, hour.tempC);
    }
  }

  void changeIndex(int by) {
    setState(() {
      index = max(0, min(hours.length - 1, index + by));
    });
  }

  @override
  Widget build(BuildContext context) {

    WeatherHour hour = hours[index];

    return DraggableScrollableSheet(
      snap: true,
      snapSizes: const [0.6, 1.0],
      initialChildSize: 0.6,
      minChildSize: 0.25,
      maxChildSize: 1.0,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 40),
                  child: Text(convertTime(hour.time, context)),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 13, bottom: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.outlined(
                        onPressed: () {
                          changeIndex(-1);
                        },
                        icon: Icon(Icons.keyboard_arrow_left_outlined, color: Theme.of(context).colorScheme.onSurface,),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/m3shapes/4_sided_cookie.svg",
                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondaryContainer, BlendMode.srcIn),
                            width: 160,
                            height: 160,
                          ),
                          SvgPicture.asset(
                            weatherIconPathMap[hour.condition] ?? "assets/weather_icons/clear_sky.svg",
                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                            width: 80,
                            height: 80,
                          )
                        ],
                      ),
                      IconButton.outlined(
                          onPressed: () {
                            changeIndex(1);
                          },
                          icon: Icon(Icons.keyboard_arrow_right_outlined, color: Theme.of(context).colorScheme.onSurface,)
                      ),
                    ],
                  ),
                ),

                Text(conditionTranslation(hour.condition, AppLocalizations.of(context)!) ?? "Clear Sky",
                  style: const TextStyle(fontSize: 20),),

                const SizedBox(height: 50,),

                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: index.toDouble()),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) {
                    return CustomPaint(
                      size: const Size(double.infinity, 150),
                      painter: CustomTempChartPainter(
                        lineColor: Theme.of(context).colorScheme.tertiaryContainer,
                        circleColor: Theme.of(context).colorScheme.tertiary,
                        hours: hours,
                        index: animatedValue,
                        minTemp: minTemp,
                        maxTemp: maxTemp,
                      ),
                    );
                  },
                )

                /*
                CustomPaint(
                  painter: CustomTempChartPainter(Theme.of(context).colorScheme.tertiaryContainer,
                      Theme.of(context).colorScheme.tertiary, hours, index),
                  child: SizedBox(
                    height: 200,
                    width: 300,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 50, left: 3),
                        child: Text(
                          "${unitConversion(hour.tempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )

                 */

              ],
            ),
          ),
        );
      },
    );
  }
}