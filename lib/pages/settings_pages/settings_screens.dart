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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:overmorrow/services/color_service.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/pages/settings_pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
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
                                          child: Icon(Icons.check, color: Colors.white,))
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
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                }),
            title: Text(AppLocalizations.of(context)!.units,
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
                HapticFeedback.lightImpact();
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

                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 14),
                        child: Row(
                          children: [
                            circleBorderIcon(Icons.format_size_rounded, context),
                            const SizedBox(width: 20,),
                            Expanded(child: Text(AppLocalizations.of(context)!.fontSize,
                              style: const TextStyle(fontSize: 20, height: 1.2),),),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 19,
                                thumbColor: Theme.of(context).colorScheme.secondary,
                                activeTrackColor: Theme.of(context).colorScheme.secondary,

                                year2023: false,
                              ),
                              child: Slider(
                                min: 0.7,
                                max: 1.3,
                                divisions: 10,
                                value: context.select((SettingsProvider p) => p.getTextScale),
                                  onChanged: (double value) {
                                    context.read<SettingsProvider>().setTextScale(value);
                                  }
                              ),
                            ),
                          ],
                        ),
                      ),
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

class BackgroundUpdatesPage extends StatefulWidget {

  const BackgroundUpdatesPage({Key? key}) : super(key: key);

  @override
  _BackgroundUpdatesPageState createState() =>
      _BackgroundUpdatesPageState();
}

class _BackgroundUpdatesPageState extends State<BackgroundUpdatesPage> {

  String widgetBackgroundState = "--";

  //this is all for debugging the background worker
  Future<void> getWidgetBackgroundState() async {
    widgetBackgroundState = (await HomeWidget.getWidgetData<String>("widget.backgroundUpdateState", defaultValue: "unknown")) ?? "unknown";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      getWidgetBackgroundState();
    });
  }

  @override
  Widget build(BuildContext context) {

    final ifnot = ["{\n        \"id\": 2651922,\n        \"name\": \"Nashville\",\n        \"region\": \"Tennessee\",\n        \"country\": \"United States of America\",\n        \"lat\": 36.17,\n        \"lon\": -86.78,\n        \"url\": \"nashville-tennessee-united-states-of-america\"\n    }"];
    final favorites = PreferenceUtils.getStringList('favorites', ifnot);

    final currentLocationName = PreferenceUtils.getString("LastKnownPositionName", "unknown");
    final currentLocationLatLon = PreferenceUtils.getString("LastKnownPositionCord", "unknown");
    bool isCurrentSelected = context.select((SettingsProvider p) => p.getOngoingNotificationPlace) == "Current Location";

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
            title: Text(AppLocalizations.of(context)!.backgroundUpdates,
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
                      SwitchSettingEntry(
                        icon: Icons.published_with_changes,
                        text: AppLocalizations.of(context)!.ongoingNotification,
                        selected: context.select((SettingsProvider p) => p.getOngoingNotificationOn),
                        update: context.read<SettingsProvider>().setOngoingNotification,
                      ),

                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                if (currentLocationName != "unknown" && currentLocationLatLon != "unknown") {
                                  HapticFeedback.lightImpact();
                                  context.read<SettingsProvider>().setOngoingNotificationPlaceAndLatLon("Current Location", currentLocationLatLon);
                                }
                              },
                              child: Container(
                                decoration: (isCurrentSelected) ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Theme.of(context).colorScheme.tertiaryContainer
                                ) : const BoxDecoration(),
                                padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text("Current Location ($currentLocationName)", style: const TextStyle(
                                          fontSize: 16, height: 1.2),),
                                    ),
                                    if (isCurrentSelected) Icon(
                                      Icons.check,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      size: 17,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            
                            Column(
                              children: List.generate(favorites.length, (index) {
                                var split = json.decode(favorites[index]);
                                String name = split["name"];
                            
                                bool isSelected = context.select((SettingsProvider p) => p.getOngoingNotificationPlace) == name;
                            
                                return GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.read<SettingsProvider>().setOngoingNotificationPlaceAndLatLon(name, '${split["lat"]}, ${split["lon"]}');
                                  },
                                  child: Container(
                                    decoration: isSelected ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Theme.of(context).colorScheme.tertiaryContainer
                                    ) : const BoxDecoration(),
                                    padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(name, style: const TextStyle(
                                            fontSize: 16, height: 1.2),),
                                        ),
                                        if (isSelected) Icon(
                                          Icons.check,
                                          color: Theme.of(context).colorScheme.tertiary,
                                          size: 17,
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              })
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 4),
                        child: Text(AppLocalizations.of(context)!.weatherProvderLowercase),
                      ),

                      SegmentedButton(
                        multiSelectionEnabled: false,
                        segments: const <ButtonSegment>[
                          ButtonSegment(
                            value: "open-meteo",
                            label: Text('open-meteo'),
                          ),
                          ButtonSegment(
                            value: "weatherapi",
                            label: Text('weatherapi'),
                          ),
                          ButtonSegment(
                            value: "met-norway",
                            label: Text('met-norway'),
                          ),
                        ],
                        selected: {context.select((SettingsProvider p) => p.getOngoingNotificationProvider)},
                        onSelectionChanged: (newSelection) {
                          HapticFeedback.lightImpact();
                          context.read<SettingsProvider>().setOngoingNotificationProvider(newSelection.first);
                        },
                      ),

                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {

                                return AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  content: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return Column(
                                        children: [
                                          Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.tertiary),
                                          const SizedBox(height: 40,),
                                          Text(widgetBackgroundState,
                                              style: const TextStyle(fontSize: 18)),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              }
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(50)
                          ),
                          margin: const EdgeInsets.only(top: 40, bottom: 100),
                          padding: const EdgeInsets.all(14),
                          child: const Row(
                            children: [
                              Text("worker logs",
                                  style: TextStyle(fontSize: 18)),
                              Spacer(),
                              Icon(Icons.open_in_new, size: 18,),
                            ],
                          ),
                        ),
                      ),
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
                  HapticFeedback.lightImpact();
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
                  HapticFeedback.lightImpact();
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

