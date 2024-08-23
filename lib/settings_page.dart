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
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/donation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'decoders/decode_wapi.dart';
import 'decoders/extra_info.dart';
import 'languages.dart';
import 'main.dart';
import 'main_ui.dart';
import 'ui_helper.dart';

Map<String, List<String>> settingSwitches = {
  'Language' : [
    'English', 'Español', 'Français', 'Deutsch', 'Italiano',
    'Português', 'Русский', 'Magyar', 'Polski', 'Ελληνικά', '简体中文', '日本語',
  ],
  'Temperature': ['˚C', '˚F'],
  'Precipitation': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph', 'kn'],
  'Pressure' : ['mmHg', 'inHg', 'mb', 'hPa'],
  'Time mode': ['12 hour', '24 hour'],
  'Font size': ['normal', 'small', 'very small', 'big'],

  'Color mode' : ['original', 'colorful', 'monochrome', 'light', 'dark'],

  'Color source' : ['image', 'wallpaper'],
  'Image source' : ['network', 'asset'],

  'Search provider' : ['weatherapi', 'open-meteo'],
};

String translation(String text, String language) {
  int index = languageIndex[language] ?? 0;
  String translated = mainTranslate[text]![index];
  return translated;
}

List<Color> getColors(primary, back, settings, dif, {force = "-1"}) {

  String x = force == "-1" ? settings["Color mode"] : force;

  //surface
  //primary
  //primaryLight
  //primaryLighter
  //onSurface
  //outline
  //containerLow
  //container
  //containerHigh
  //surfaceVariant
  //onPrimaryLight
  //primarySecond

  //colorpop
  //desc

  List<Color> colors = [
    primary,
    back,
    lighten2(primary, 0.8),
    darken2(primary, 0.2),
    WHITE,
    lighten2(primary, 1),
    darken(primary, 0.02),
    darken(primary, 0.04),
    darken(primary, 0.04),
    darken(primary, 0.03),
    back,
    back,

    [back, WHITE, WHITE][dif],
    WHITE
  ];

  if (x == "monochrome") {
    colors = [ //default colorful option
      primary,
      WHITE,
      WHITE,
      WHITE,
      WHITE,
      WHITE,
      darken(primary, 0.03),
      darken(primary, 0.06),
      darken(primary, 0.06),
      darken(primary, 0.03),
      primary,
      WHITE,

      WHITE,
      WHITE
    ];
  }

  if (x == "colorful") {
    colors = [ //default colorful option
      back,
      primary,
      lighten2(back, 0.73),
      darken(back, 0.1),
      lighten2(back, 0.73),
      lighten2(back, 0.73),
      darken(back, 0.02),
      darken(back, 0.04),
      darken(back, 0.04),
      darken(back, 0.03),
      primary,
      primary,

      [back, WHITE, WHITE][dif],
      WHITE
    ];
  }

  else if (x == "light") { //only the error page uses these because it's otherwise the network palette
    colors = [ //backcolor, primary, text
      WHITE,
      primary,
      lighten(primary, 0.05),
      lighten(primary, 0.15),
      BLACK,
      BLACK,
      const Color.fromARGB(250, 245, 245, 245),
      const Color.fromARGB(250, 240, 240, 240),
      const Color.fromARGB(250, 230, 230, 230),

    ];
  }

  else if (x == "dark") {
    colors = [ //backcolor, primary, text
      BLACK,
      primary,
      lighten(primary, 0.1),
      lighten(primary, 0.15),
      WHITE,
      WHITE,
      const Color.fromARGB(250, 15, 15, 15),
      const Color.fromARGB(250, 25, 25, 25),
      const Color.fromARGB(250, 35, 35, 35),
    ];
  }

  return colors;
}

