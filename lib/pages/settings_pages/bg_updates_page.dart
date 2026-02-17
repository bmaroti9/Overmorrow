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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/pages/settings_pages/settings_page.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';

class TimeLinePainter extends CustomPainter {
  final List<double> percentages; // Values between 0.0 and 1.0
  final Color pointColor;

  TimeLinePainter({
    required this.percentages,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pointPaint = Paint()
      ..color = pointColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double yCenter = size.height / 2;

    for (double percent in percentages) {
      double xPos = percent * size.width;

      canvas.drawLine(
          Offset(xPos, yCenter - size.height / 2 + 4),
          Offset(xPos, yCenter + size.height / 2 - 4),
          pointPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimeLinePainter oldDelegate) {
    return oldDelegate.percentages != percentages;
  }
}

class BackgroundUpdatesPage extends StatefulWidget {

  const BackgroundUpdatesPage({Key? key}) : super(key: key);

  @override
  _BackgroundUpdatesPageState createState() =>
      _BackgroundUpdatesPageState();
}

class _BackgroundUpdatesPageState extends State<BackgroundUpdatesPage> {

  String widgetBackgroundState = "--";
  List<DateTime> updateTimes = [];
  List<double> updateLines = [];

  //this is all for debugging the background worker
  Future<void> getWidgetBackgroundState() async {
    widgetBackgroundState = (await HomeWidget.getWidgetData<String>("widget.backgroundUpdateState", defaultValue: "unknown")) ?? "unknown";
  }

  void getBackgroundUpdateTimes() async {
    List<String> timestamps = PreferenceUtils.getStringList("backgroundUpdateLog", []);

    DateTime now = DateTime.now();

    for (int i = 0; i < timestamps.length; i++) {
      DateTime time = DateTime.parse(timestamps[i]);
      updateTimes.add(time);
      double percent = 1.0 - (now.difference(time).inMinutes / 1440);
      updateLines.add(percent);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      getWidgetBackgroundState();
    });
    setState(() {
      getBackgroundUpdateTimes();
    });
  }

  @override
  Widget build(BuildContext context) {

    final ifnot = ["{\n        \"id\": 2651922,\n        \"name\": \"Nashville\",\n        \"region\": \"Tennessee\",\n        \"country\": \"United States of America\",\n        \"lat\": 36.17,\n        \"lon\": -86.78,\n        \"url\": \"nashville-tennessee-united-states-of-america\"\n    }"];
    final favorites = PreferenceUtils.getStringList('favorites', ifnot);

    final currentLocationName = PreferenceUtils.getString("LastKnownPositionName", "unknown");
    final currentLocationLatLon = PreferenceUtils.getString("LastKnownPositionCord", "unknown");
    bool isCurrentSelected = context.select((SettingsProvider p) => p.getOngoingNotificationPlace) == "Current Location";

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                }),
            title: Text(AppLocalizations.of(context)!.backgroundUpdates,
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: AnimationLimiter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 80.0,
                        child: FadeInAnimation(
                          child: widget,
                        ),
                      ),
                      children: [

                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 4, bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("${updateLines.length}", style: TextStyle(color: Theme.of(context).colorScheme.primary,
                                        fontSize: 36, fontWeight: FontWeight.w600, height: 1.1),),
                                    Text("/24", style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 20, fontWeight: FontWeight.w600),),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 1, left: 5),
                                      child: Text("updates complete", style: TextStyle(color: Theme.of(context).colorScheme.outline,
                                        fontWeight: FontWeight.w600, fontSize: 16),),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                height: 35,
                                width: double.infinity,
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 6),
                                child: CustomPaint(
                                  painter: TimeLinePainter(
                                    percentages: updateLines,
                                    pointColor: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 3, right: 3, top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('24${AppLocalizations.of(context)!.hr}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 13),),
                                    Text('18${AppLocalizations.of(context)!.hr}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 13),),
                                    Text('12${AppLocalizations.of(context)!.hr}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 13),),
                                    Text('6${AppLocalizations.of(context)!.hr}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 13),),
                                    Text(AppLocalizations.of(context)!.now,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 13),),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20,),

                        SwitchSettingEntry(
                          icon: Icons.published_with_changes,
                          text: AppLocalizations.of(context)!.ongoingNotification,
                          selected: context.select((SettingsProvider p) => p.getOngoingNotificationOn),
                          update: context.read<SettingsProvider>().setOngoingNotification,
                        ),

                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  if (currentLocationName != "unknown" && currentLocationLatLon != "unknown") {
                                    HapticFeedback.lightImpact();
                                    context.read<SettingsProvider>().setOngoingNotificationPlaceAndLatLon("Current Location", currentLocationLatLon);
                                  }
                                },
                                child: Container(
                                  decoration: (isCurrentSelected) ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Theme.of(context).colorScheme.tertiaryContainer
                                  ) : const BoxDecoration(),
                                  padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text("Current Location ($currentLocationName)", style: const TextStyle(
                                            fontSize: 16, height: 1.2),),
                                      ),
                                      if (isCurrentSelected) Icon(
                                        Icons.check,
                                        color: Theme.of(context).colorScheme.tertiary,
                                        size: 17,
                                      )
                                    ],
                                  ),
                                ),
                              ),

                              Column(
                                  children: List.generate(favorites.length, (index) {
                                    var split = json.decode(favorites[index]);
                                    String name = split["name"];

                                    bool isSelected = context.select((SettingsProvider p) => p.getOngoingNotificationPlace) == name;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        context.read<SettingsProvider>().setOngoingNotificationPlaceAndLatLon(name, '${split["lat"]}, ${split["lon"]}');
                                      },
                                      child: Container(
                                        decoration: isSelected ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: Theme.of(context).colorScheme.tertiaryContainer
                                        ) : const BoxDecoration(),
                                        padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(name, style: const TextStyle(
                                                  fontSize: 16, height: 1.2),),
                                            ),
                                            if (isSelected) Icon(
                                              Icons.check,
                                              color: Theme.of(context).colorScheme.tertiary,
                                              size: 17,
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 4),
                          child: Text(AppLocalizations.of(context)!.weatherProvderLowercase),
                        ),

                        SegmentedButton(
                          multiSelectionEnabled: false,
                          segments: const <ButtonSegment>[
                            ButtonSegment(
                              value: "open-meteo",
                              label: Text('open-meteo'),
                            ),
                            ButtonSegment(
                              value: "weatherapi",
                              label: Text('weatherapi'),
                            ),
                            ButtonSegment(
                              value: "met-norway",
                              label: Text('met-norway'),
                            ),
                          ],
                          selected: {context.select((SettingsProvider p) => p.getOngoingNotificationProvider)},
                          onSelectionChanged: (newSelection) {
                            HapticFeedback.lightImpact();
                            context.read<SettingsProvider>().setOngoingNotificationProvider(newSelection.first);
                          },
                        ),

                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {

                                  return AlertDialog(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    content: StatefulBuilder(
                                      builder: (BuildContext context, StateSetter setState) {
                                        return Column(
                                          children: [
                                            Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.tertiary),
                                            const SizedBox(height: 40,),
                                            Text(widgetBackgroundState,
                                                style: const TextStyle(fontSize: 18)),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                }
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(50)
                            ),
                            margin: const EdgeInsets.only(top: 40, bottom: 100),
                            padding: const EdgeInsets.all(14),
                            child: const Row(
                              children: [
                                Text("worker logs",
                                    style: TextStyle(fontSize: 18)),
                                Spacer(),
                                Icon(Icons.open_in_new, size: 18,),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}