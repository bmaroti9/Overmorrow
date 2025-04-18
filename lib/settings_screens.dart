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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:url_launcher/url_launcher.dart';

import 'decoders/decode_wapi.dart';
import 'decoders/extra_info.dart';
import 'main_ui.dart';
import '../l10n/app_localizations.dart';

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

Widget mainSettingEntry(String title, String desc, Color highlight, Color primary, Color onSurface, Color surface,
    IconData icon, settings, Widget pushTo, context, updatePage) {
  return Padding(
    padding: const EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 5),
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
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Icon(icon, color: primary, size: 24,),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: comfortatext(title, 21, settings, color: onSurface),
                  ),
                  comfortatext(desc, 15, settings, color: onSurface),
                ],
              ),
            )
          ],
        )
      ),
    ),
  );
}

Widget NewSettings(Map<String, String> settings, Function updatePage, Image image, List<Color> colors, context, colornotify) {

  Color containerLow = colors[6];
  Color onSurface = colors[4];
  Color primary = colors[1];
  Color primaryLight = colors[2];
  Color surface = colors[0];
  Color onPrimaryLight = colors[10];

  AppLocalizations localizations = AppLocalizations.of(context)!;

  print(("prime", primary));

  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 20),
    child: Column(
      children: [
        mainSettingEntry(localizations.appearance, localizations.appearanceSettingDesc,
            containerLow, primary, onSurface, surface, Icons.palette_outlined, settings,
            AppearancePage(settings: settings, image: image, colors: colornotify, updateMainPage: updatePage,
                localizations: localizations),
            context, updatePage
        ),
        mainSettingEntry(localizations.general, localizations.generalSettingDesc,
            containerLow, primary, onSurface, surface, Icons.settings_applications, settings,
            GeneralSettingsPage(colors: colors, settings: settings, image: image, updateMainPage: updatePage,
              localizations: localizations,),
            context, updatePage),
        mainSettingEntry(localizations.language, localizations.languageSettingDesc,
            containerLow, primary, onSurface, surface, Icons.language, settings,
            LangaugePage(colors: colors, settings: settings, image: image, updateMainPage: updatePage, highlight:
            primaryLight, onPrimaryLight: onPrimaryLight,),
            context, updatePage),
        mainSettingEntry(localizations.units, localizations.unitsSettingdesc,
            containerLow, primary, onSurface, surface, Icons.pie_chart_outline, settings,
            UnitsPage(colors: colors, settings: settings, image: image, updateMainPage: updatePage,
            localizations: localizations,),
            context, updatePage),
        mainSettingEntry(localizations.layout, localizations.layoutSettingDesc,
            containerLow, primary, onSurface, surface,
            Icons.splitscreen, settings,
            LayoutPage(colors: colors, settings: settings, image: image,
              updateMainPage: updatePage, localizations: localizations,),
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
  final colors;
  final updateMainPage;
  final localizations;

  const AppearancePage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _AppearancePageState createState() =>
      _AppearancePageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _AppearancePageState extends State<AppearancePage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;
  final localizations;

  _AppearancePageState({required this.image, required this.settings, required this.colors, required this.updateMainPage,
  required this.localizations});

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

    return ValueListenableBuilder(
      valueListenable: colors,
      builder: (context, value, child) {
        return AppearanceSelector(image: image,
            settings: copySettings,
            colors: value,
            updatePage: updatePage,
            localizations: localizations,
            goBack: goBack);
      }
    );

  }
}


class AppearanceSelector extends StatelessWidget {

  final image;
  final settings;
  final colors;
  final updatePage;
  final localizations;
  final goBack;

  AppearanceSelector({required this.image, required this.settings, required this.colors,
    required this.updatePage, required this.localizations, required this.goBack});


  @override
  Widget build(BuildContext context) {

    Color highlight = colors[7];
    Color primaryLight = colors[2];
    Color primary = colors[1];
    Color onSurface = colors[4];
    Color surface = colors[0];

    Color colorPop = colors[12];
    Color descColor = colors[13];

    print(("primary", primary));

    return Material(
      color: surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                localizations.appearance, 30, settings,
                color: primary),
            backgroundColor: surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 10),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          color: highlight
                      ),
                      width: 240,
                      height: 350,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 240,
                              child: Stack(
                                children: [
                                  ParrallaxBackground(image: image, color: surface),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10, bottom: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        comfortatext("${unit_coversion(32, settings["Temperature"]!).toInt()}°", 42,
                                            settings, color: colorPop, weight: FontWeight.w300),
                                        comfortatext(localizations.clearSky, 24,
                                            settings, color: descColor, weight: FontWeight.w600)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(top: 15, right: 4, left: 4, bottom: 15),
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

                settingEntry(Icons.colorize_rounded, localizations.colorSource, settings, highlight, updatePage,
                    onSurface, primaryLight, primary, 'Color source'),
                if (settings["Color source"] == "custom") SizedBox(
                  height: 80,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10, top: 10),
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: settingSwitches["Custom color"]!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          updatePage("Custom color", settingSwitches["Custom color"]![index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Color(getColorFromHex(settingSwitches["Custom color"]![index])),
                                      borderRadius: BorderRadius.circular(100)
                                  ),
                                ),
                                if (settings["Custom color"] == settingSwitches["Custom color"]![index]) const Center(
                                    child: Icon(Icons.check, color: WHITE,))
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                settingEntry(Icons.landscape_outlined, localizations.imageSource, settings, highlight, updatePage,
                    onSurface, primaryLight, primary, 'Image source'),
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
  final localizations;

  const UnitsPage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _UnitsPageState createState() =>
      _UnitsPageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _UnitsPageState extends State<UnitsPage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;
  final localizations;

  _UnitsPageState({required this.image, required this.settings, required this.colors,
    required this.updateMainPage, required this.localizations});

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
            IconButton(icon: Icon(Icons.arrow_back, color: primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                localizations.units, 30, settings,
                color: primary),
            backgroundColor: surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60),
              child: Column(
                children: [
                  settingEntry(CupertinoIcons.thermometer, localizations.temperature, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Temperature'),
                  settingEntry(Icons.water_drop_outlined, localizations.precipitaion, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Precipitation'),
                  settingEntry(CupertinoIcons.wind, localizations.windCapital, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Wind'),
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
  final localizations;

  const GeneralSettingsPage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _GeneralSettingsPageState createState() =>
      _GeneralSettingsPageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;
  final localizations;

  _GeneralSettingsPageState({required this.image, required this.settings, required this.colors,
    required this.updateMainPage, required this.localizations});

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
            IconButton(icon: Icon(Icons.arrow_back, color: primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                localizations.general, 30, settings,
                color: primary),
            backgroundColor: surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60),
              child: Column(
                children: [
                  settingEntry(Icons.access_time_outlined, localizations.timeMode, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Time mode'),
                  settingEntry(Icons.date_range, localizations.dateFormat, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Date format'),
                  settingEntry(CupertinoIcons.textformat_size, localizations.fontSize, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Font size'),

                  settingEntry(Icons.manage_search_outlined, localizations.searchProvider, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Search provider'),
                  settingEntry(Icons.vibration_rounded, localizations.radarHaptics, settings, highlight, updatePage,
                      onSurface, primaryLight, primary, 'Radar haptics'),
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
  final highlight;
  final onPrimaryLight;

  const LangaugePage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage, required this.highlight, required this.onPrimaryLight})
      : super(key: key);

  @override
  _LangaugePageState createState() =>
      _LangaugePageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage, highlight: highlight, onPrimaryLight: onPrimaryLight);
}

class _LangaugePageState extends State<LangaugePage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;
  final highlight;
  final onPrimaryLight;

  _LangaugePageState({required this.image, required this.settings, required this.colors,
    required this.updateMainPage, required this.highlight, required this.onPrimaryLight});

  String _locale = 'English';

  @override
  void initState() {
    super.initState();
    _locale = settings["Language"];
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
          _locale = value;
        }
      });
    }

    return Localizations.override(
      context: context,
      locale: languageNameToLocale[_locale] ?? const Locale('en'),
      child: TranslationSelection(settings: settings, goBack: goBack, onSurface: onSurface,
      primary: primary, onTap: onTap, options: options, selected: selected, surface: surface,
        highlight: highlight, onPrimaryLight: onPrimaryLight,)
    );
  }
}

class TranslationSelection extends StatelessWidget {
  final surface;
  final onSurface;
  final onPrimaryLight;
  final goBack;
  final onTap;
  final primary;
  final settings;
  final options;
  final selected;
  final highlight;


  const TranslationSelection({super.key, this.settings, this.goBack, this.onSurface, this.primary,
  this.onTap, this.options, this.selected, this.surface, this.highlight, this.onPrimaryLight});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                AppLocalizations.of(context)!.language, 30, settings,
                color: primary),
            backgroundColor: surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 25, right: 25, bottom: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _launchUrl("https://hosted.weblate.org/engage/overmorrow-weather/");
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: highlight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Row(
                      children: [
                        comfortatext(AppLocalizations.of(context)!.helpTranslate, 21, settings, color: onPrimaryLight),
                        const Spacer(),
                        Icon(Icons.arrow_forward, color: onPrimaryLight, size: 21,)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10, left: 25, right: 25, bottom: 40),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  onTap: () {
                    onTap(options[index]);
                  },
                  title: Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: comfortatext(options[index], 20, settings, color: onSurface),
                  ),
                  trailing: Radio<String>(
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



class LayoutPage extends StatefulWidget {
  final settings;
  final image;
  final colors;
  final updateMainPage;
  final localizations;

  const LayoutPage({Key? key, required this.colors, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _LayoutPageState createState() =>
      _LayoutPageState(image: image, settings: settings, colors: colors,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _LayoutPageState extends State<LayoutPage> {

  final image;
  final settings;
  final colors;
  final updateMainPage;
  final AppLocalizations localizations;

  _LayoutPageState({required this.image, required this.settings, required this.colors,
    required this.updateMainPage, required this.localizations});

  late List<String> _items;

  //also the default order
  static const allNames = ["sunstatus", "rain indicator", "alerts", "air quality", "radar", "forecast", "daily"];

  List<String> removed = [];

  @override
  void initState() {
    super.initState();
    _items = settings["Layout order"] == "" ? [] : settings["Layout order"].split(",");

    for (int i = 0; i < allNames.length; i++) {
      if (!_items.contains(allNames[i])) {
        removed.add(allNames[i]);
      }
    }

    print(removed);
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
    Color outline = colors[5];

    return Material(
      color: surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primary),
              onPressed: () {
                goBack();
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(Icons.restore, color: primary, size: 26,),
                  onPressed: () {
                    setState(() {
                      _items = allNames.toList();
                      removed = [];
                      updatePage('Layout order', _items.join(","));
                    });
                  },
                ),
              ),
            ],
            title: comfortatext(localizations.layout, 30, settings, color: primary),
            backgroundColor: surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 50),
                  children: <Widget>[
                    for (int index = 0; index < _items.length; index += 1)
                      Container(
                        key: Key("$index"),
                        color: surface,
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: highlight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          height: 70,
                          padding: const EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              comfortatext(_items[index], 19, settings, color: onSurface),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    print((_items[index], _items));
                                    setState(() {
                                      removed.add(_items[index]);
                                      _items.remove(_items[index]);
                                      updatePage('Layout order', _items.join(","));
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primaryLight,
                                      borderRadius: BorderRadius.circular(40)
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.remove_rounded, color: highlight, size: 21,),
                                  ),
                                ),
                              ),
                              Icon(Icons.reorder_rounded, color: primary, size: 21,),
                            ],
                          ),
                        ),
                      ),
                  ],
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final String item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                      updatePage('Layout order', _items.join(","));
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top:0, left: 20, right: 20),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(removed.length, (i) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _items.add(removed[i]);
                            removed.remove(removed[i]);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(width: 1.2, color: outline)
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: primaryLight, size: 21,),
                              comfortatext(removed[i], 16, settings, color: onSurface),
                            ],
                          ),
                        ),
                      );
                    }),
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