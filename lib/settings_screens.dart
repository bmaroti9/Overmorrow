/*
Copyright (C) <2024>  <Balint Maroti>

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
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';

import 'decoders/decode_wapi.dart';
import 'main_ui.dart';

Widget settingEntry(String title, String desc, Color highlight, Color primary, Color onSurface, Color surface,
    IconData icon, settings, Widget pushTo, context) {
  return Padding(
    padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pushTo)
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: highlight,
        ),
        padding: EdgeInsets.all(23),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Icon(icon, color: primary, size: 24,),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                comfortatext(title, 21, settings, color: onSurface),
                comfortatext(desc, 16, settings, color: onSurface)
              ],
            )
          ],
        )
      ),
    ),
  );
}

Widget NewSettings(Map<String, String> settings, Function updatePage, Image image, List<Color> colors,
    allColors, context) {

  Color containerLow = colors[6];
  Color onSurface = colors[4];
  Color primary = colors[1];
  Color primaryLight = colors[2];
  Color surface = colors[0];
  Color colorpop = colors[12];
  Color desc_color = colors[13];


  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 20),
    child: Column(
      children: [
        settingEntry("Appearance", "color theme, image source", containerLow, primary, onSurface, surface,
            Icons.palette_outlined, settings,
          AppearancePage(primary: primary, settings: settings, surface: surface,
              onSurface: onSurface, highlight: containerLow, image: image, colorPop: colorpop, descColor: desc_color,),
          context,
        ),
        settingEntry("General", "time mode, font size", containerLow, primary, onSurface, surface,
            Icons.settings_applications, settings, Container(), context),
        settingEntry("Language", "the language used", containerLow, primary, onSurface, surface,
            Icons.language, settings, Container(), context),
        settingEntry("Units", "the units used in the app", containerLow, primary, onSurface, surface,
            Icons.pie_chart_outline, settings, Container(), context),
        settingEntry("Layout", "widget order, customization", containerLow, primary, onSurface, surface,
            Icons.grid_view, settings, Container(), context),
      ],
    ),
  );
}

class AppearancePage extends StatefulWidget {
  final Color primary;
  final Color surface;
  final settings;
  final onSurface;
  final highlight;
  final colorPop;
  final descColor;
  final image;

  const AppearancePage({Key? key, required this.primary, required this.settings, required this.surface, required this.onSurface,
    required this.highlight, required this.descColor, required this.colorPop, required this.image})
      : super(key: key);

  @override
  _AppearancePageState createState() =>
      _AppearancePageState(primary: primary, settings: settings, surface: surface, highlight: highlight, onSurface: onSurface,
      colorPop: colorPop, image: image, descColor: descColor);
}

class _AppearancePageState extends State<AppearancePage> {
  final primary;
  final settings;
  final surface;
  final onSurface;
  final highlight;
  final colorPop;
  final descColor;
  final image;

  _AppearancePageState({required this.primary, required this.settings, required this.surface, required this.onSurface,
    required this.highlight, required this.colorPop, required this.descColor, required this.image});

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: surface,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                "Appearance", 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 10),
                  child: Center(
                    child: SizedBox(
                      width: 270,
                      height: 320,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            ParrallaxBackground(image: image, color: surface),
                            Padding(
                              padding: const EdgeInsets.only(left: 10, bottom: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  comfortatext("${unit_coversion(29, settings["Temperature"]!).toInt()}°", 50, settings, color: colorPop),
                                  comfortatext(translation("Clear Sky", settings["Language"]!), 25,
                                      settings, color: descColor)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}