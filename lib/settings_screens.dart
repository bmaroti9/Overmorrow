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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:overmorrow/about_page.dart';
import 'package:overmorrow/services/color_service.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:url_launcher/url_launcher.dart';

import 'decoders/decode_wapi.dart';
import 'main_ui.dart';
import '../l10n/app_localizations.dart';

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

Widget mainSettingEntry(String title, String desc, ColorScheme palette,
    IconData icon, settings, Widget pushTo, context, updatePage) {
  return Padding(
    padding: const EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 5),
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pushTo)
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 13, bottom: 13),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18, left: 15),
              child: Icon(icon, color: palette.primary, size: 24,),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: comfortatext(title, 21, settings, color: palette.onSurface),
                  ),
                  comfortatext(desc, 15, settings, color: palette.outline),
                ],
              ),
            )
          ],
        ),
      ),
    ),
  );
}

Widget NewSettings(Map<String, String> settings, Function updatePage, Image image, ColorScheme palette, context, colornotify) {

  AppLocalizations localizations = AppLocalizations.of(context)!;

  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 20),
    child: AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(
            child: widget,
          ),
        ),
        children: [
          mainSettingEntry(localizations.appearance, localizations.appearanceSettingDesc,
              palette, Icons.palette_outlined, settings,
              AppearancePage(settings: settings, image: image, colornotify: colornotify, updateMainPage: updatePage,
                  localizations: localizations),
              context, updatePage
          ),
          mainSettingEntry(localizations.general, localizations.generalSettingDesc,
              palette, Icons.tune, settings,
              GeneralSettingsPage(palette: palette, settings: settings, image: image, updateMainPage: updatePage,
                localizations: localizations,),
              context, updatePage),
          mainSettingEntry(localizations.language, localizations.languageSettingDesc,
              palette, Icons.language, settings,
              LangaugePage(palette: palette, settings: settings, image: image, updateMainPage: updatePage),
              context, updatePage),
          mainSettingEntry(localizations.units, localizations.unitsSettingdesc,
              palette, Icons.straighten, settings,
              UnitsPage(palette: palette, settings: settings, image: image, updateMainPage: updatePage,
              localizations: localizations,),
              context, updatePage),
          mainSettingEntry(localizations.layout, localizations.layoutSettingDesc,
              palette, Icons.widgets_outlined, settings,
              LayoutPage(palette: palette, settings: settings, image: image, updateMainPage: updatePage,
                localizations: localizations,), context, updatePage),
          mainSettingEntry(localizations.about, "about this app",
              palette, Icons.info_outline, settings,
              AboutPage(settings: settings, palette: palette), context, updatePage),
          ],
        ),
      ),
    )
  );
}

class AppearancePage extends StatefulWidget {
  final settings;
  final image;
  final colornotify;
  final updateMainPage;
  final localizations;

