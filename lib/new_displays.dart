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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:provider/provider.dart';

import 'alerts_page.dart';
import 'aqi_page.dart';
import '../l10n/app_localizations.dart';
import 'decoders/weather_data.dart';

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
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secondPaint = Paint()
      ..color = secondColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path();

    const amplitude = 2.15;
    const frequency = 21.0;
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

    path1.moveTo(splitPoint, size.height / 2 + 8);
    path1.lineTo(splitPoint, size.height / 2 - 8);

    final path2 = Path();

    for (double x = splitPoint; x <= size.width; x++) {
      final y = size.height / 2;
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

class ClockUpdater extends StatefulWidget {
  final int hourDiff;
  final double progress;
  final double width;

  const ClockUpdater({
    super.key,
    required this.hourDiff,
    required this.progress,
    required this.width,
  });

  @override
  State<ClockUpdater> createState() => _ClockUpdaterState();
}

class _ClockUpdaterState extends State<ClockUpdater> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startAlignedTimer();
  }

  void _startAlignedTimer() {
    final now = DateTime.now();

    //make a timer that will update every minute to show the local time

    final delay = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );

    _timer = Timer(delay, () {
      if (mounted) {
        setState(() {});
      }

      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime localTime = now.add(Duration(hours: widget.hourDiff));
    String write = convertTime(localTime, context);

    final textPainter = TextPainter(
        text: TextSpan(text: write, style: const TextStyle(fontSize: 15)),
        textDirection: TextDirection.ltr);
    textPainter.layout();
    final textWidth = textPainter.width * 1.1;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: widget.progress,
      ),

      curve: Curves.easeInOut,

      duration: const Duration(milliseconds: 600),

      builder: (context, currentScale, child) {
        return Padding(
          padding: EdgeInsets.only(
              left: min(
                  max((currentScale * (widget.width - 53)) - textWidth / 2 + 5, 0),
                  widget.width - 53 - textWidth)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(write, style: TextStyle(fontSize: 15, )),
          ),
        );
      },
    );
  }
}

class NewSunriseSunset extends StatefulWidget {
  final WeatherData data;
  final width;

  const NewSunriseSunset({super.key, required this.data, required this.width});

  @override
  State<NewSunriseSunset> createState() => _NewSunriseSunsetState();
}

class _NewSunriseSunsetState extends State<NewSunriseSunset> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentTime = DateTime.now();

    final localtimeOld = widget.data.localTime;

    int hourDiff = localtimeOld.hour - currentTime.hour;

    final double targetProgress = widget.data.sunStatus.sunstatus;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetProgress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,

      builder: (context, animatedProgress, child) {

        return Padding(
          padding: const EdgeInsets.only(left: 25, right: 25, bottom: 22, top: 15),
          child: Column(
            children: [

              ClockUpdater(hourDiff: hourDiff, progress: targetProgress, width: widget.width),

              Padding(
                padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 13),
                child: SizedBox(
                  width: double.infinity,
                  height: 8.0,
                  child: WaveTicker(
                    currentWaveProgress: animatedProgress,
                    child: Container(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 1),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 14,
                      ),
                    ),
                    Text(convertTime(widget.data.sunStatus.sunrise, context),
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.tertiary),),
                    const Spacer(),
                    Text(convertTime(widget.data.sunStatus.sunset, context),
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.secondary),),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 1),
                      child: Icon(Icons.nightlight_outlined,
                          color: Theme.of(context).colorScheme.secondary, size: 14),
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

class WaveTicker extends StatefulWidget {
  final Widget child;
  final double currentWaveProgress;

  const WaveTicker({
    super.key,
    required this.child,
    required this.currentWaveProgress,
  });

  @override
  State<WaveTicker> createState() => _WaveTickerState();
}

class _WaveTickerState extends State<WaveTicker> with SingleTickerProviderStateMixin {
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
          painter: WavePainter(
              _controller.value,
              Theme.of(context).colorScheme.tertiary,
              Theme.of(context).colorScheme.tertiaryContainer,
              widget.currentWaveProgress
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class AqiWidget extends StatelessWidget {
  final WeatherData data;
  final bool isTabletMode;

  const AqiWidget({super.key, required this.data, required this.isTabletMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 15),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.airQualityLowercase,
              style: const TextStyle(fontSize: 17),)
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: (){
            HapticFeedback.lightImpact();
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllergensPage(data: data, isTabletMode: isTabletMode,))
            );
          },
          child: Container(
            padding: const EdgeInsets.all(22),
            margin: const EdgeInsets.only(left: 25, right: 25, top: 14, bottom: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2)
            ),
            child: Row(
              children: [
                const SizedBox(width: 2,),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/m3shapes/9_sided_cookie.svg",
                      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondaryContainer, BlendMode.srcIn),
                      width: 88,
                      height: 88,
                    ),
                    Text(
                      data.aqi.aqiIndex.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aqiTitleLocalization(data.aqi.aqiIndex, AppLocalizations.of(context)!),
                        style: TextStyle( color: Theme.of(context).colorScheme.secondary, fontSize: 18,
                        fontWeight: FontWeight.w600, height: 1.1),),
                      const SizedBox(height: 7,),
                      Text(aqiDescLocalization(data.aqi.aqiIndex, AppLocalizations.of(context)!),
                        style: TextStyle( color: Theme.of(context).colorScheme.outline, fontSize: 14, height: 1.1),)
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllergensPage(data: data, isTabletMode: isTabletMode,))
                    );
                  },
                  icon: Icon(Icons.keyboard_arrow_right_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24,),
                ),
              ],
            ),

          ),
        ),
      ],
    );
  }
}

