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
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

class MainSettingEntry extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Widget? pushTo;

  const MainSettingEntry({super.key, required this.title, required this.desc, required this.icon, this.pushTo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          HapticFeedback.selectionClick();
          if (pushTo != null) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => pushTo!)
            );
          }
          /*
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => pushTo)
          );

           */
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 13, bottom: 13),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              circleBorderIcon(icon, context),
              const SizedBox(width: 20,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 21, height: 1.2),),
                    Text(desc, style: TextStyle(color: Theme.of(context).colorScheme.outline,
                        fontSize: 15, height: 1.2),)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class NewSettings extends StatelessWidget {
  const NewSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
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
            MainSettingEntry(
              title: AppLocalizations.of(context)!.appearance,
              desc: AppLocalizations.of(context)!.appearanceSettingDesc,
              icon: Icons.palette_outlined,
              pushTo: const AppearancePage(),
            ),
            MainSettingEntry(
              title: AppLocalizations.of(context)!.general,
              desc: AppLocalizations.of(context)!.generalSettingDesc,
              icon: Icons.tune,
              pushTo: const GeneralSettingsPage(),
            ),
            MainSettingEntry(
              title: AppLocalizations.of(context)!.language,
              desc: AppLocalizations.of(context)!.languageSettingDesc,
              icon: Icons.language,
              pushTo: const LanguagePage(),
            ),
            MainSettingEntry(
              title: AppLocalizations.of(context)!.units,
              desc: AppLocalizations.of(context)!.unitsSettingdesc,
              icon: Icons.straighten,
              pushTo: const UnitsPage(),
            ),
            MainSettingEntry(
              title: AppLocalizations.of(context)!.layout,
              desc: AppLocalizations.of(context)!.layoutSettingDesc,
              icon: Icons.widgets_outlined
            ),
            MainSettingEntry(
              title: AppLocalizations.of(context)!.about,
              desc: AppLocalizations.of(context)!.aboutSettingsDesc,
              icon: Icons.info_outline,
              pushTo: const AboutPage(),
            ),
          ],
        ),
      ),
    );
  }
}


class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {

