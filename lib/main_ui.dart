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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/main_screens.dart';
import 'package:overmorrow/settings_page.dart';
import 'ui_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WeatherPage extends StatelessWidget {
  final data;
  final updateLocation;

  WeatherPage({super.key, required this.data,
        required this.updateLocation});

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize / view.devicePixelRatio;

    if (size.width > 950) {
      return TabletLayout(data, updateLocation, context);
    }

    return NewMain(data: data, updateLocation: updateLocation, context: context,
        key: Key("${data.place}, ${data.provider} ${data.updatedTime}"),);
  }
}

class ParrallaxBackground extends StatelessWidget {
  final Image image;
  final Color color;

  const ParrallaxBackground({Key? key, required this.image, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1300),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          color: color,
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 1.0 + (0.06 * value),
              child: image,
            ),
          ),
        );
      },
    );
  }
}


Widget Circles(double width, var data, double bottom, color, context, {align = Alignment.center}) {
  return Align(
    alignment: align,
    child: SizedBox(
      width: width,
        child: Container(
            //top padding is slightly bigger because of the offline colored bar
            padding: EdgeInsets.only(top: data.isonline ? 26 : 33, left: 4, right: 4, bottom: 13),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.feels_like}°',
                    undercaption: AppLocalizations.of(context)!.feelsLike,
                    extra: '',
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: -1,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.humidity}',
                    undercaption: AppLocalizations.of(context)!.humidity,
                    extra: '%',
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: -1,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.precip}',
                    undercaption: AppLocalizations.of(context)!.precipLowercase,
                    extra: data.settings["Precipitation"],
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: -1,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.wind}',
                    undercaption: AppLocalizations.of(context)!.windCapital,
                    extra: data.settings["Wind"],
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: data.current.wind_dir + 180,
                  ),
                ]
            )
        )
    ),
  );
}

Widget providerSelector(settings, updateLocation, textcolor, highlight, primary,
    provider, latlng, real_loc, context) {
  return Padding(
    padding: const EdgeInsets.only(left: 23, right: 23, bottom: 30, top: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(
                AppLocalizations.of(context)!.weatherProvider, 16,
                settings,
                color: textcolor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
            child: DropdownButton(
              underline: Container(),
              onTap: () {
                HapticFeedback.mediumImpact();
              },
              borderRadius: BorderRadius.circular(20),
              icon: Padding(
                padding: const EdgeInsets.only(left:5),
                child: Icon(Icons.arrow_drop_down_circle_outlined, color: primary, size: 22,),
              ),
              style: GoogleFonts.comfortaa(
                color: primary,
                fontSize: 18 * getFontSize(settings["Font size"]),
                fontWeight: FontWeight.w500,
              ),
              //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
              value: provider.toString(),
              items: ['weatherapi.com', 'open-meteo', 'met norway'].map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? value) async {
                HapticFeedback.mediumImpact();
                SetData('weather_provider', value!);
                await updateLocation(latlng, real_loc);
              },
              isExpanded: true,
              dropdownColor: highlight,
              elevation: 0,
            ),
          ),
        ),
      ],
    ),
  );
}
