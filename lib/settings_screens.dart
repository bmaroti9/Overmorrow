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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';

import 'decoders/decode_wapi.dart';
import 'main_ui.dart';

Widget mainSettingEntry(String title, String desc, Color highlight, Color primary, Color onSurface, Color surface,
    IconData icon, settings, Widget pushTo, context, updatePage) {
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
        padding: const EdgeInsets.all(23),
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
  Color surface = colors[0];

  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 20),
    child: Column(
      children: [
        mainSettingEntry("Appearance", "color theme, image source", containerLow, primary, onSurface, surface,
            Icons.palette_outlined, settings,
          AppearancePage(settings: settings, image: image, allColors: allColors, updateMainPage: updatePage,),
          context, updatePage
        ),
        mainSettingEntry("General", "time mode, font size", containerLow, primary, onSurface, surface,
            Icons.settings_applications, settings,
            GeneralSettingsPage(colors: colors, settings: settings, image: image, updateMainPage: updatePage),
            context, updatePage),
        mainSettingEntry("Language", "the language used", containerLow, primary, onSurface, surface,
            Icons.language, settings,
            LangaugePage(colors: colors, settings: settings, image: image, updateMainPage: updatePage),
            context, updatePage),
        mainSettingEntry("Units", "the units used in the app", containerLow, primary, onSurface, surface,
            Icons.pie_chart_outline, settings,
            UnitsPage(colors: colors, settings: settings, image: image, updateMainPage: updatePage),
            context, updatePage),
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
        HapticFeedback.mediumImpact();
        updatePage("Color mode", name);
      },
      child: Container(
        padding: const EdgeInsets.only(top: 22, bottom: 22, left: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? primary : highlight,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 18, color: selected ? highlight : primary,),
            ),
            comfortatext(name, 18, settings, color: selected ? highlight : primary)
          ],
        ),
      ),
    ),
  );
}

class AppearancePage extends StatefulWidget {
  final settings;
  final image;
  final allColors;
  final updateMainPage;

  const AppearancePage({Key? key, required this.allColors, required this.settings,
    required this.image, required this.updateMainPage})
      : super(key: key);

  @override
  _AppearancePageState createState() =>
      _AppearancePageState(image: image, settings: settings, allColors: allColors,
          updateMainPage: updateMainPage);
}

class _AppearancePageState extends State<AppearancePage> {

  final image;
  final settings;
  final allColors;
  final updateMainPage;

  _AppearancePageState({required this.image, required this.settings, required this.allColors, required this.updateMainPage});

  Map<String, String> copySettings = {};

  @override
  void initState() {
    super.initState();

    copySettings = settings;
  }

  void updatePage(String name, String to) {
    setState(() {
      updateMainPage(name, to);
      copySettings[name] = to;
    });
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    String x = "light";
    if (copySettings["Color mode"] == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      x = brightness == Brightness.dark ? "dark" : "light";
    }
    else {
      x = copySettings["Color mode"] ?? "light";
    }

    final colors = allColors[["original", "colorful", "mono", "light", "dark"]
        .indexOf(x)];

    Color highlight = colors[7];
    Color primaryLight = colors[2];
    Color primary = colors[1];
    Color onSurface = colors[4];
    Color surface = colors[0];

    Color colorPop = colors[12];
    Color descColor = colors[13];

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
                      height: 350,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              padding: const EdgeInsets.only(top: 10, right: 4, left: 4, bottom: 15),
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
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Container(
                                width: 150,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: onSurface,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10, top: 8),
                              child: Container(
                                width: 70,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: primaryLight,
                                ),
                              ),
                            )
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
                          ColorThemeButton("auto", Icons.brightness_6_rounded, highlight, primary, settings, updatePage),
                        ]
                    )
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 30),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorThemeButton("original", Icons.circle_outlined, highlight, primary, settings, updatePage),
                          ColorThemeButton("colorful", Icons.circle, highlight, primary, settings, updatePage),
                          ColorThemeButton("mono", Icons.invert_colors_on_outlined, highlight, primary, settings, updatePage),
                        ]
                    )
                ),

                settingEntry(Icons.colorize_rounded, "Color source", settings, highlight, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(Icons.landscape_outlined, "Image source", settings, highlight, updatePage,
                    onSurface, primaryLight, primary),
                const SizedBox(height: 70,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UnitsPage extends StatefulWidget {
  final settings;
  final image;
  final colors;
  final updateMainPage;

  const UnitsPage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage})
      : super(key: key);

  @override
  _UnitsPageState createState() =>
      _UnitsPageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage);
}

