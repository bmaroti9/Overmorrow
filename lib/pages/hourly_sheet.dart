/*
Copyright (C) <2026>  <Balint Maroti>

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
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../services/preferences_service.dart';
import '../weather_refact.dart';


double transformToConcentrated(double delta, int span) {
  double absDelta = delta.abs();
  double fisheye = pow(absDelta, 0.9).toDouble();
  double exitBoost = pow((absDelta - 0.25) / span, 20).toDouble() * span;
  double result = fisheye + exitBoost;
  return result * delta.sign;
}

double interpolateWindDir(List<WeatherHour> hours, double index) {
  int lower = index.floor().clamp(0, hours.length - 1);
  int upper = index.ceil().clamp(0, hours.length - 1);
  double t = index - lower;

  int a = hours[lower].windDirA ?? 0;
  int b = hours[upper].windDirA ?? 0;

  if ((a - b).abs() <= 180) {
    return lerpDouble(a, b, t) ?? 0;
  } else {
    return lerpDouble(a + (b - a).sign * 360, b, t) ?? 0;
  }
}

double interpolatePrecipProb(List<WeatherHour> hours, double index) {
  int lower = index.floor().clamp(0, hours.length - 1);
  int upper = index.ceil().clamp(0, hours.length - 1);
  double t = index - lower;

  int a = hours[lower].precipProb ?? 0;
  int b = hours[upper].precipProb ?? 0;

  return lerpDouble(a, b, t) ?? 0;
}

String localizeWindDir(AppLocalizations localizations, int? windDirA) {
  if (windDirA == null) return "--";
  final List<String> directions = [
    localizations.north,
    localizations.northEast,
    localizations.east,
    localizations.southEast,
    localizations.south,
    localizations.southWest,
    localizations.west,
    localizations.northWest,
  ];

  int index = ((windDirA + 22.5) / 45).floor() % 8;
  return directions[index];
}

class CustomTempChartPainter extends CustomPainter {
  final Color chipColor;
  final List<WeatherHour> hours;
  final TextPainter textPainter;
  final BuildContext context;

  final double maxTemp;
  final double minTemp;

  final double index;

  CustomTempChartPainter({
    required this.context,
    required this.chipColor,
    required this.hours,
    required this.index,
    required this.maxTemp,
    required this.minTemp,
    required this.textPainter,
  });

  double getHeightFromTemp(double temp, Size size,) {
    double normalized = (temp - minTemp) / (maxTemp - minTemp);
    return (1 - normalized) * size.height;
  }

  double getInterpolatedY(double idx, Size size) {
    int lower = idx.floor().clamp(0, hours.length - 1);
    int upper = idx.ceil().clamp(0, hours.length - 1);
    double t = idx - lower;

    double yLow = getHeightFromTemp(hours[lower].tempC, size);
    double yHigh = getHeightFromTemp(hours[upper].tempC, size);

    return yLow + (yHigh - yLow) * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Theme.of(context).colorScheme.tertiaryContainer
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final Paint outlinePaint = Paint()
      ..color = Theme.of(context).colorScheme.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final Paint circlePaint = Paint()
      ..color = Theme.of(context).colorScheme.tertiary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    const double pointRadius = 5.0;
    const int span = 6;

    final double centerX = size.width / 2;
    final double w = size.width * 0.08;

    final List<Offset> points = [];

    final int startI = (index - span - 1).floor().clamp(0, hours.length - 1);
    final int endI = (index + span + 3).floor().clamp(0, hours.length);

    for (int i = startI; i < endI; i++) {
      double closeness = transformToConcentrated(i - index, span);

      double x = centerX + closeness * w;

      double y = getHeightFromTemp(hours[i].tempC, size);
      points.add(Offset(x, y));

      if (hours[i].time.hour % 6 == 0) {
        final timePainter = TextPainter(
          text: TextSpan(
            text: "${hours[i].time.hour}",
            style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        timePainter.paint(canvas, Offset(x - timePainter.width / 2, size.height + 12));
      }
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
      canvas.drawLine(Offset(point.dx, -10), Offset(point.dx, point.dy - pointRadius - 10), outlinePaint);
      canvas.drawLine(Offset(point.dx, point.dy + pointRadius + 10), Offset(point.dx, size.height + 10), outlinePaint);
    }

    final double smoothY = getInterpolatedY(index, size);

    final Rect topRect = Rect.fromLTWH(
      centerX - 18,
      smoothY - 58,
      36,
      36
    );

    canvas.drawRRect(
        RRect.fromRectAndRadius(topRect, const Radius.circular(30)),
        Paint()..color = chipColor
    );

    final Path bottomPath = Path()
      ..moveTo(centerX - 11.5, topRect.bottom - 4)
      ..lineTo(centerX + 11.5, topRect.bottom - 4)
      ..lineTo(centerX, topRect.bottom + 5)
      ..close();

    canvas.drawPath(bottomPath, Paint()..color = chipColor);

    textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, smoothY - 50));
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
  _HourlyBottomSheetState createState() => _HourlyBottomSheetState(hours: hours, index: initialIndex.toDouble());
}

class _HourlyBottomSheetState extends State<HourlyBottomSheet> with SingleTickerProviderStateMixin {
  final List<WeatherHour> hours;

  double index = 0.0;

  final double _dragSensitivity = 50.0;

  double minTemp = 100;
  double maxTemp = -100;

  late AnimationController _controller;
  int _lastHapticIndex = -1;
  
  static const List<Color> uvLightPrimaryContainerColors =
      [Color(0xffc9eea7), Color(0xfff8e287), Color(0xffffdbc8), Color(0xffffdad4), Color(0xffffd7f5)];
  static const List<Color> uvLightPrimaryColors =
      [Color(0xff48672f), Color(0xff6d5e0f), Color(0xff8c4f27), Color(0xff904b40), Color(0xff804d79)];
  static const List<Color> uvDarkPrimaryContainerColors =
      [Color(0xff314e19), Color(0xff534600), Color(0xff6f3810), Color(0xff73342a), Color(0xff653660)];
  static const List<Color> uvDarkPrimaryColors =
      [Color(0xffaed18d), Color(0xffdbc66f), Color(0xffffb68c), Color(0xffffb4a8), Color(0xfff1b3e6)];

  @override
  void initState() {
    super.initState();

    for (WeatherHour hour in hours) {
      minTemp = min(minTemp, hour.tempC);
      maxTemp = max(maxTemp, hour.tempC);
    }

    _controller = AnimationController.unbounded(
        value: index,
        vsync: this
    );

    _controller.addListener(() {
      int rounded = _controller.value.round();
      if (rounded != _lastHapticIndex && (rounded - _controller.value).abs() < 0.2) {
        HapticFeedback.selectionClick();
        _lastHapticIndex = rounded;
      }

      double clampedValue = _controller.value.clamp(0.0, hours.length - 1.0);

      if (_controller.value != clampedValue) {
        _controller.value = clampedValue;
        _controller.stop();
      }

      setState(() {
        index = _controller.value;
      });
    });
  }

  void changeIndex(int by) {
    double target = (index + by).clamp(0.0, hours.length - 1.0);
    _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut
    );
  }

  _HourlyBottomSheetState({required this.hours, required this.index});

  @override
  Widget build(BuildContext context) {

    WeatherHour hour = hours[index.round()];
    double precipProb = interpolatePrecipProb(hours, index) / 100;

    String mode = context.watch<ThemeProvider>().getBrightness;

    if (mode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      mode = brightness == Brightness.dark ? "dark" : "light";
    }

    final List<Color> uvSelectedColors = mode == "light" ? uvLightPrimaryColors : uvDarkPrimaryColors;
    final List<Color> uvUnSelectedColors = mode == "light" ? uvLightPrimaryContainerColors : uvDarkPrimaryContainerColors;

    return DraggableScrollableSheet(
      snap: true,
      snapSizes: const [0.65, 1.0],
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

                /*
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(convertTime(hour.time, context)),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 15),
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
                            width: 155,
                            height: 155,
                          ),
                          SvgPicture.asset(
                            weatherIconPathMap[hour.condition] ?? "assets/weather_icons/clear_sky.svg",
                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                            width: 75,
                            height: 75,
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

                 */

                const SizedBox(height: 70,),

                //const SizedBox(height: 80,),

                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Stack(
                            children: [
                              Transform.rotate(
                                angle: interpolateWindDir(hours, index) / 180 * math.pi,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 25),
                                  child: SvgPicture.asset(
                                    "assets/m3shapes/arrow.svg",
                                    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondaryContainer, BlendMode.srcIn),
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.air, size: 20,),
                                        const SizedBox(width: 3,),
                                        Text(AppLocalizations.of(context)!.windCapital, style: const TextStyle(fontSize: 15),)
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            '${unitConversion(hour.windKmh,
                                            context.select((SettingsProvider p) => p.getWindUnit), decimals: 0)}',
                                          style: TextStyle(fontSize: 40, height: 1.12, color: Theme.of(context).colorScheme.primary),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(context.select((SettingsProvider p) => p.getWindUnit), style: const TextStyle(fontSize: 20),),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Text(
                                        localizeWindDir(AppLocalizations.of(context)!, hour.windDirA),
                                        style: const TextStyle(fontSize: 15),
                                      )
                                    ),
                                  )
                                ]
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20,),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: precipProb,
                                    child: Container(
                                      color: Theme.of(context).colorScheme.tertiaryContainer,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.water_drop_outlined, size: 19,),
                                                const SizedBox(width: 3,),
                                                Expanded(child: Text(AppLocalizations.of(context)!.precipCapital, style: const TextStyle(fontSize: 15),))
                                              ],
                                            ),
                                            const Spacer(),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${unitConversion(hour.precipMm,
                                                      context.select((SettingsProvider p) => p.getPrecipUnit), decimals: 1)}',
                                                  style: TextStyle(fontSize: 40, height: 1.0, color: Theme.of(context).colorScheme.tertiary),
                                                ),
                                                Text(context.select((SettingsProvider p) => p.getPrecipUnit),
                                                  style: const TextStyle(fontSize: 20, height: 1.0),),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        const double approxTextHeight = 20;
                                        return Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              bottom: (constraints.maxHeight * precipProb - approxTextHeight / 2)
                                                  .clamp(20 - approxTextHeight / 2, constraints.maxHeight - 16 - approxTextHeight / 2)
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "${hour.precipProb}%",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_right_outlined, size: 20,)
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16, bottom: 20, top: 20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(6, (int index) {
                                          return Container(
                                            width: 5,
                                            height: 1,
                                            margin: const EdgeInsets.only(left: 6),
                                            color: Theme.of(context).colorScheme.onSurface,
                                          );
                                        }),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20,),

                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              "assets/m3shapes/12_sided_cookie.svg",
                              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.surfaceContainer, BlendMode.srcIn),
                              width: double.infinity,
                              height: double.infinity,
                            ),

                            ...List.generate(5, (i) {
                              double angle = (5 - i) / 12 * 2 * pi;
                              bool selected = i == hour.uv;

                              return Align(
                                alignment: Alignment(cos(angle) * 0.85, sin(angle) * 0.85),
                                child: Container(
                                  width: selected ? 16 : 13,
                                  height: selected ? 16 : 13,
                                  decoration: BoxDecoration(
                                    color: selected ? uvSelectedColors[i] : uvUnSelectedColors[i],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }),

                            Column(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, size: 20,),
                                      const SizedBox(width: 3,),
                                      Text(AppLocalizations.of(context)!.uvCapital, style: const TextStyle(fontSize: 15),)
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    hour.uv?.toString() ?? "--",
                                    style: TextStyle(fontSize: 40, height: 1.12, color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                const Expanded(
                                  flex: 4,
                                  child: Text(
                                    "low",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                )
                              ]
                            )
                          ],
                        )
                      ),
                    ),
                    const SizedBox(width: 20,),
                    Expanded(
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          )
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100,),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    _controller.stop();
                    _controller.value = (_controller.value - details.primaryDelta! / _dragSensitivity)
                        .clamp(0.0, hours.length - 1.0);
                  },
                  onHorizontalDragEnd: (details) {
                    final double velocity = -details.primaryVelocity! / _dragSensitivity;
                    final simulation = FrictionSimulation(0.135, _controller.value, velocity,
                        tolerance: const Tolerance(velocity: 0.2, distance: 0.01));

                    _controller.animateWith(simulation).then((_) {
                      _controller.animateTo(
                          _controller.value.roundToDouble(),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut
                      );
                    });
                  },
                  child: CustomPaint(
                    size: const Size(double.infinity, 170),
                    painter: CustomTempChartPainter(
                      context: context,
                      chipColor: Theme.of(context).colorScheme.inverseSurface,
                      hours: hours,
                      index: index,
                      minTemp: minTemp,
                      maxTemp: maxTemp,
                      textPainter: TextPainter(
                        text: TextSpan(
                          text: "${unitConversion(hour.tempC, context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onInverseSurface,
                            fontSize: 17,
                            fontFamily: GoogleFonts.outfit().fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                      )..layout()
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}