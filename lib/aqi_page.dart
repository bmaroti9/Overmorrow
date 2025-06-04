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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:overmorrow/decoders/decode_OM.dart';

import 'package:overmorrow/ui_helper.dart';
import '../l10n/app_localizations.dart';

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

    double waves = 12;
    double waveAmplitude = size.width / 52;

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

Widget pollenWidget(IconData icon, String name, double value, data, ColorScheme palette) {
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
        Icon(icon, size: 22, color: palette.secondary),
        Padding(
          padding: const EdgeInsets.only(left: 17),
          child: comfortatext(name, 17, data.settings, color: palette.onSurface),
        ),
        const Spacer(),
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: categoryIndex >= 4 ? palette.errorContainer
                : categoryIndex >= 3 ? palette.primaryContainer
                : categoryIndex >= 2 ? palette.secondaryContainer
                : palette.surfaceContainerHigh,
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            width: 75,
            child: Center(child: comfortatext(severity, 15, data.settings, color: palette.onSecondaryContainer))
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
      -3.14159265359 * 5 / 4 + angle + 0.35,
      3.14159265359 * 1.5 - angle - 0.35,
      false,
      baseCircle,
    );

    // Foreground Circle
    Paint progressCircle = Paint()
      ..color = color
      ..strokeWidth = 9
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

Widget pollutantWidget(data, name, value, percent, ColorScheme palette) {
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
                    painter: ThreeQuarterCirclePainter(percentage: percent, color: palette.secondary,
                    secondColor: palette.secondaryContainer),
                    child: Center(
                      child: comfortatext(value.toString(), 18, data.settings, color: palette.secondary, weight: FontWeight.w600)
                  ),
                ),
                            ),
              ),
          ),
        ),
        comfortatext(name, 14, data.settings, color: palette.onSurface),
      ],
    ),
  );
}

class AllergensPage extends StatefulWidget {
  final data;
  final isTabletMode;

  const AllergensPage({Key? key, required this.data, required this.isTabletMode})
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
    ColorScheme palette = data.current.palette;
    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: palette.primary),
              onPressed: () {
                goBack();
              },
            ),
            title: comfortatext(AppLocalizations.of(context)!.airQuality, 30, data.settings,
                color: palette.secondary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<OMExtendedAqi>(
              future: OMExtendedAqi.fromJson(data.lat, data.lng, data.settings, AppLocalizations.of(context)!),
              builder: (BuildContext context,
                  AsyncSnapshot<OMExtendedAqi> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 200),
                    child: Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: palette.secondary,
                        size: 40,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  print((snapshot.error, snapshot.stackTrace));
                  //this was the best way i found to detect no wifi
                  if (snapshot.error.toString().contains("Socket")) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Icon(Icons.wifi_off_rounded, color: palette.primary, size: 23,),
                          ),
                          comfortatext("no wifi connection", 18, data.settings, color: palette.onSurface),
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
                          child: Icon(Icons.wifi_off_rounded, color: palette.primary, size: 23,),
                        ),
                        comfortatext("unable to load air quality data", 18, data.settings, color: palette.onSurface),
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: comfortatext("${snapshot.error} ${snapshot.stackTrace}", 15, data.settings, color: palette.outline,
                          align: TextAlign.center),
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
                                  aqiCircleAndDesc(data, palette),
                                  pollutantIndicators(data, extendedAqi, palette),
                                ],
                              )
                            ),
                            const SizedBox(width: 40,),
                            Expanded(
                              child: Column(
                                children: [
                                  NewHourlyAqi(data: data, extendedAqi: extendedAqi),
                                  dailyAqi(data, extendedAqi, palette, context, highestAqi),
                                ],
                              )
                            ),
                            const SizedBox(width: 40,),
                            Expanded(
                                child: Column(
                                  children: [
                                    mainPollutantIndicator(data, extendedAqi, palette, context),
                                    pollenIndicators(data, extendedAqi, palette, context),
                                    europeanAndUsAqi(data, extendedAqi, palette, context),
                                    dustAndAODIndicators(data, extendedAqi, palette, context),
                                  ],
                                )
                            )
                          ],
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 70, bottom: 70),
                            child: comfortatext(AppLocalizations.of(context)!.poweredByOpenMeteo, 16, data.settings, color: palette.outline),
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
                          aqiCircleAndDesc(data, palette),
                          mainPollutantIndicator(data, extendedAqi, palette, context),
                          pollenIndicators(data, extendedAqi, palette, context),
                          NewHourlyAqi(data: data, extendedAqi: extendedAqi),
                          pollutantIndicators(data, extendedAqi, palette),
                          europeanAndUsAqi(data, extendedAqi, palette, context),
                          dailyAqi(data, extendedAqi, palette, context, highestAqi),
                          dustAndAODIndicators(data, extendedAqi, palette, context),

                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 70, bottom: 70),
                              child: comfortatext(AppLocalizations.of(context)!.poweredByOpenMeteo, 16, data.settings, color: palette.outline),
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

