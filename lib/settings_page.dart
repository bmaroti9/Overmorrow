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
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/donation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'decoders/decode_wapi.dart';
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

  'Search provider' : ['weatherapi', 'open-meteo'],
};

String translation(String text, String language) {
  int index = languageIndex[language] ?? 0;
  String translated = mainTranslate[text]![index];
  return translated;
}

List<Color> getColors(primary, back, settings, dif, {force = "-1"}) {

  String x = force == "-1" ? settings["Color mode"] : force;

  //0 BACKCOLOR
  //1 PRIMARY
  //2 TEXT COLOR
  //3 COLOR POP
  //4 SECONDARY
  //5 HIGHLIGHT

  List<Color> colors = [
    primary,
    back,
    WHITE,
    [back, WHITE, WHITE][dif],
    WHITE,
    darken(primary)
  ];

  if (x == "monochrome") {
    colors = [ //default colorful option
      primary,
      WHITE,
      WHITE,
      WHITE,
      WHITE,
      darken(primary)
    ];
  }

  if (x == "colorful") {
    colors = [ //default colorful option
      back,
      primary,
      WHITE,
      [back, WHITE, WHITE][dif],
      WHITE,
      darken(back)
    ];
  }

  else if (x == "light") {
    colors = [ //backcolor, primary, text
      const Color(0xffeeeeee),
      primary,
      BLACK,
      WHITE,
      primary,
      lighten(lightAccent(primary, 60000), 0.25),
    ];
  }
  else if (x == "dark") {
    colors = [ //backcolor, primary, text
      BLACK,
      lighten(primary, 0.25),
      lighten(lightAccent(primary, 50000), 0.3),
      [BLACK, primary, WHITE][dif],
      lighten(lightAccent(primary, 60000), 0.25),
      const Color(0xff141414),
    ];
  }

  return colors;
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
      updatePage(name, value);
    }
  );
}
Widget settingEntry(icon, text, settings, highlight, updatePage, textcolor, primary) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(icon, color: textcolor),
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
            darken(highlight), text, updatePage, settings[text]!, settings, textcolor, primary
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

Widget ColorCircle(name, primary, back, settings, updatePage, {w = 2, tap = 0}) {

  List<Color> colors = getColors(primary, back, settings, 0, force: name);

  return Expanded(
    child: GestureDetector(
      onTap: () {
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
                  border: Border.all(width: w * 1.0, color: colors[1]),
                  color: colors[0]
                ),
                child: tap == 1 ? Center(child: comfortatext(name[0], 20, settings, color: colors[2]))
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
    return FutureBuilder<Map<String, String>>(
      future: getSettingsUsed(),
      builder: (BuildContext context,
          AsyncSnapshot<Map<String, String>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: ErrorWidget(snapshot.error as Object),
          );
        }
        return SettingsMain(primary, snapshot.data, updatePage, goBack, back, image);
      },
    );
  }
}

Widget SettingsMain(Color primary, Map<String, String>? settings, Function updatePage,
    Function goBack, Color back, String image) {

  List<Color> colors = getColors(primary, back, settings, 0);

  return Scaffold(
    backgroundColor: colors[5],
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: colors[5],
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: Icon(Icons.arrow_back, color: colors[2],),
          )
      ),
      body: settingsMain(colors[0], settings!, updatePage, colors[2], colors[1], colors[5], colors[3],
      image, primary, back),
  );
}

