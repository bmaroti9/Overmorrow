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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overmorrow/services/weather_service.dart';
import '../../l10n/app_localizations.dart';
import '../decoders/weather_data.dart';


Widget alertBadge(name, text, WeatherData data, context) {
  return Padding(
    padding: const EdgeInsets.only(right: 3.0, top: 3, bottom: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$name:", style: const TextStyle(fontSize: 15),),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            padding: const EdgeInsets.only(left: 7, right: 7, top: 6, bottom: 6),
            child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 13),),
          ),
        )
      ],
    ),
  );
}

class AlertsPage extends StatefulWidget {
  final WeatherData data;

  const AlertsPage({Key? key, required this.data})
      : super(key: key);

  @override
  _AlertsPageState createState() =>
      _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {

  @override
  void initState() {
    super.initState();
  }

  void goBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  goBack();
                }),
            title: Text(AppLocalizations.of(context)!.alertsCapital, style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(widget.data.alerts.length, (index) {
                    final alert = widget.data.alerts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(left: 24, right: 24, top: 2, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.only(left: 7, right: 7, top: 6, bottom: 8),
                                  child: Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error)
                              ),
                              const SizedBox(width: 15,),
                              Expanded(
                                child: Text(alert.event,
                                  style: const TextStyle(fontSize: 21, height: 1.3),
                                )
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(top: 25, left: 3),
                            child: Text(alert.headline, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary, height: 1.3),)
                          ),

                          Padding(
                            padding: const EdgeInsets.only(top: 25, left: 3, bottom: 20),
                            child: Container(
                              padding: const EdgeInsets.only(left: 15, bottom: 3, top: 3),
                              decoration: BoxDecoration(
                                  border: Border(left:
                                  BorderSide(width: 2, color: Theme.of(context).colorScheme.secondaryContainer),
                              )
                              ),
                              child: Text(alert.desc, style: TextStyle(color: Theme.of(context).colorScheme.outline,
                                  fontSize: 16))
                            ),
                          ),

                          Wrap(
                            children: [
                              alertBadge(AppLocalizations.of(context)!.severity, alert.severity, widget.data, context),
                              alertBadge(AppLocalizations.of(context)!.certainty, alert.certainty, widget.data, context),
                              alertBadge(AppLocalizations.of(context)!.urgency, alert.urgency, widget.data, context),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left: 2, top: 15),
                            child: Text("${AppLocalizations.of(context)!.areas}:", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),)
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30, top: 5),
                            child: Text(alert.areas, style: TextStyle(color: Theme.of(context).colorScheme.outline,
                                fontSize: 15))
                          ),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                "${convertToWeekDayTime(widget.data.alerts[index].start, context)} - "
                                    "${convertToWeekDayTime(widget.data.alerts[index].end, context)}",
                                style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 14),),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 200,),
              ],
            )
          ),
        ],
      ),
    );
  }
}