Widget aqiCircleAndDesc(data, ColorScheme palette) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 25),
        child: FractionallySizedBox(
          widthFactor: 0.77,
          alignment: FractionalOffset.center,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: SquigglyCirclePainter(palette.primaryFixedDim),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: comfortatext(data.aqi.aqi_index.toString(), 75, data.settings, color: palette.secondary, weight: FontWeight.w200),
                    ),
                    comfortatext(data.aqi.aqi_title, 23, data.settings, color: palette.secondary, weight: FontWeight.w400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 30, left: 30, right: 30),
        child: comfortatext(data.aqi.aqi_desc, 17, data.settings, color: palette.outline, weight: FontWeight.w400, align: TextAlign.center),
      ),
    ],
  );
}

Widget mainPollutantIndicator(data, extendedAqi, ColorScheme palette, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 25, bottom: 3),
    child: Container(
      decoration: BoxDecoration(
        color: palette.secondaryContainer,
        borderRadius: BorderRadius.circular(33),
      ),
      height: 67,
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Row(
        children: [
          comfortatext(AppLocalizations.of(context)!.mainPollutant, 18, data.settings,
              color: palette.onSecondaryContainer),
          const Spacer(),
          comfortatext(extendedAqi.mainPollutant, 18, data.settings,
              color: palette.primary, weight: FontWeight.w600)
        ],
      ),
    ),
  );
}

Widget pollenIndicators(data, extendedAqi, ColorScheme palette, context) {
  return  Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 10),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: palette.outlineVariant),
        borderRadius: BorderRadius.circular(33),
      ),
      padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 16),
      child: Column(
        children: [
          pollenWidget(Icons.forest_outlined,
              AppLocalizations.of(context)!.alderPollen, extendedAqi.alder, data, palette),
          pollenWidget(Icons.eco_outlined,
              AppLocalizations.of(context)!.birchPollen, extendedAqi.birch, data, palette),
          pollenWidget(Icons.grass_outlined,
              AppLocalizations.of(context)!.grassPollen, extendedAqi.grass, data, palette),
          pollenWidget(Icons.local_florist_outlined,
              AppLocalizations.of(context)!.mugwortPollen, extendedAqi.mugwort, data, palette),
          pollenWidget(Icons.park_outlined,
              AppLocalizations.of(context)!.olivePollen, extendedAqi.olive, data, palette),
          pollenWidget(Icons.filter_vintage_outlined,
              AppLocalizations.of(context)!.ragweedPollen, extendedAqi.ragweed, data, palette),
        ],
      ),
    ),
  );
}

Widget pollutantIndicators(data, extendedAqi, ColorScheme palette) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 3, top: 40),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: palette.outlineVariant),
        borderRadius: BorderRadius.circular(33),
      ),
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 3,
        shrinkWrap: true,
        childAspectRatio: 0.9,
        children: <Widget>[
          pollutantWidget(data, "pm2.5", extendedAqi.pm2_5, extendedAqi.pm2_5_p, palette),
          pollutantWidget(data, "pm10", extendedAqi.pm10, extendedAqi.pm10_p, palette),
          pollutantWidget(data, "o3", extendedAqi.o3, extendedAqi.o3_p, palette),
          pollutantWidget(data, "no2", extendedAqi.no2, extendedAqi.no2_p, palette),
          pollutantWidget(data, "co", extendedAqi.co, extendedAqi.co_p, palette),
          pollutantWidget(data, "so2", extendedAqi.so2, extendedAqi.so2_p, palette),
        ],
      ),
    ),
  );
}

Widget europeanAndUsAqi(data, extendedAqi, ColorScheme palette, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 0),
    child: Row(
      children: [
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(33),
                ),
                height: 120,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    comfortatext(AppLocalizations.of(context)!.europeanAqi, 14, data.settings,
                        color: palette.onSurface),
                    const Spacer(),
                    comfortatext(extendedAqi.european_aqi.toString(), 25, data.settings,
                        color: palette.primary, weight: FontWeight.w400),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: comfortatext(extendedAqi.european_desc, 15, data.settings,
                          color: palette.outline, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
        ),
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(33),
                ),
                height: 120,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    comfortatext(AppLocalizations.of(context)!.unitedStatesAqi, 14, data.settings,
                        color: palette.onSurface),
                    const Spacer(),
                    comfortatext(extendedAqi.us_aqi.toString(), 25, data.settings,
                        color: palette.primary, weight: FontWeight.w400),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: comfortatext(extendedAqi.us_desc, 15, data.settings,
                          color: palette.outline, weight: FontWeight.w600),
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