List<Color> getNetworkColors(List<dynamic> palette, settings, {force = "-1"}) {
  String x = force == "-1" ? settings["Color mode"] : force;

  //surface
  //primary
  //primaryLight
  //primaryLighter
  //onSurface
  //outline
  //containerLow
  //container
  //containerHigh
  //surfaceVariant
  //onPrimaryLight
  //primarySecond

  List<Color> colors = [
    palette[0].onPrimaryFixedVariant,
    palette[0].tertiary,
    palette[0].tertiaryFixed,
    palette[0].secondaryFixed,
    palette[0].secondaryFixed,
    palette[0].outline,
    darken2(palette[0].onPrimaryFixedVariant, 0.09),
    darken2(palette[0].onPrimaryFixedVariant, 0.12),
    darken2(palette[0].onPrimaryFixedVariant, 0.2),
    darken2(palette[0].onPrimaryFixedVariant, 0.1),
    palette[0].onTertiaryFixed,
    palette[0].tertiaryFixed,

    palette[1],
    palette[2],
  ];
  if (x == "monochrome") {
    colors = [
      palette[0].onPrimaryFixedVariant,
      WHITE,
      WHITE,
      WHITE,
      palette[0].onSurface,
      WHITE,
      darken2(palette[0].onPrimaryFixedVariant, 0.09),
      darken2(palette[0].onPrimaryFixedVariant, 0.12),
      darken2(palette[0].onPrimaryFixedVariant, 0.2),
      darken2(palette[0].onPrimaryFixedVariant, 0.1),
      palette[0].onTertiaryFixed,
      WHITE,

      palette[1],
      palette[2],
    ];
  }
  else if (x == "colorful") {
    colors = [
      palette[0].onTertiaryFixedVariant,
      palette[0].primary,
      palette[0].primaryFixed,
      palette[0].secondaryFixed,
      palette[0].onSurface,
      palette[0].outline,
      darken2(palette[0].onTertiaryFixedVariant, 0.09),
      darken2(palette[0].onTertiaryFixedVariant, 0.12),
      darken2(palette[0].onTertiaryFixedVariant, 0.2),
      darken2(palette[0].onTertiaryFixedVariant, 0.1),
      palette[0].onPrimaryFixed,
      palette[0].primaryFixed,

      palette[1],
      palette[2],
    ];
  }
  else if (x == "light") {
    colors = [
      palette[0].surface,
      palette[0].primary,
      palette[0].primaryFixedDim,
      palette[0].primaryFixed,
      palette[0].onSurface,
      palette[0].outline,
      palette[0].surfaceContainerLow,
      palette[0].surfaceContainer,
      palette[0].surfaceContainerHigh,
      palette[0].surfaceContainerHighest,
      palette[0].onPrimaryFixed,
      palette[0].primaryFixedDim,

      palette[1],
      palette[2],
    ];
  }
  else if (x == "dark") {
    colors = [
      palette[0].surface,
      palette[0].primary,
      palette[0].primaryFixed,
      palette[0].primaryFixed,
      palette[0].onSurface,
      palette[0].outline,
      palette[0].surfaceContainerLow,
      palette[0].surfaceContainer,
      palette[0].surfaceContainerHigh,
      palette[0].surfaceContainerHighest,
      palette[0].onPrimaryFixed,
      palette[0].primaryFixed,

      palette[1],
      palette[2],
    ];
  }
  return colors;
}

Future<List<dynamic>> getMainColor(settings, primary, back, image) async {
  List<Color> colors;

  final String mode = settings["Color mode"];

  List<dynamic> x = await getImageColors(image, mode, settings);
  List<dynamic> palette = x[0];

  if ((mode == "light" || mode == "dark") || settings["Image source"] == 'network'
      || settings["Color source"] == 'wallpaper') {
    colors = getNetworkColors(palette, settings);
  }
  else {
    colors = getColors(primary, back, settings, 0);
  }

  return [colors, x[1]];
}

