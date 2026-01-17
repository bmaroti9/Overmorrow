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

import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../decoders/decode_OM.dart';
import '../decoders/weather_data.dart';

import '../../../l10n/app_localizations.dart';

class PrecipitationPage extends StatefulWidget {
  final WeatherData data;

  const PrecipitationPage({Key? key, required this.data})
      : super(key: key);

  @override
  _PrecipitationPageState createState() =>
      _PrecipitationPageState();
}

class _PrecipitationPageState extends State<PrecipitationPage> {

  void goBack() {
    HapticFeedback.lightImpact();
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

                return Container();
                /*

                return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return OneRowLayout(data: widget.data, extendedAqi: extendedAqi);
                      }
                      if (constraints.maxWidth < 1000) {
                        return TwoRowLayout(data: widget.data, extendedAqi: extendedAqi);
                      }
                      return ThreeRowLayout(data: widget.data, extendedAqi: extendedAqi);
                    }
                );

                 */
              },
            ),
          ),
        ],
      ),
    );
  }
}