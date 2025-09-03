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

import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/services/weather_service.dart';

import '../l10n/app_localizations.dart';
import 'decoders/weather_data.dart';

class SquigglyCirclePainter extends CustomPainter {

  final Color circleColor;

  SquigglyCirclePainter(this.circleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final Path path = Path();
    double radius = size.width / 2;
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    double waves = 11;
    double waveAmplitude = size.width / 45;

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

Widget pollenWidget(IconData icon, String name, double value, WeatherData data, context) {
  const categoryBoundaries = [-1, 0, 20, 80, 200];
  const categoryNames = ["--", "none", "low", "medium", "high"];

  int categoryIndex = 0;
  for (int i = 0; i < categoryBoundaries.length; i++) {
    if (value >= categoryBoundaries[i]) {
      categoryIndex = i;
    }
  }

  String severity = categoryNames[categoryIndex];

  return Padding(
    padding: const EdgeInsets.only(top:5, bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.tertiary),
        Padding(
          padding: const EdgeInsets.only(left: 17),
          child: Text(name, style: const TextStyle(fontSize: 17),)
        ),
        const Spacer(),
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.tertiaryContainer
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            width: 75,
            child: Center(child: Text(severity, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 15)))
        ),
      ],
    ),
  );
}


class ThreeQuarterCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color secondColor;

  ThreeQuarterCirclePainter({required this.percentage, required this.color, required this.secondColor});

  @override
  void paint(Canvas canvas, Size size) {
    double angle = 2 * 3.14159265359 * (max(min(percentage, 100), 0) / 100) * 0.75; // 3 quarters of a circle

    // Background Circle
    Paint baseCircle = Paint()
      ..color = secondColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -3.14159265359 * 5 / 4 + angle + 0.38,
      3.14159265359 * 1.5 - angle - 0.38,
      false,
      baseCircle,
    );

    // Foreground Circle
    Paint progressCircle = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -3.14159265359 * 5 / 4,
      angle,
      false,
      progressCircle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

Widget pollutantWidget(WeatherData data, name, value, percent, context) {
  return Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: ThreeQuarterCirclePainter(percentage: percent, color: Theme.of(context).colorScheme.secondary,
                    secondColor: Theme.of(context).colorScheme.secondaryContainer),
                    child: Center(
                      child: Text(value.toString(), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600))
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(name, style: const TextStyle(fontSize: 14),),
      ],
    ),
  );
}

class AllergensPage extends StatefulWidget {
  final WeatherData data;
  final isTabletMode;

  const AllergensPage({Key? key, required this.data, required this.isTabletMode})
      : super(key: key);

  @override
  _AllergensPageState createState() =>
      _AllergensPageState();
}