Future<List<dynamic>> getTotalColor(settings, primary, back, image) async {
  List<Color> colors;
  List<List<Color>> allColor = [];

  final String mode = settings["Color mode"];

  List<dynamic> lightPalette = (await getImageColors(image, "light" , settings))[0];
  List<dynamic> darkPalette = (await getImageColors(image, "dark" , settings))[0];

  if (settings["Image source"] == 'network' || settings["Color source"] == 'wallpaper') {
    allColor.add(getNetworkColors(darkPalette, settings, force: "original"));
    allColor.add(getNetworkColors(darkPalette, settings, force: "colorful"));
    allColor.add(getNetworkColors(darkPalette, settings, force: "monochrome"));
    allColor.add(getNetworkColors(lightPalette, settings, force: "light"));
    allColor.add(getNetworkColors(darkPalette, settings, force: "dark"));
  }
  else {
    allColor.add(getColors(primary, back, settings, 0, force: "original"));
    allColor.add(getColors(primary, back, settings, 0, force: "colorful"));
    allColor.add(getColors(primary, back, settings, 0, force: "dark"));
    allColor.add(getNetworkColors(lightPalette, settings, force: "light")); //because the light and dark use the
    allColor.add(getNetworkColors(darkPalette, settings, force: "dark")); // material palette generator anyway
  }

  if ((mode == "light" || mode == "dark") || settings["Image source"] == 'network'
      || settings["Color source"] == 'wallpaper') {
    colors = getNetworkColors(mode == "light" ? lightPalette : darkPalette ,settings);
  }
  else {
    colors = getColors(primary, back, settings, 0);
  }

  return [colors, allColor];
}

Future<List<dynamic>> getSettingsAndColors(primary, back, image) async {
  Map<String, String> settings = await getSettingsUsed();
  List<dynamic> colors = await getTotalColor(settings, primary, back, image);
  return [settings, colors];
}

Future<Map<String, String>> getSettingsUsed() async {
  Map<String, String> settings = {};
  for (var v in settingSwitches.entries) {
    final prefs = await SharedPreferences.getInstance();
    final ifnot = v.value[0];
    final used = prefs.getString('setting${v.key}') ?? ifnot;
    settings[v.key] = v.value.contains(used) ? used: ifnot;
  }
  return settings;
}

Future<String> isLocationSafe() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return "location services are disabled.";
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return "location permission is denied";
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return "location permission denied forever";
  }
  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    return "enabled";
  }
  return "failed to access gps";
}

Future<List<String>> getLastPlace() async {
  final prefs = await SharedPreferences.getInstance();
  final place = prefs.getString('LastPlaceN') ?? 'New York';
  final cord = prefs.getString('LastCord') ?? '40.7128, 74.0060';
  return [place, cord];
}

setLastPlace(String place, String cord) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('LastPlaceN', place);
  await prefs.setString('LastCord', cord);
}

Future<String> getWeatherProvider() async {
  final prefs = await SharedPreferences.getInstance();
  final used = prefs.getString('weather_provider') ?? 'open-meteo';
  return used;
}

SetData(String name, String to) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(name, to);
}

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit, settings, textcolor,
    Color primary) {
  List<String> Items = settingSwitches[name] ?? ['˚C', '˚F'];
  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(18),
    icon: Padding(
      padding: const EdgeInsets.only(left:5),
      child: Icon(Icons.arrow_drop_down_circle_rounded, color: primary,),
    ),
    style: GoogleFonts.comfortaa(
      color: textcolor,
      fontSize: 19 * getFontSize(settings["Font size"]),
      fontWeight: FontWeight.w300,
    ),
    value: unit,
    items: Items.map((item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item),
      );
    }).toList(),
    onChanged: (Object? value) {
      HapticFeedback.lightImpact();
      updatePage(name, value);
    }
  );
}

Widget settingEntry(icon, text, settings, highlight, updatePage, textcolor, primaryLight, primary) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(icon, color: primary),
        ),
        Expanded(
          flex: 10,
          child: comfortatext(
            translation(text, settings["Language"]!),
            20,
            settings,
            color: textcolor,
          ),
        ),
        const Spacer(),
        dropdown(
            darken(highlight), text, updatePage, settings[text]!, settings, textcolor, primaryLight
        ),
      ],
    ),
  );
}