class AlertWidget extends StatelessWidget {
  final WeatherData data;

  const AlertWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.alerts.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.only(
              left: 25, right: 25, bottom: 10, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Text(AppLocalizations.of(context)!.alertsLowercase,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17),),
              ),
              Column(
                children: List.generate(data.alerts.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
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
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.only(left: 7, right: 7, top: 6, bottom: 8),
                                child: Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error)
                            ),
                            const SizedBox(width: 20,),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(data.alerts[index].event, style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface, fontSize: 18, height: 1.2
                                    ),),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "${convertToWeekDayTime(data.alerts[index].start, context)} - ${convertToWeekDayTime(data.alerts[index].end, context)}",
                                        style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),)
                                  )
                                ],
                              ),
                            ),
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

}

class Rain15MinuteChart extends StatelessWidget {
  final WeatherData data;

  const Rain15MinuteChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    String text = getRain15MinuteLocalization(data.minutely15Precip.text,
        data.minutely15Precip.timeTo, AppLocalizations.of(context)!);

    if (data.minutely15Precip.text != "") {
      return Container(
        margin: const EdgeInsets.only(left: 23, right: 23, top: 15, bottom: 30),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.umbrella, size: 18, color: Theme.of(context).colorScheme.primary)
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        unitConversion(data.minutely15Precip.precipSumMm,
                            context.select((SettingsProvider p) => p.getPrecipUnit)).toString(),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, height: 1.2),
                      ),
                      Text(
                        context.select((SettingsProvider p) => p.getPrecipUnit),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary,
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              text,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.44),
                            )
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
              child: SizedBox(
                height: 41,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(data.minutely15Precip.precipListMm.length, (int index)  {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 1, right: 1),
                          child: Container(
                            //i'm doing this because otherwise you wouldn't be
                            // able to tell the 0mm rain apart from the 0.1mm, or just low values in general
                            height: data.minutely15Precip.precipListMm[index] == 0 ?
                            5 : 6.0 + data.minutely15Precip.precipListMm[index] * 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: data.minutely15Precip.precipListMm[index] == 0 ?
                              Theme.of(context).colorScheme.outlineVariant : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.now,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),),
                  Text('3${AppLocalizations.of(context)!.hr}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),),
                  Text('6${AppLocalizations.of(context)!.hr}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),)
                ],
              ),
            )
          ],
        ),
      );
    }
    return Container();
  }

}