class _AllergensPageState extends State<AllergensPage> {

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                goBack();
              },
            ),
            title: Text(AppLocalizations.of(context)!.airQuality,
               style: const TextStyle(fontSize: 30)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<OMExtendedAqi>(
              future: OMExtendedAqi.fromJson(widget.data.lat, widget.data.lng),
              builder: (BuildContext context,
                  AsyncSnapshot<OMExtendedAqi> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Theme.of(context).colorScheme.primaryContainer
                      ),
                      margin: const EdgeInsets.only(top: 130),
                      padding: const EdgeInsets.all(3),
                      width: 64,
                      height: 64,
                      child: const ExpressiveLoadingIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  if (kDebugMode) {
                    print((snapshot.error, snapshot.stackTrace));
                  }
                  //this was the best way i found to detect no wifi
                  if (snapshot.error.toString().contains("Socket")) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Icon(Icons.wifi_off_rounded, color: Theme.of(context).colorScheme.primary, size: 23,),
                          ),
                          const Text("no wifi connection", style: TextStyle(fontSize: 18))
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Icon(Icons.wifi_off_rounded, color: Theme.of(context).colorScheme.primary, size: 23,),
                        ),
                        const Text("no wifi connection", style: TextStyle(fontSize: 18)),
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Text("${snapshot.error} ${snapshot.stackTrace}",
                            style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 15))
                        )
                      ],
                    ),
                  );
                }
                final OMExtendedAqi extendedAqi = snapshot.data!;
                final highestAqi = extendedAqi.dailyAqi.reduce(max);

                if (widget.isTabletMode) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 25, right: 25),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  aqiCircleAndDesc(widget.data, context),
                                  pollenIndicators(widget.data, extendedAqi, context),
                                ],
                              )
                            ),
                            const SizedBox(width: 40,),
                            Expanded(
                              child: Column(
                                children: [
                                  NewHourlyAqi(data: widget.data, extendedAqi: extendedAqi),
                                  dailyAqi(widget.data, extendedAqi, context, highestAqi),
                                ],
                              )
                            ),
                            const SizedBox(width: 40,),
                            Expanded(
                                child: Column(
                                  children: [
                                    mainPollutantIndicator(widget.data, extendedAqi, context),
                                    pollutantIndicators(widget.data, extendedAqi, context),
                                    europeanAndUsAqi(widget.data, extendedAqi, context),
                                    const SizedBox(height: 10,),
                                    dustAndAODIndicators(widget.data, extendedAqi, context),
                                  ],
                                )
                            )
                          ],
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 70, bottom: 70),
                            child: Text(AppLocalizations.of(context)!.poweredByOpenMeteo, style: const TextStyle(fontSize: 16),)
                          ),
                        )
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 100.0,
                          child: FadeInAnimation(
                            child: widget,
                          ),
                        ),
                        children:[
                          aqiCircleAndDesc(widget.data, context),
                          mainPollutantIndicator(widget.data, extendedAqi, context),
                          pollenIndicators(widget.data, extendedAqi, context),
                          NewHourlyAqi(data: widget.data, extendedAqi: extendedAqi),
                          europeanAndUsAqi(widget.data, extendedAqi, context),
                          pollutantIndicators(widget.data, extendedAqi, context),
                          dailyAqi(widget.data, extendedAqi, context, highestAqi),
                          dustAndAODIndicators(widget.data, extendedAqi, context),

                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 70, bottom: 70),
                              child: Text(AppLocalizations.of(context)!.poweredByOpenMeteo,
                                style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 16),)
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget aqiCircleAndDesc(WeatherData data, context) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 25),
        child: FractionallySizedBox(
          widthFactor: 0.78,
          alignment: FractionalOffset.center,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: SquigglyCirclePainter(Theme.of(context).colorScheme.primaryFixedDim),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.aqi.aqiIndex.toString(),
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 65,
                        height: 1.2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(aqiTitleLocalization(data.aqi.aqiIndex, AppLocalizations.of(context)!), style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary, fontSize: 21, height: 1.2, fontWeight: FontWeight.w600),)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 30, left: 40, right: 40),
        child: Text(aqiDescLocalization(data.aqi.aqiIndex, AppLocalizations.of(context)!),
            textAlign: TextAlign.center,
            style: TextStyle(
            color: Theme.of(context).colorScheme.outline, fontSize: 18, height: 1.15)
        ),
      ),
    ],
  );
}

Widget mainPollutantIndicator(WeatherData data, extendedAqi, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 25, bottom: 3),
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(33),
      ),
      height: 67,
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Row(
        children: [
          Text(AppLocalizations.of(context)!.mainPollutant, style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 18)),
          const Spacer(),
          Text(extendedAqi.mainPollutant, style: TextStyle(
              color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 18))
        ],
      ),
    ),
  );
}

Widget pollenIndicators(WeatherData data, extendedAqi, context) {
  return  Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 15),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(33),
      ),
      padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 16),
      child: Column(
        children: [
          pollenWidget(Icons.forest_outlined,
              AppLocalizations.of(context)!.alderPollen, extendedAqi.alder, data, context),
          pollenWidget(Icons.eco_outlined,
              AppLocalizations.of(context)!.birchPollen, extendedAqi.birch, data, context),
          pollenWidget(Icons.grass_outlined,
              AppLocalizations.of(context)!.grassPollen, extendedAqi.grass, data, context),
          pollenWidget(Icons.local_florist_outlined,
              AppLocalizations.of(context)!.mugwortPollen, extendedAqi.mugwort, data, context),
          pollenWidget(Icons.park_outlined,
              AppLocalizations.of(context)!.olivePollen, extendedAqi.olive, data, context),
          pollenWidget(Icons.filter_vintage_outlined,
              AppLocalizations.of(context)!.ragweedPollen, extendedAqi.ragweed, data, context),
        ],
      ),
    ),
  );
}

Widget pollutantIndicators(data, extendedAqi, context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 3, top: 20),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(33),
      ),
      padding: const EdgeInsets.only(top: 17, left: 15, right: 15, bottom: 11),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 3,
        shrinkWrap: true,
        childAspectRatio: 0.9,
        children: <Widget>[
          pollutantWidget(data, "pm2.5", extendedAqi.pm2_5, extendedAqi.pm2_5_p, context),
          pollutantWidget(data, "pm10", extendedAqi.pm10, extendedAqi.pm10_p, context),
          pollutantWidget(data, "o3", extendedAqi.o3, extendedAqi.o3_p, context),
          pollutantWidget(data, "no2", extendedAqi.no2, extendedAqi.no2_p, context),
          pollutantWidget(data, "co", extendedAqi.co, extendedAqi.co_p, context),
          pollutantWidget(data, "so2", extendedAqi.so2, extendedAqi.so2_p, context),
        ],
      ),
    ),
  );
}