class _UnitsPageState extends State<UnitsPage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;

  _UnitsPageState({required this.image, required this.settings, required this.colors, required this.updateMainPage});

  @override
  void initState() {
    super.initState();
  }

  void updatePage(String name, String to) {
    setState(() {
      updateMainPage(name, to);
    });
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    Color highlight = colors[7];
    Color primaryLight = colors[2];
    Color primary = colors[1];
    Color onSurface = colors[4];
    Color surface = colors[0];

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
                "Units", 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60),
              child: Column(
                children: [
                  settingEntry(CupertinoIcons.thermometer, "Temperature", settings, highlight, updatePage,
                      onSurface, primaryLight, primary),
                  settingEntry(Icons.water_drop_outlined, "Precipitation", settings, highlight, updatePage,
                      onSurface, primaryLight, primary),
                  settingEntry(CupertinoIcons.wind, "Wind", settings, highlight, updatePage,
                      onSurface, primaryLight, primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class GeneralSettingsPage extends StatefulWidget {
  final settings;
  final image;
  final colors;
  final updateMainPage;

  const GeneralSettingsPage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage})
      : super(key: key);

  @override
  _GeneralSettingsPageState createState() =>
      _GeneralSettingsPageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage);
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;

  _GeneralSettingsPageState({required this.image, required this.settings, required this.colors, required this.updateMainPage});

  @override
  void initState() {
    super.initState();
  }

  void updatePage(String name, String to) {
    setState(() {
      updateMainPage(name, to);
    });
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    Color highlight = colors[7];
    Color primaryLight = colors[2];
    Color primary = colors[1];
    Color onSurface = colors[4];
    Color surface = colors[0];

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
                "General", 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60),
              child: Column(
                children: [
                  settingEntry(Icons.access_time_filled_sharp, "Time mode", settings, highlight, updatePage,
                      onSurface, primaryLight, primary),
                  settingEntry(CupertinoIcons.textformat_size, "Font size", settings, highlight, updatePage,
                      onSurface, primaryLight, primary),

                  settingEntry(Icons.manage_search_outlined, "Search provider", settings, highlight, updatePage,
                      onSurface, primaryLight, primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LangaugePage extends StatefulWidget {
  final settings;
  final image;
  final colors;
  final updateMainPage;

  const LangaugePage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage})
      : super(key: key);

  @override
  _LangaugePageState createState() =>
      _LangaugePageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage);
}

class _LangaugePageState extends State<LangaugePage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;

  _LangaugePageState({required this.image, required this.settings, required this.colors, required this.updateMainPage});


  @override
  void initState() {
    super.initState();
  }

  void updatePage(String name, String to) {
    setState(() {
      updateMainPage(name, to);
    });
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    Color primary = colors[1];
    Color onSurface = colors[4];
    Color surface = colors[0];

    String selected = settings["Language"] ?? "English";
    List<String> options = settingSwitches["Language"]!;

    void onTap(value) {
      setState(() {
        HapticFeedback.mediumImpact();
        if (value != null) {
          settings["Language"] = value;
          updateMainPage("Language", value);
        }
      });
    }

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
                translation("Language", selected), 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 30, left: 10, right: 20, bottom: 40),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  onTap: () {
                    onTap(options[index]);
                  },
                  title: comfortatext(options[index], 20, settings, color: onSurface),
                  leading: Radio<String>(
                    fillColor: WidgetStateProperty.all(primary),
                    value: options[index],
                    groupValue: selected,
                    onChanged: (String? value) {
                      onTap(value);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}