  const AppearancePage({Key? key, required this.colornotify, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _AppearancePageState createState() =>
      _AppearancePageState(image: image, settings: settings, colornotify: colornotify,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _AppearancePageState extends State<AppearancePage> {

  final image;
  final settings;
  final colornotify;
  final updateMainPage;
  final localizations;

  _AppearancePageState({required this.image, required this.settings, required this.colornotify, required this.updateMainPage,
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
      valueListenable: colornotify,
      builder: (context, ColorPalette value, child) {
        return AppearanceSelector(image: image,
            settings: copySettings,
            colorPalette: value,
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
  final ColorPalette colorPalette;
  final updatePage;
  final localizations;
  final goBack;

  AppearanceSelector({required this.image, required this.settings, required this.colorPalette,
    required this.updatePage, required this.localizations, required this.goBack});

  @override
  Widget build(BuildContext context) {
    ColorScheme palette = colorPalette.palette;

    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                localizations.appearance, 30, settings,
                color: palette.primary),
            backgroundColor: palette.surface,
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
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: Container(
                          height: 190,
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Stack(
                              children: [
                                ParrallaxBackground(image: image, color: palette.surface),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      comfortatext("${unit_coversion(16, settings["Temperature"]!).toInt()}°", 67,
                                          settings, color: colorPalette.colorPop, weight: FontWeight.w200),
                                      comfortatext(localizations.clearSky, 26,
                                          settings, color: colorPalette.descColor, weight: FontWeight.w400)
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 1, bottom: 14, top: 30),
                            child: comfortatext("app theme", 17,
                              settings,
                              color: palette.onSurface),
                          ),
                        ],
                      ),

                      SegmentedButton(
                        selected: <String>{settings["Color mode"]},
                        onSelectionChanged: (Set<String> newSelection) {
                          HapticFeedback.mediumImpact();
                          updatePage("Color mode", newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: palette.surface,
                          foregroundColor: palette.primary,
                          selectedBackgroundColor: palette.secondaryContainer,
                          selectedForegroundColor: palette.primary,
                        ),
                        segments: [
                          ButtonSegment(
                            icon: const Icon(Icons.light_mode_outlined),
                            value: "light",
                            label: comfortatext("light", 18, settings, color: palette.onSurface)
                          ),
                          ButtonSegment(
                              icon: const Icon(Icons.dark_mode_outlined),
                              value: "dark",
                              label: comfortatext("dark", 18, settings, color: palette.onSurface)
                          ),
                          ButtonSegment(
                              icon: const Icon(Icons.brightness_6_outlined),
                              value: "auto",
                              label: comfortatext("auto", 18, settings, color: palette.onSurface)
                          ),
                        ],
                      ),

                      const SizedBox(height: 20,),

                      settingEntry(Icons.colorize_rounded, localizations.colorSource, settings, palette, updatePage, 'Color source', context),

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
                      settingEntry(Icons.image_outlined, localizations.imageSource, settings, palette, updatePage, 'Image source', context),
                      const SizedBox(height: 70,),
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

class UnitsPage extends StatefulWidget {
  final settings;
  final image;
  final palette;
  final updateMainPage;
  final localizations;

  const UnitsPage({Key? key, required this.palette, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _UnitsPageState createState() =>
      _UnitsPageState(image: image, settings: settings, palette: palette,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _UnitsPageState extends State<UnitsPage> {

  final image;
  final settings;
  final ColorScheme palette;
  final updateMainPage;
  final localizations;

  _UnitsPageState({required this.image, required this.settings, required this.palette,
    required this.updateMainPage, required this.localizations});

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

    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                localizations.units, 30, settings,
                color: palette.primary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60, left: 30),
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 80.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      settingEntry(Icons.device_thermostat, localizations.temperature, copySettings, palette, updatePage, 'Temperature', context),
                      settingEntry(Icons.water_drop_outlined, localizations.precipitaion, copySettings, palette, updatePage, 'Precipitation', context),
                      settingEntry(Icons.air, localizations.windCapital, copySettings, palette, updatePage, 'Wind', context),
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


class GeneralSettingsPage extends StatefulWidget {
  final settings;
  final image;
  final palette;
  final updateMainPage;
  final localizations;

  const GeneralSettingsPage({Key? key, required this.palette, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _GeneralSettingsPageState createState() =>
      _GeneralSettingsPageState(image: image, settings: settings, palette: palette,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {

  final image;
  final settings;
  final ColorScheme palette;
  final updateMainPage;
  final localizations;

  _GeneralSettingsPageState({required this.image, required this.settings, required this.palette,
    required this.updateMainPage, required this.localizations});

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

    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                localizations.general, 30, settings,
                color: palette.primary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60, left: 30),
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 80.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      settingEntry(Icons.access_time_outlined, localizations.timeMode, copySettings, palette, updatePage, 'Time mode', context),
                      settingEntry(Icons.date_range, localizations.dateFormat, copySettings, palette, updatePage, 'Date format', context),
                      settingEntry(Icons.format_size, localizations.fontSize, copySettings, palette, updatePage, 'Font size', context),
                      settingEntry(Icons.manage_search_outlined, localizations.searchProvider, copySettings, palette, updatePage, 'Search provider', context),
                      settingEntry(Icons.vibration_rounded, localizations.radarHaptics, copySettings, palette, updatePage, 'Radar haptics', context),
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

class LangaugePage extends StatefulWidget {
  final settings;
  final image;
  final palette;
  final updateMainPage;

  const LangaugePage({Key? key, required this.palette, required this.settings,
    required this.image, required this.updateMainPage})
      : super(key: key);

  @override
  _LangaugePageState createState() =>
      _LangaugePageState(image: image, settings: settings, palette: palette,
          updateMainPage: updateMainPage);
}

class _LangaugePageState extends State<LangaugePage> {

  final image;
  final settings;
  final ColorScheme palette;
  final updateMainPage;

  _LangaugePageState({required this.image, required this.settings, required this.palette,
    required this.updateMainPage});

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
      child: TranslationSelection(settings: settings, goBack: goBack, onTap: onTap, options: options, selected: selected,
        palette: palette,)
    );
  }
}

class TranslationSelection extends StatelessWidget {
  final goBack;
  final onTap;
  final settings;
  final options;
  final selected;
  final ColorScheme palette;


  const TranslationSelection({super.key, this.settings, this.goBack,
    this.onTap, this.options, this.selected, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                AppLocalizations.of(context)!.language, 30, settings,
                color: palette.primary),
            backgroundColor: palette.surface,
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
                    borderRadius: BorderRadius.circular(70),
                    color: palette.primaryFixedDim,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Row(
                      children: [
                        comfortatext(AppLocalizations.of(context)!.helpTranslate, 21, settings, color: palette.onPrimaryFixedVariant),
                        const Spacer(),
                        Icon(Icons.arrow_forward, color: palette.onPrimaryFixedVariant, size: 22,)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 40),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: ListTile(
                          onTap: () {
                            onTap(options[index]);
                          },
                          title: Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 15, left: 13),
                            child: comfortatext(options[index], 20, settings, color: palette.onSurface),
                          ),
                          contentPadding: EdgeInsets.zero,
                          trailing: Radio<String>(
                            fillColor: WidgetStateProperty.all(palette.primary),
                            value: options[index],
                            groupValue: selected,
                            onChanged: (String? value) {
                              onTap(value);
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
  final ColorScheme palette;
  final updateMainPage;
  final localizations;

  const LayoutPage({Key? key, required this.palette, required this.settings,
    required this.image, required this.updateMainPage, required this.localizations})
      : super(key: key);

  @override
  _LayoutPageState createState() =>
      _LayoutPageState(image: image, settings: settings, palette: palette,
          updateMainPage: updateMainPage, localizations: localizations);
}

class _LayoutPageState extends State<LayoutPage> {

  final image;
  final settings;
  final ColorScheme palette;
  final updateMainPage;
  final AppLocalizations localizations;

  _LayoutPageState({required this.image, required this.settings, required this.palette,
    required this.updateMainPage, required this.localizations});

  late List<String> _items;

  //also the default order
  static const allNames = ["sunstatus", "rain indicator", "hourly", "alerts", "radar", "daily", "air quality"];

  List<String> removed = [];

  @override
  void initState() {
    super.initState();
    _items = settings["Layout"] == "" ? [] : settings["Layout"].split(",");

    for (int i = 0; i < allNames.length; i++) {
      if (!_items.contains(allNames[i])) {
        removed.add(allNames[i]);
      }
    }
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

    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: palette.primary),
              onPressed: () {
                goBack();
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(Icons.restore, color: palette.primary, size: 26,),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _items = allNames.toList();
                      removed = [];
                      updatePage('Layout', _items.join(","));
                    });
                  },
                ),
              ),
            ],
            title: comfortatext(localizations.layout, 30, settings, color: palette.primary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  proxyDecorator: (child, index, animation) => Material(
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                  padding: const EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 50),
                  children: <Widget>[
                    for (int index = 0; index < _items.length; index += 1)
                      Container(
                        key: Key("$index"),
                        color: palette.surface,
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.surfaceContainer,
                            borderRadius: BorderRadius.circular(33),
                          ),
                          height: 67,
                          padding: const EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 14),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(Icons.drag_indicator, color: palette.outline,),
                              ),
                              Expanded(
                                child: comfortatext(_items[index], 19, settings, color: palette.onSurface),
                              ),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    removed.add(_items[index]);
                                    _items.remove(_items[index]);
                                    updatePage('Layout', _items.join(","));
                                  });
                                },
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: palette.primary, size: 23,
                                ),
                              )
                            ],
                          ),
                          /*
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              comfortatext(_items[index], 19, settings, color: palette.onSurface),
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
                                      color: palette.primaryContainer,
                                      borderRadius: BorderRadius.circular(40)
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.remove_rounded, color: palette.surfaceContainer, size: 21,),
                                  ),
                                ),
                              ),
                              Icon(Icons.reorder_rounded, color: palette.primary, size: 21,),
                            ],
                          ),

                           */
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
                      updatePage('Layout', _items.join(","));
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top:0, left: 20, right: 20),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(removed.length, (i) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _items.add(removed[i]);
                            removed.remove(removed[i]);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(width: 2, color: palette.outlineVariant)
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: palette.primary, size: 22,),
                              Padding(
                                padding: const EdgeInsets.only(left: 3, right: 3),
                                child: comfortatext(removed[i], 17, settings, color: palette.onSurface),
                              ),
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