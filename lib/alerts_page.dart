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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overmorrow/new_displays.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


Widget alertBadge(name, text, data) {
  return Padding(
    padding: const EdgeInsets.only(right: 3.0, top: 3, bottom: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        comfortatext("$name:", 15, data.settings, color: data.current.onSurface),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: data.current.primaryLight,
            ),
            padding: const EdgeInsets.only(left: 5, right: 5, top: 5.5, bottom: 4.5),
            child: comfortatext(text, 13, data.settings, color: data.current.onPrimaryLight),
          ),
        )
      ],
    ),
  );
}

class AlertsPage extends StatefulWidget {
  final data;

  const AlertsPage({Key? key, required this.data})
      : super(key: key);

  @override
  _AlertsPageState createState() =>
      _AlertsPageState(data: data);
}

class _AlertsPageState extends State<AlertsPage> {

  final data;

  _AlertsPageState({required this.data});

  @override
  void initState() {
    super.initState();
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      color: data.current.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: data.current.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                AppLocalizations.of(context)!.alertsCapital, 30, data.settings,
                color: data.current.primary),
            backgroundColor: data.current.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(data.alerts.length, (index) {
                  final alert = data.alerts[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 35, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        comfortatext(alert.event, 23, data.settings, color: data.current.primary),
                        Padding(
                          padding: const EdgeInsets.only(top: 25, left: 3),
                          child: comfortatext(alert.headline, 16, data.settings, color: data.current.onSurface),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 20, left: 3, bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.only(left: 15, bottom: 3, top: 3),
                            decoration: BoxDecoration(
                                border: Border(left:
                                BorderSide(width: 2, color: data.current.primaryLight),
                            )
                            ),
                            child: comfortatext(alert.desc, 16, data.settings, color: data.current.outline)
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 5),
                          child: comfortatext("${data.alerts[index].start} - ${data.alerts[index].end}", 15, data.settings,
                              color: data.current.primary),
                        ),
                        
                        Wrap(
                          children: [
                            alertBadge("severity", alert.severity, data),
                            alertBadge("certainty", alert.certainty, data),
                            alertBadge("urgency", alert.urgency, data),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 15),
                          child: comfortatext("areas:", 16, data.settings, color: data.current.primary),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 5),
                          child: comfortatext(alert.areas, 15, data.settings,
                              color: data.current.outline),
                        ),

                        if (index != data.alerts.length - 1)Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4, top: 30, bottom: 10),
                          child: CustomPaint(
                            painter: WavePainter(
                                0, widget.data.current.primarySecond,
                                darken(widget.data.current.surfaceVariant, 0.03),
                                1),
                            child: Container(
                              width: double.infinity,
                              height: 8.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            )
          ),
        ],
      ),
    );
  }
}