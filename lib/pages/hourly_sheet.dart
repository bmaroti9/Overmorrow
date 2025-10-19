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
import 'package:flutter_svg/svg.dart';
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/weather_service.dart';
import '../../l10n/app_localizations.dart';

import '../weather_refact.dart';

class HourlyBottomSheet extends StatelessWidget {
  final WeatherHour hour;

  const HourlyBottomSheet({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {

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
                  padding: const EdgeInsets.only(top: 40, bottom: 50),
                  child: Text(convertTime(hour.time, context)),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.outlined(
                        onPressed: () {

                        },
                        icon: Icon(Icons.keyboard_arrow_left_outlined, color: Theme.of(context).colorScheme.onSurface,)
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

                        },
                        icon: Icon(Icons.keyboard_arrow_right_outlined, color: Theme.of(context).colorScheme.onSurface,)
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 50),
                  child: Text(conditionTranslation(hour.condition, AppLocalizations.of(context)!) ?? "Clear Sky",
                    style: TextStyle(fontSize: 20),),
                ),

                ElevatedButton(
                  child: const Text('Close BottomSheet'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            controller: scrollController, // 🚨 ESSENTIAL: Assign the controller here
            itemCount: 50,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Item $index'),
              );
            },
          ),
        );
      },
    );


  }

}