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
          AppearancePage(primary: primary, settings: settings, surface: surface, onSurface: onSurface,
            highlight: containerLow, image: image, colorPop: colorpop, descColor: desc_color,
            updatePage: updatePage),
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

Widget ColorThemeButton(String name, IconData icon, Color highlight, Color primary, settings, updatePage) {
  bool selected = settings["Color mode"] == name;
  return Padding(
    padding: const EdgeInsets.all(3.0),
    child: GestureDetector(
      onTap: () {
        updatePage("Color mode", name);
      },
      child: Container(
        padding: const EdgeInsets.only(top: 22, bottom: 22, left: 8, right: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? primary : highlight,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 17, color: selected ? highlight : primary,),
            ),
            comfortatext(name, 17, settings, color: selected ? highlight : primary, weight: FontWeight.w600)
          ],
        ),
      ),
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
  final updatePage;

  const AppearancePage({Key? key, required this.primary, required this.settings, required this.surface, required this.onSurface,
    required this.highlight, required this.descColor, required this.colorPop, required this.image, required this.updatePage})
      : super(key: key);

  @override
  _AppearancePageState createState() =>
      _AppearancePageState(primary: primary, settings: settings, surface: surface, highlight: highlight, onSurface: onSurface,
      colorPop: colorPop, image: image, descColor: descColor, updatePage: updatePage);
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
  final updatePage;

  _AppearancePageState({required this.primary, required this.settings, required this.surface, required this.onSurface,
    required this.highlight, required this.colorPop, required this.descColor, required this.image, required this.updatePage});

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
                  padding: const EdgeInsets.only(top: 50, bottom: 10),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: highlight
                      ),
                      width: 240,
                      height: 330,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: Stack(
                                children: [
                                  ParrallaxBackground(image: image, color: surface),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10, bottom: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        comfortatext("${unit_coversion(29, settings["Temperature"]!).toInt()}°", 42,
                                            settings, color: colorPop, weight: FontWeight.w300),
                                        comfortatext(translation("Clear Sky", settings["Language"]!), 22,
                                            settings, color: descColor, weight: FontWeight.w500)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10, right: 4, left: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(4, (index) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(40),
                                            border: Border.all(color: primary, width: 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorThemeButton("light", Icons.light_mode_outlined, highlight, primary, settings, updatePage),
                          ColorThemeButton("dark", Icons.dark_mode_outlined, highlight, primary, settings, updatePage),
                          ColorThemeButton("automatic", Icons.brightness_6_rounded, highlight, primary, settings, updatePage),
                        ]
                    )
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorThemeButton("original", Icons.circle_outlined, highlight, primary, settings, updatePage),
                          ColorThemeButton("colorful", Icons.circle, highlight, primary, settings, updatePage),
                          ColorThemeButton("monochrome", Icons.invert_colors_on_outlined, highlight, primary, settings, updatePage),
                        ]
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}