    String colorSource = context.select((ThemeProvider p) => p.getColorSource);
    String customColorHex = context.select((ThemeProvider p) => p.getThemeSeedColorHex);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                }),
            title: Text(AppLocalizations.of(context)!.appearance,
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                      /*
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: Container(
                          height: 190,
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Stack(
                              children: [
                                ParrallaxBackground(image: image, color: Theme.of(context).colorScheme.surface),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      comfortatext("${unitConversion(16, settings["Temperature"]!).toInt()}°", 67,
                                          settings, color: Theme.of(context).colorScheme.colorPop, weight: FontWeight.w200),
                                      comfortatext(localizations.clearSky, 26,
                                          settings, color: Theme.of(context).colorScheme.descColor, weight: FontWeight.w400)
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),

                       */

                      const Padding(
                        padding: EdgeInsets.only(left: 1, bottom: 14, top: 30),
                        child: Text("app theme", style: TextStyle(fontSize: 17),)
                      ),

                      SegmentedButton(
                        selected: <String>{context.watch<ThemeProvider>().getBrightness},
                        onSelectionChanged: (Set<String> newSelection) {
                          HapticFeedback.mediumImpact();
                          context.read<ThemeProvider>().setBrightness(newSelection.first);
                        },
                        segments: const [
                          ButtonSegment(
                            icon: Icon(Icons.light_mode_outlined),
                            value: "light",
                            label: Text("light", style: TextStyle(fontSize: 18),),
                          ),
                          ButtonSegment(
                            icon: Icon(Icons.dark_mode_outlined),
                            value: "dark",
                            label: Text("dark", style: TextStyle(fontSize: 18),),
                          ),
                          ButtonSegment(
                            icon: Icon(Icons.brightness_6_outlined),
                            value: "auto",
                            label: Text("auto", style: TextStyle(fontSize: 18),),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      SettingsEntry(
                        icon: Icons.download_for_offline_outlined,
                        text: AppLocalizations.of(context)!.imageSource,
                        rawText: 'Image source',
                        selected: context.select((SettingsProvider p) => p.getImageSource),
                        update: context.read<SettingsProvider>().setImageSource,
                      ),

                      SettingsEntry(
                        icon: Icons.colorize,
                        text: AppLocalizations.of(context)!.colorSource,
                        rawText: 'Color source',
                        selected: colorSource,
                        update: context.read<ThemeProvider>().setColorSource,
                      ),

                      const SizedBox(height: 30,),

                      if (colorSource == "custom") SizedBox(
                        height: 65,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: settingSwitches["Custom color"]!.length,
                          itemBuilder: (BuildContext context, int index) {
                            String name = settingSwitches["Custom color"]![index];
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.read<ThemeProvider>().setCustomColorScheme(name);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Color(getColorFromHex(name)),
                                            borderRadius: BorderRadius.circular(33)
                                        ),
                                      ),
                                      if (customColorHex == name) const Center(
                                          child: Icon(Icons.check, color: WHITE,))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20,),

                      //settingEntry(Icons.colorize_rounded, localizations.colorSource, settings, palette, updatePage, 'Color source', context),

                      /*
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

                       */
                      /*
                      settingEntry(Icons.image_outlined, localizations.imageSource, settings, palette, updatePage, 'Image source', context),

                       */
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

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

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
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                }),
            title: Text(AppLocalizations.of(context)!.units,
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30),
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

                      SettingsEntry(
                          icon: Icons.ac_unit,
                          text: AppLocalizations.of(context)!.temperature,
                          rawText: 'Temperature',
                          selected: context.select((SettingsProvider p) => p.getTempUnit),
                          update: context.read<SettingsProvider>().setTempUnit,
                      ),
                      SettingsEntry(
                        icon: Icons.water_drop_outlined,
                        text: AppLocalizations.of(context)!.precipitaion,
                        rawText: 'Precipitation',
                        selected: context.select((SettingsProvider p) => p.getPrecipUnit),
                        update: context.read<SettingsProvider>().setPrecipUnit,
                      ),
                      SettingsEntry(
                        icon: Icons.air,
                        text: AppLocalizations.of(context)!.windCapital,
                        rawText: 'Wind',
                        selected: context.select((SettingsProvider p) => p.getWindUnit),
                        update: context.read<SettingsProvider>().setWindUnit,
                      ),

                      /*
                      settingEntry(Icons.device_thermostat, localizations.temperature, copySettings, palette, updatePage, 'Temperature', context),
                      settingEntry(Icons.water_drop_outlined, localizations.precipitaion, copySettings, palette, updatePage, 'Precipitation', context),
                      settingEntry(Icons.air, localizations.windCapital, copySettings, palette, updatePage, 'Wind', context),

                       */
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

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

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
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              }),
            title: Text(AppLocalizations.of(context)!.general,
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
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

                      SettingsEntry(
                        icon: Icons.access_time_outlined,
                        text: AppLocalizations.of(context)!.timeMode,
                        rawText: 'Time mode',
                        selected: context.select((SettingsProvider p) => p.getTimeMode),
                        update: context.read<SettingsProvider>().setTimeMode,
                      ),

                      SettingsEntry(
                        icon: Icons.date_range,
                        text: AppLocalizations.of(context)!.dateFormat,
                        rawText: 'Date format',
                        selected: context.select((SettingsProvider p) => p.getDateFormat),
                        update: context.read<SettingsProvider>().setDateFormat,
                      ),

                      SwitchSettingEntry(
                          icon: Icons.vibration,
                          text: AppLocalizations.of(context)!.radarHaptics,
                          selected: context.select((SettingsProvider p) => p.getRadarHapticsOn),
                          update: context.read<SettingsProvider>().setRadarHaptics,
                      ),

                      SettingsEntry(
                        icon: Icons.manage_search,
                        text: AppLocalizations.of(context)!.searchProvider,
                        rawText: 'Search provider',
                        selected: context.select((SettingsProvider p) => p.getSearchProvider),
                        update: context.read<SettingsProvider>().setSearchProvider,
                      ),

                      /*
                      settingEntry(Icons.access_time_outlined, localizations.timeMode, copySettings, palette, updatePage, 'Time mode', context),
                      settingEntry(Icons.date_range, localizations.dateFormat, copySettings, palette, updatePage, 'Date format', context),
                      settingEntry(Icons.format_size, localizations.fontSize, copySettings, palette, updatePage, 'Font size', context),
                      settingEntry(Icons.manage_search_outlined, localizations.searchProvider, copySettings, palette, updatePage, 'Search provider', context),
                      settingEntry(Icons.vibration_rounded, localizations.radarHaptics, copySettings, palette, updatePage, 'Radar haptics', context),

                       */
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

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {

    String selectedLocale = context.select((SettingsProvider p) => p.getLocaleName);

    List<String> options = settingSwitches["Language"]!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                }),
            title: Text(AppLocalizations.of(context)!.language, style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 30),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _launchUrl("https://hosted.weblate.org/engage/overmorrow-weather/");
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(70),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Row(
                      children: [
                        Text(AppLocalizations.of(context)!.helpTranslate,
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 21)),
                        const Spacer(),
                        Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.tertiary, size: 23,)
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
                            HapticFeedback.mediumImpact();
                            context.read<SettingsProvider>().setLocale(options[index]);
                          },
                          title: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12, left: 13),
                            child: Text(options[index], style: const TextStyle(fontSize: 20),)
                          ),
                          contentPadding: EdgeInsets.zero,
                          trailing: Radio<String>(
                            fillColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                            value: options[index],
                            groupValue: selectedLocale,
                            onChanged: (String? value) {
                              HapticFeedback.mediumImpact();
                              context.read<SettingsProvider>().setLocale(options[index]);
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