Widget europeanAndUsAqi(WeatherData data, OMExtendedAqi extendedAqi, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 0),
    child: Row(
      children: [
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      "assets/m3shapes/4_sided_cookie.svg",
                      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.tertiaryContainer, BlendMode.srcIn),
                    ),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(extendedAqi.europeanAqi.toString(), style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary, fontSize: 33, height: 1.2),),
                          Padding(
                            padding: const EdgeInsets.only(top: 1, bottom: 10),
                            child: Text(
                              aqiTitleLocalization(extendedAqi.europeanDescIndex, AppLocalizations.of(context)!), style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface, fontSize: 15),),
                          ),
                          Text(AppLocalizations.of(context)!.europeanAqi, style: TextStyle(
                              color: Theme.of(context).colorScheme.outline, fontSize: 14),),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
        ),
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(extendedAqi.usAqi.toString(), style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, fontSize: 33, height: 1.2),),
                      Padding(
                        padding: const EdgeInsets.only(top: 1, bottom: 10),
                        child: Text(
                          aqiTitleLocalization(extendedAqi.usDescIndex, AppLocalizations.of(context)!), style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface, fontSize: 15),),
                      ),
                      Text(AppLocalizations.of(context)!.unitedStatesAqi, style: TextStyle(
                          color: Theme.of(context).colorScheme.outline, fontSize: 14),),
                    ],
                  ),
                ),
              ),
            )
        )
      ],
    ),
  );

}

Widget dailyAqi(WeatherData data, OMExtendedAqi extendedAqi, context, highestAqi) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 35, bottom: 10),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.dailyAqi, style: const TextStyle(fontSize: 17),)
        ),
      ),

      Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(extendedAqi.dailyAqi.length, (index) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
                  child: SizedBox(
                    height: 150,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: extendedAqi.dailyAqi[index] == highestAqi ? Theme.of(context).colorScheme.tertiaryContainer
                              : Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        width: 48,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 16),
                        //tried to do some null safety and not allowing the bars to be too short
                        height: max(130 / max(highestAqi, 1) * extendedAqi.dailyAqi[index], 48),
                        child: Text(
                          extendedAqi.dailyAqi[index].toString(),
                          style: TextStyle(
                            color: extendedAqi.dailyAqi[index] == highestAqi ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          )
                        )
                      ),
                    ),
                  ),
                ),
                Text(
                  index == 0 ? AppLocalizations.of(context)!.now
                      : "$index${AppLocalizations.of(context)!.d}",
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14)
                )
              ],
            );
          }
          )
      ),
      const SizedBox(height: 40,)
    ],
  );
}

Widget dustAndAODIndicators(WeatherData data, OMExtendedAqi extendedAqi, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 0),
    child: Row(
      children: [
        Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                height: 145,
                decoration: BoxDecoration(
                  border: Border.all(width: 1.5, color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(33), bottomLeft: Radius.circular(33),
                    bottomRight: Radius.circular(18), topRight: Radius.circular(18)),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.grain, size: 18, color: Theme.of(context).colorScheme.primary)
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(AppLocalizations.of(context)!.dust, style: const TextStyle(fontSize: 14, height: 1.1),),
                        )
                      ],
                    ),
                    const Spacer(),
                    Text(extendedAqi.dust.toString(), style: TextStyle(
                        color: Theme.of(context).colorScheme.primary, fontSize: 22, height: 1.1),),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: Text("μg/m³", style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            )
        ),
        Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                height: 145,
                decoration: BoxDecoration(
                  border: Border.all(width: 1.5, color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(33), topRight: Radius.circular(33)),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.grain, size: 18, color: Theme.of(context).colorScheme.primary)
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(AppLocalizations.of(context)!.aerosolOpticalDepth, style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontSize: 14, height: 1.1
                            ),)
                          ),
                        )
                      ],
                    ),
                    const Spacer(),
                    Text(extendedAqi.aod.toString(), style: TextStyle(
                        color: Theme.of(context).colorScheme.primary, fontSize: 22, height: 1.1),),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: Text(aerosolOpticalDepthLocalizations(extendedAqi.aodIndex, AppLocalizations.of(context)!), style: TextStyle(
                          color: Theme.of(context).colorScheme.outline, fontSize: 15, fontWeight: FontWeight.w600),)
                    ),
                  ],
                ),
              ),
            )
        )
      ],
    ),
  );
}