Widget NavButton(text, settings, textcolor, icon) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 8, right: 12, top: 15, bottom: 15),
        child: Icon(icon, color: textcolor, size: 26,),
      ),
      comfortatext(text, 21, settings, color: textcolor),
    ],
  );
}

Widget ColorCircle(name, outline, inside, settings, updatePage, {w = 2, tap = 0}) {

  return Expanded(
    child: GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (tap == 0) {
          return;
        }
        else {
          updatePage("Color mode", name);
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  border: Border.all(width: w * 1.0, color: outline),
                  color: inside
                ),
                child: tap == 1 ? Center(child: comfortatext(name[0], 20, settings, color: outline))
                : Container(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SettingsPage extends StatefulWidget {

  final primary;
  final back;
  final image;

  const SettingsPage({Key? key, required this.back, required this.primary,
  required this.image}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState(back: back, primary: primary, image: image);
}

class _SettingsPageState extends State<SettingsPage> {

  final primary;
  final back;
  final image;

  _SettingsPageState({required this.primary, required this.back, required this.image});

  void updatePage(String name, String to) {
    setState(() {
      //selected_temp_unit = newSelect;
      SetData('setting$name', to);
    });
  }
  void goBack() {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return const MyApp();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: getSettingsAndColors(primary, back, image),
      builder: (BuildContext context,
          AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        } else if (snapshot.hasError) {
          print((snapshot.error, snapshot.stackTrace));
          return Center(
            child: ErrorWidget(snapshot.error as Object),
          );
        }
        return SettingsMain(primary, snapshot.data?[0], updatePage, goBack, back, image, context,
            snapshot.data?[1][0], snapshot.data?[1][1]);
      },
    );
  }
}

Widget SettingsMain(Color primary, Map<String, String>? settings, Function updatePage,
    Function goBack, Color back, Image image, context, colors, allColors) {

  return  Material(
    color: colors[1],
    child: CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          leading:
          IconButton(icon: Icon(Icons.arrow_back, color: colors[11],), onPressed: () {
            HapticFeedback.selectionClick();
            goBack();
          }),
          title: comfortatext(translation('Settings', settings!["Language"]!), 30, settings, color: colors[11]),
          backgroundColor: colors[6],
          pinned: false,
        ),
        // Just some content big enough to have something to scroll.
        SliverToBoxAdapter(
          child: Container(
            color: colors[6],
            child: settingsMain(settings, updatePage, image, colors, allColors),
          ),
        ),
      ],
    ),
  );
}