class LayoutPage extends StatelessWidget {

  const LayoutPage({super.key});

  //also the default order
  static const allNames = ["sunstatus", "rain indicator", "hourly", "alerts", "radar", "daily", "air quality"];

  @override
  Widget build(BuildContext context) {

    List<String> _items = context.watch<SettingsProvider>().getLayout;

    List<String> removed = [];
    for (int i = 0; i < allNames.length; i++) {
      if (!_items.contains(allNames[i])) {
        removed.add(allNames[i]);
      }
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(Icons.restore, color: Theme.of(context).colorScheme.primary, size: 26,),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    context.read<SettingsProvider>().setLayoutOrder(allNames);
                  },
                ),
              ),
            ],
            title: Text(AppLocalizations.of(context)!.layout, style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(33),
                          ),
                          height: 67,
                          padding: const EdgeInsets.only(top: 6, bottom: 6, left: 20, right: 10),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(Icons.drag_indicator, color: Theme.of(context).colorScheme.outline,),
                              ),
                              Expanded(
                                child: Text(_items[index], style: const TextStyle(fontSize: 19),),
                              ),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.heavyImpact();
                                  final List<String> newOrder = List.from(_items);
                                  newOrder.removeAt(index);
                                  context.read<SettingsProvider>().setLayoutOrder(newOrder);
                                },
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Theme.of(context).colorScheme.tertiary, size: 23,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final List<String> newOrder = List.from(_items);
                    final String item = newOrder.removeAt(oldIndex);
                    newOrder.insert(newIndex, item);
                    context.read<SettingsProvider>().setLayoutOrder(newOrder);
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
                          final List<String> newOrder = List.from(_items);
                          newOrder.add(removed[i]);
                          context.read<SettingsProvider>().setLayoutOrder(newOrder);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(width: 2, color: Theme.of(context).colorScheme.outlineVariant)
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary, size: 22,),
                              Padding(
                                padding: const EdgeInsets.only(left: 3, right: 3),
                                child: Text(removed[i], style: const TextStyle(fontSize: 17),),
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