class NewHourlyAqi extends StatefulWidget {
  final WeatherData data;
  final OMExtendedAqi extendedAqi;

  NewHourlyAqi({Key? key, required this.data, required this.extendedAqi}) : super(key: key);

  @override
  _NewHourlyAqiState createState() => _NewHourlyAqiState();
}

class _NewHourlyAqiState extends State<NewHourlyAqi> with AutomaticKeepAliveClientMixin {
  int _value = 0;

  PageController _pageController = PageController();

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _value = ["pm2.5", "pm10", "ozone", "carbon monoxide", "sulphur dioxide", "nitrogen dioxide"].
      indexOf(widget.extendedAqi.mainPollutant);
    _pageController = PageController(initialPage: _value);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5, top: 25),
          child: SizedBox(
            height: 300,
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: <Widget>[
                HourlyQqi(widget.data, widget.extendedAqi.pm2_5_h, "PM2.5", widget.extendedAqi, context),
                HourlyQqi(widget.data, widget.extendedAqi.pm10_h, "PM10", widget.extendedAqi, context),
                HourlyQqi(widget.data, widget.extendedAqi.o3_h, "O3", widget.extendedAqi, context),
                HourlyQqi(widget.data, widget.extendedAqi.no2_h, "NO2", widget.extendedAqi, context),
                HourlyQqi(widget.data, widget.extendedAqi.co_h, "CO", widget.extendedAqi, context),
                HourlyQqi(widget.data, widget.extendedAqi.so2_h, "SO2", widget.extendedAqi, context),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 5.0,
          children: List<Widget>.generate(
            6,
                (int index) {

              return ChoiceChip(
                elevation: 0.0,
                checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
                color: WidgetStateProperty.resolveWith((states) {
                  if (index == _value) {
                    return Theme.of(context).colorScheme.secondaryContainer;
                  }
                  return Theme.of(context).colorScheme.surface;
                }),
                side: BorderSide(
                    color: index == _value ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: 1.6),
                label: Text(
                  ['pm2.5', 'pm10', 'o3', 'no2', 'co', 'so2'][index],
                  style: TextStyle(
                    color: _value == index ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                selected: _value == index,
                onSelected: (bool selected) {
                  _value = index;
                  setState(() {
                    HapticFeedback.lightImpact();
                    _onItemTapped(index);
                  });
                },
              );
            },
          ).toList(),
        ),
        const SizedBox(height: 40,),
      ],
    );

  }
}

class AQIGraphPainter extends CustomPainter {
  final List<double> aqiData;
  final int maxAQI;
  final Color color;

  AQIGraphPainter({required this.aqiData, required this.maxAQI, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

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

Widget HourlyQqi(WeatherData data, hourValues, name, OMExtendedAqi extendedAqi, context) {

  const List<List<int>> chartTypes = [
    [0, 2, 4, 6, 8, 10],
    [0, 5, 10, 15, 20, 25],
    [0, 10, 20, 30, 40, 50],
    [0, 20, 40, 60, 80, 100],
    [0, 30, 60, 90, 120, 150],
    [0, 50, 100, 150, 200, 250],
    [0, 100, 200, 300, 400, 500],
    [0, 200, 400, 600, 800, 1000]
  ];

  double valueMax = hourValues.reduce((a, b) => max<double>(a, b));
  int currentChart = 0;

  for (int i = 0; i < chartTypes.length; i++) {
    if (valueMax * 1.3 > chartTypes[i][chartTypes[i].length - 1]) { //because it looks weird if it is close to the top
      currentChart = min(i + 1, chartTypes.length - 1); //just for null safety
    }
  }

  int len = chartTypes[currentChart].length;

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.grain, size: 18, color: Theme.of(context).colorScheme.primary)
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(name, style: const TextStyle(fontSize: 16),)
              )
            ]
        ),
      ),

      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 10),
            child: SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(len, (index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(chartTypes[currentChart][len - 1 - index].toString(), style: TextStyle(
                          color: Theme.of(context).colorScheme.outline, fontSize: 14,
                      ),),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Container(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            height: 1,
                          ),
                        ),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 20),
            child: CustomPaint(
              painter: AQIGraphPainter(aqiData: hourValues,
                  maxAQI: chartTypes[currentChart][len - 1],
                  color: Theme.of(context).colorScheme.secondary),
              child: const SizedBox(
                width: double.infinity,
                height: 220.0,
              ),
            ),
          ),
        ],
      ),
      Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(extendedAqi.dailyAqi.length, (index) {
                return Text(
                  index == 0 ? AppLocalizations.of(context)!.now
                      : "$index${AppLocalizations.of(context)!.d}",
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),
                );
               }
              )
          ),
      )
    ]
  );
}