Widget settingsMain(Map<String, String> settings, Function updatePage, Image image, List<Color> colors,
    allColors) {

  Color containerLow = colors[6];
  Color onSurface = colors[4];
  Color primary = colors[1];
  Color primaryLight = colors[2];
  Color surface = colors[0];
  Color colorpop = colors[12];
  Color desc_color = colors[13];


  //var entryList = settings.entries.toList();
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 15),
    color: containerLow,
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /*
                NavButton('Appearance', settings, textcolor, Icons.color_lens),
                NavButton('Language', settings, textcolor, Icons.language),
                NavButton('Units', settings, textcolor, Icons.graphic_eq),
                NavButton('Advanced', settings, textcolor, Icons.code),

                 */


                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.palette_outlined, color: primary, ),
                      ),
                      Expanded(
                        flex: 10,
                        child: comfortatext(translation('Color mode', settings["Language"]!), 20, settings,
                        color: onSurface),
                      ),
                      const Spacer(),
                      comfortatext(settings["Color mode"]!, 20, settings, color: primaryLight)
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 30),
                  child: SizedBox(
                    height: 300,
                    child: Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: 0.72,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20)),
                            color: surface,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
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
                                            comfortatext("${unit_coversion(29, settings["Temperature"]!).toInt()}°", 36, settings, color: colorpop),
                                            comfortatext(translation("Clear Sky", settings["Language"]!), 20,
                                                settings, color: desc_color)
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
                                    children: [
                                      //ColorCircle(settings["Color mode"], primary, surface, settings, updatePage),
                                      ColorCircle("", primary, surface, settings, updatePage),
                                      ColorCircle("", primary, surface, settings, updatePage),
                                      ColorCircle("", primary, surface, settings, updatePage),
                                      ColorCircle("", primary, surface, settings, updatePage)
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  //somehow this was the only way i found to limit the width.
                  //otherwise the row would disregard the max size and expand beyond
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 90),
                    child: Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: 4,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ColorCircle("original", allColors[0][1], allColors[0][0], settings, updatePage, w: 4, tap: 1),
                              ColorCircle("colorful", allColors[1][1], allColors[1][0], settings, updatePage, w: 4, tap: 1),
                              ColorCircle("monochrome", allColors[2][1], allColors[2][0], settings, updatePage, w: 4, tap: 1),
                              ColorCircle("light", allColors[3][1], allColors[3][0], settings, updatePage, w: 4, tap: 1),
                              ColorCircle("dark", allColors[4][1], allColors[4][0], settings, updatePage, w: 4, tap: 1),
                            ]
                        ),
                      ),
                    ),
                  ),
                ),

                settingEntry(Icons.invert_colors_on, "Color source", settings, containerLow, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(Icons.landscape_outlined, "Image source", settings, containerLow, updatePage,
                    onSurface, primaryLight, primary),

                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20, left: 12, right: 12),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(2)
                    ),
                  ),
                ),

                settingEntry(CupertinoIcons.globe, "Language", settings, containerLow, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(Icons.access_time_filled_sharp, "Time mode", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(CupertinoIcons.textformat_size, "Font size", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),

                settingEntry(Icons.manage_search_outlined, "Search provider", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),

                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20, left: 12, right: 12),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(2)
                    ),
                  ),
                ),

                settingEntry(CupertinoIcons.thermometer, "Temperature", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(CupertinoIcons.drop_fill, "Precipitation", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(CupertinoIcons.wind, "Wind", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),
                settingEntry(CupertinoIcons.timelapse, "Pressure", settings, onSurface, updatePage,
                    onSurface, primaryLight, primary),

                const SizedBox(
                  height: 40,
                )


              ]
          ),
        ),
      ),
    ),
  );
}

class MyDrawer extends StatelessWidget {

  final backupprimary;
  final backupback;
  final settings;
  final image;

  final primary;
  final surface;
  final onSurface;
  final hihglight;

  const MyDrawer({super.key, required this.settings, required this.backupback, required this.backupprimary,
  required this.image, required this.surface, required this.primary, required this.onSurface,
  required this.hihglight});

  @override
  Widget build(BuildContext context) {

    return Drawer(
      backgroundColor: surface,
      elevation: 0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: primary,
            ),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: comfortatext('Overmorrow', 30, settings, color: surface)
                ),
                Align(
                  alignment: Alignment.centerRight,
                    child: comfortatext('Weather', 30, settings, color: surface)
                ),
              ],
            ),
          ),
          ListTile(
            title: comfortatext(translation('Settings', settings["Language"]), 25,
                settings, color: onSurface),
            leading: Icon(Icons.settings, color: primary,),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(primary: backupprimary,
                    back: backupback, image: image,)),
              );
            },
          ),
          ListTile(
            title: comfortatext(translation('About', settings["Language"]), 25,
                settings, color: onSurface),
            leading: Icon(Icons.info_outline, color: primary,),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InfoPage(primary: primary, settings: settings,
                surface: surface, onSurface: onSurface, hihglight: hihglight,)),
              );
            },
          ),
          ListTile(
            title: comfortatext(translation('Donate', settings["Language"]), 25,
                settings, color: onSurface),
            leading: Icon(Icons.favorite_border, color: primary,),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DonationPage(primary: primary, settings: settings,
                surface: surface, highlight: hihglight, onSurface: onSurface,)),
              );
            },
          ),
        ],
      ),
    );
  }
}