Widget settingsMain(Color color, Map<String, String> settings, Function updatePage,
    Color textcolor, Color secondary, highlight, Color colorpop, String image, Color primary,
    Color back) {

  //var entryList = settings.entries.toList();
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 15),
    color: highlight,
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15,),
                Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 30, left: 10),
                  child: comfortatext(translation('Settings', settings["Language"]!), 30, settings, color: textcolor),
                ),
                NavButton('Appearance', settings, textcolor, Icons.color_lens),
                NavButton('Language', settings, textcolor, Icons.language),
                NavButton('Units', settings, textcolor, Icons.graphic_eq),
                NavButton('Advanced', settings, textcolor, Icons.code),


                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(CupertinoIcons.circle_lefthalf_fill, color: textcolor, ),
                      ),
                      Expanded(
                        flex: 10,
                        child: comfortatext(translation('Color mode', settings["Language"]!), 20, settings,
                        color: textcolor),
                      ),
                      const Spacer(),
                      comfortatext(settings["Color mode"]!, 20, settings, color: textcolor)
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
                            color: color,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: Stack(
                                    children: [
                                      ParrallaxBackground(imagePath1: Image.asset(image, fit: BoxFit.cover,), color: color),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10, bottom: 15),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            comfortatext("${unit_coversion(29, settings["Temperature"]!).toInt()}°", 36, settings, color: colorpop),
                                            comfortatext(translation("Partly Cloudy", settings["Language"]!), 20,
                                                settings, color: WHITE)
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
                                      ColorCircle(settings["Color mode"], primary, back, settings, updatePage),
                                      ColorCircle(settings["Color mode"], primary, back, settings, updatePage),
                                      ColorCircle(settings["Color mode"], primary, back, settings, updatePage),
                                      ColorCircle(settings["Color mode"], primary, back, settings, updatePage),
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
                              ColorCircle("original", primary, back, settings, updatePage, w: 4, tap: 1),
                              ColorCircle("colorful", primary, back, settings, updatePage, w: 4, tap: 1),
                              ColorCircle("monochrome", primary, back, settings, updatePage, w: 4, tap: 1),
                              ColorCircle("light", primary, back, settings, updatePage, w: 4, tap: 1),
                              ColorCircle("dark", primary, back, settings, updatePage, w: 4, tap: 1),
                            ]
                        ),
                      ),
                    ),
                  ),
                ),

                settingEntry(CupertinoIcons.globe, "Language", settings, highlight, updatePage,
                    textcolor, secondary),
                settingEntry(Icons.access_time_filled_sharp, "Time mode", settings, highlight, updatePage,
                    textcolor, secondary),
                settingEntry(CupertinoIcons.textformat_size, "Font size", settings, highlight, updatePage,
                    textcolor, secondary),

                settingEntry(Icons.manage_search_outlined, "Search provider", settings, highlight, updatePage,
                    textcolor, secondary),

                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20, left: 12, right: 12),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(2)
                    ),
                  ),
                ),

                settingEntry(CupertinoIcons.thermometer, "Temperature", settings, highlight, updatePage,
                    textcolor, secondary),
                settingEntry(CupertinoIcons.drop_fill, "Precipitation", settings, highlight, updatePage,
                    textcolor, secondary),
                settingEntry(CupertinoIcons.wind, "Wind", settings, highlight, updatePage,
                    textcolor, secondary),
                settingEntry(CupertinoIcons.timelapse, "Pressure", settings, highlight, updatePage,
                    textcolor, secondary),

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

  final primary;
  final back;
  final settings;
  final image;

  const MyDrawer({super.key, required this.settings, required this.primary, required this.back,
  required this.image});

  @override
  Widget build(BuildContext context) {

    List<Color> colors = getColors(primary, back, settings, 0);

    return Drawer(
      backgroundColor: colors[0],
      elevation: 0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: colors[1],
            ),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: comfortatext('Overmorrow', 30, settings, color: colors[0])
                ),
                Align(
                  alignment: Alignment.centerRight,
                    child: comfortatext('Weather', 30, settings, color: colors[0])
                ),
              ],
            ),
          ),
          ListTile(
            title: comfortatext(translation('Settings', settings["Language"]), 25,
                settings, color: colors[2]),
            leading: Icon(Icons.settings, color: colors[2],),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(primary: primary,
                    back: back, image: image,)),
              );
            },
          ),
          ListTile(
            title: comfortatext(translation('About', settings["Language"]), 25,
                settings, color: colors[2]),
            leading: Icon(Icons.info_outline, color: colors[2],),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InfoPage(primary: primary, settings: settings,
                back: back,)),
              );
            },
          ),
          ListTile(
            title: comfortatext(translation('Donate', settings["Language"]), 25,
                settings, color: colors[2]),
            leading: Icon(Icons.favorite_border, color: colors[2],),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DonationPage(primary: primary, settings: settings,
                back: back,)),
              );
            },
          ),
        ],
      ),
    );
  }
}
