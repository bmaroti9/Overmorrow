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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/donation_page.dart';
import 'package:overmorrow/settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'decoders/extra_info.dart';
import 'languages.dart';
import 'main.dart';
import 'ui_helper.dart';

Map<String, List<String>> settingSwitches = {
  'Language' : [
    'English', 'Español', 'Français', 'Deutsch', 'Italiano',
    'Português', 'Русский', 'Magyar', 'Polski', 'Ελληνικά', '简体中文', '日本語',
  ],
  'Temperature': ['˚C', '˚F'],
  'Precipitation': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph', 'kn'],
  'Time mode': ['12 hour', '24 hour'],
  'Font size': ['normal', 'small', 'very small', 'big'],

  'Color mode' : ['auto', 'original', 'colorful', 'mono', 'light', 'dark'],

  'Color source' : ['image', 'wallpaper'],
  'Image source' : ['network', 'asset'],

  'Search provider' : ['weatherapi', 'open-meteo'],
  'networkImageDialogShown' : ["false", "true"],

  'Layout order' : ["sunstatus,rain indicator,air quality,radar,forecast,daily"],
};

String translation(String text, String language) {
  int index = languageIndex[language] ?? 0;
  String translated = mainTranslate[text]![index];
  return translated;
}

List<Color> getColors(primary, back, settings, dif, {force = "-1"}) {

  String x = force == "-1" ? settings["Color mode"] : force;
  if (x == "auto") {
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    x = brightness == Brightness.dark ? "dark" : "light";
  }


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

  if (x == "mono") {
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
  if (x == "auto") {
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    x = brightness == Brightness.dark ? "dark" : "light";
  }

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
  if (x == "mono") {
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

  String mode = settings["Color mode"];

  List<dynamic> x = await getImageColors(image, mode, settings);
  List<dynamic> palette = x[0];

  if (mode == "auto") {
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    mode = brightness == Brightness.dark ? "dark" : "light";
  }

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

  String mode = settings["Color mode"];

  if (mode == "auto") {
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    mode = brightness == Brightness.dark ? "dark" : "light";
  }

  List<dynamic> lightPalette = (await getImageColors(image, "light" , settings))[0];
  List<dynamic> darkPalette = (await getImageColors(image, "dark" , settings))[0];

  if (settings["Image source"] == 'network' || settings["Color source"] == 'wallpaper') {
    allColor.add(getNetworkColors(darkPalette, settings, force: "original"));
    allColor.add(getNetworkColors(darkPalette, settings, force: "colorful"));
    allColor.add(getNetworkColors(darkPalette, settings, force: "mono"));
    allColor.add(getNetworkColors(lightPalette, settings, force: "light"));
    allColor.add(getNetworkColors(darkPalette, settings, force: "dark"));
  }
  else {
    allColor.add(getColors(primary, back, settings, 0, force: "original"));
    allColor.add(getColors(primary, back, settings, 0, force: "colorful"));
    allColor.add(getColors(primary, back, settings, 0, force: "mono"));
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
    if (v.value.length > 1) { //this is so that ones like the layout don't have to include all possible options
      settings[v.key] = v.value.contains(used) ? used: ifnot;
    }
    else {
      settings[v.key] = used;
    }
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
      settings[name] = value;
      updatePage(name, value);
    }
  );
}

Widget settingEntry(icon, text, settings, highlight, updatePage, textcolor, primaryLight, primary) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3, left: 25, right: 25),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 13),
          child: Icon(icon, color: primary),
        ),
        Expanded(
          flex: 10,
          child: comfortatext(
            translation(text, settings["Language"]!),
            19,
            settings,
            color: textcolor,
          ),
        ),
        const Spacer(),
        dropdown(
            highlight, text, updatePage, settings[text]!, settings, textcolor, primaryLight
        ),
      ],
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
    color: colors[0],
    child: CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          leading:
          IconButton(icon: Icon(Icons.arrow_back, color: colors[0],), onPressed: () {
            HapticFeedback.selectionClick();
            goBack();
          }),
          title: comfortatext(translation('Settings', settings!["Language"]!), 30, settings, color: colors[0]),
          backgroundColor: colors[1],
          pinned: false,
        ),
        // Just some content big enough to have something to scroll.
        SliverToBoxAdapter(
          child: NewSettings(settings, updatePage, image, colors, allColors, context),
        ),
      ],
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
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: comfortatext('OVRMRW', 40, settings, color: surface, weight: FontWeight.w300),
                )
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          ListTile(
            title: comfortatext(translation('Settings', settings["Language"]), 24,
                settings, color: onSurface),
            leading: Icon(Icons.settings_outlined, color: primary, size: 24,),
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
            title: comfortatext(translation('About', settings["Language"]), 24,
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
            title: comfortatext(translation('Donate', settings["Language"]), 24,
                settings, color: onSurface),
            leading: Icon(Icons.favorite_outline_sharp, color: primary,),
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