Widget dailyAqi(data, extendedAqi, ColorScheme palette, context, highestAqi) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 35, bottom: 10),
        child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(AppLocalizations.of(context)!.dailyAqi, 17, data.settings, color: palette.onSurface)
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
                          color: extendedAqi.dailyAqi[index] == highestAqi ? palette.secondary : palette.secondaryContainer,
                        ),
                        width: 48,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 16),
                        //tried to do some null safety and not allowing the bars to be too short
                        height: max(130 / max(highestAqi, 1) * extendedAqi.dailyAqi[index], 42),
                        child: comfortatext(extendedAqi.dailyAqi[index].toString(), 16, data.settings,
                            color: extendedAqi.dailyAqi[index] == highestAqi ? palette.onSecondary : palette.onSecondaryContainer,
                            weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                comfortatext(index == 0 ? AppLocalizations.of(context)!.now
                    : "$index${AppLocalizations.of(context)!.d}",
                    14, data.settings, color: palette.outline)
              ],
            );
          }
          )
      ),
      const SizedBox(height: 40,)
    ],
  );
}

Widget dustAndAODIndicators(data, extendedAqi, ColorScheme palette, context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 0),
    child: Row(
      children: [
        Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1.5, color: palette.outlineVariant),
                  borderRadius: BorderRadius.circular(33),
                ),
                height: 125,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.grain, size: 18, color: palette.secondary),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: comfortatext(AppLocalizations.of(context)!.dust, 14, data.settings, color: palette.onSurface),
                        )
                      ],
                    ),
                    const Spacer(),
                    comfortatext(extendedAqi.dust.toString(), 25, data.settings, color: palette.primary, weight: FontWeight.w400),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: comfortatext("μg/m³", 15, data.settings, color: palette.outline, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
        ),
        Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1.5, color: palette.outlineVariant),
                  borderRadius: BorderRadius.circular(33),
                ),
                height: 125,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.grain, size: 18, color: palette.secondary),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: comfortatext(AppLocalizations.of(context)!.aerosolOpticalDepth,
                                14, data.settings, color: palette.onSurface),
                          ),
                        )
                      ],
                    ),
                    const Spacer(),
                    comfortatext(extendedAqi.aod.toString(), 25, data.settings, color: palette.primary, weight: FontWeight.w400),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: comfortatext(extendedAqi.aod_desc, 15, data.settings, color: palette.outline, weight: FontWeight.w600),
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
  final data;
  final extendedAqi;

  NewHourlyAqi({Key? key, required this.data, required this.extendedAqi}) : super(key: key);

  @override
  _NewHourlyAqiState createState() => _NewHourlyAqiState(data, extendedAqi);
}

class _NewHourlyAqiState extends State<NewHourlyAqi> with AutomaticKeepAliveClientMixin {
  final data;
  final extendedAqi;
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
      indexOf(extendedAqi.mainPollutant);
    _pageController = PageController(initialPage: _value);
  }

  @override
  bool get wantKeepAlive => true;

  _NewHourlyAqiState(this.data, this.extendedAqi);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ColorScheme palette = data.current.palette;

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
                HourlyQqi(data, extendedAqi.pm2_5_h, "PM2.5", extendedAqi, context, palette),
                HourlyQqi(data, extendedAqi.pm10_h, "PM10", extendedAqi, context, palette),
                HourlyQqi(data, extendedAqi.o3_h, "O3", extendedAqi, context, palette),
                HourlyQqi(data, extendedAqi.no2_h, "NO2", extendedAqi, context, palette),
                HourlyQqi(data, extendedAqi.co_h, "CO", extendedAqi, context, palette),
                HourlyQqi(data, extendedAqi.so2_h, "SO2", extendedAqi, context, palette),
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
                checkmarkColor: palette.onSecondaryContainer,
                color: WidgetStateProperty.resolveWith((states) {
                  if (index == _value) {
                    return palette.secondaryContainer;
                  }
                  return palette.surface;
                }),
                side: BorderSide(
                    color: index == _value ? palette.secondaryContainer : palette.outlineVariant,
                    width: 1.6),
                label: comfortatext(
                    ['pm2.5', 'pm10', 'o3', 'no2', 'co', 'so2'][index], 14, data.settings,
                    color: _value == index ? palette.onSecondaryContainer : palette.onSurface),
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

Widget HourlyQqi(data, hourValues, name, extendedAqi, context, ColorScheme palette) {

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
              Icon(Icons.grain, size: 20, color: palette.primary),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: comfortatext(name, 17, data.settings, color: palette.onSurface),
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
                      comfortatext(chartTypes[currentChart][len - 1 - index].toString(), 14, data.settings,
                          color: palette.outline),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Container(
                            color: palette.outlineVariant,
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
                  color: palette.secondary),
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
                return comfortatext(index == 0 ? AppLocalizations.of(context)!.now
                    : "${index}${AppLocalizations.of(context)!.d}",
                    14, data.settings, color: palette.outline);
               }
              )
          ),
      )
    ]
  );
}
