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
import 'package:overmorrow/main_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'languages.dart';
import 'main.dart';
import 'ui_helper.dart';

Map<String, List<String>> settingSwitches = {
  'Language' : [
    'English', 'Magyar', 'Español', 'Français', 'Deutsch', 'Italiano',
    'Português', 'Русский', '简体中文', '日本語'
  ],
  'Temperature': ['˚C', '˚F'],
  'Precipitation': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph', 'kn'],
  'Pressure' : ['mmHg', 'inHg', 'mb', 'hPa'],
  'Time mode': ['12 hour', '24 hour'],
  'Font size': ['normal', 'small', 'very small', 'big'],

  'Color mode' : ['original', 'colorful', 'monochrome', 'light', 'dark'],
};

String translation(String text, String language) {
  int index = languageIndex[language] ?? 0;
  String translated = mainTranslate[text]![index];
  return translated;
}

List<Color> getColors(primary, back, settings, dif) {
  List<Color> colors = [ //original colorful option
    primary,
    back,
    WHITE,
    [back, WHITE][dif],
    WHITE,
    darken(primary)
  ];

  if (settings["Color mode"] == "monochrome") {
    colors = [ //default colorful option
      primary,
      WHITE,
      WHITE,
      WHITE,
      WHITE,
      darken(primary)
    ];
  }

  if (settings["Color mode"] == "colorful") {
    colors = [ //default colorful option
      back,
      primary,
      WHITE,
      [back, WHITE][dif],
      WHITE,
      darken(back)
    ];
  }

  else if (settings["Color mode"] == "light") {
    colors = [ //backcolor, primary, text
      const Color(0xffeeeeee),
      primary,
      lightAccent(primary, 30000),
      WHITE,
      primary,
      lighten(lightAccent(primary, 60000), 0.25),
    ];
  }
  else if (settings["Color mode"] == "dark") {
    colors = [ //backcolor, primary, text
      BLACK,
      lighten(primary, 0.15),
      lighten(lightAccent(primary, 30000), 0.3),
      [BLACK, primary, WHITE][dif],
      WHITE,
      darken(lightAccent(primary, 30000), 0.3),
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

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit, settings, textcolor) {
  List<String> Items = settingSwitches[name] ?? ['˚C', '˚F'];
  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(18),
    icon: Padding(
      padding: const EdgeInsets.only(left:5),
      child: Icon(Icons.arrow_drop_down_circle_rounded, color: textcolor,),
    ),
    style: GoogleFonts.comfortaa(
      color: textcolor,
      fontSize: 20 * getFontSize(settings["Font size"]),
      fontWeight: FontWeight.w300,
    ),
    //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
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

Widget setingEntry(icon, text, settings, highlight, updatePage, textcolor) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(icon, color: textcolor, ),
        ),
        comfortatext(translation(text, settings["Language"]!), 20, settings, color: textcolor),
        const Spacer(),
        dropdown(
          darken(highlight), text, updatePage, settings[text]!, settings, textcolor
        ),
      ],
    ),
  );
}

class SettingsPage extends StatefulWidget {

  final primary;
  final back;

  const SettingsPage({Key? key, required this.back, required this.primary,}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState(back: back, primary: primary);
}

class _SettingsPageState extends State<SettingsPage> {

  final primary;
  final back;

  _SettingsPageState({required this.primary, required this.back});

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
          return MyApp();
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
          return Scaffold(backgroundColor: WHITE,);
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: ErrorWidget(snapshot.error as Object),
          );
        }
        return SettingsMain(primary, snapshot.data, updatePage, goBack, back);
      },
    );
  }
}

Widget SettingsMain(Color primary, Map<String, String>? settings, Function updatePage,
    Function goBack, Color back) {

  List<Color> colors = getColors(primary, back, settings, 0);

  return Scaffold(
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: colors[0],
          title: comfortatext(translation('Settings', settings!["Language"]!), 25, settings, color: colors[2]),
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: Icon(Icons.arrow_back, color: colors[2],),
          )
      ),
      body: settingsMain(colors[0], settings, updatePage, colors[2], colors[1], colors[5], colors[3]),
  );
}

Widget settingsMain(Color color, Map<String, String> settings, Function updatePage,
    Color textcolor, Color secondary, highlight, Color colorpop) {
  //var entryList = settings.entries.toList();
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 15),
    color: highlight,
    child: ListView(
      physics: BouncingScrollPhysics(),
        children: [
          SizedBox(height: 15,),
          setingEntry(CupertinoIcons.globe, "Language", settings, highlight, updatePage, textcolor),
          setingEntry(Icons.access_time_filled_sharp, "Time mode", settings, highlight, updatePage, textcolor),
          setingEntry(CupertinoIcons.textformat_size, "Font size", settings, highlight, updatePage, textcolor),

          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10, left: 10, bottom: 10),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.circular(2)
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 20, bottom: 10),
            child: SizedBox(
              height: 300,
              child: Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: 0.7,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25)),
                      color: color,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 210,
                            child: Stack(
                              children: [
                                ParrallaxBackground(imagePath1: "sleet.jpg", color: color),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, bottom: 15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      comfortatext("10°", 32, settings, color: colorpop),
                                      comfortatext(translation("Partly Cloudy", settings["Language"]!), 19,
                                          settings, color: WHITE)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 4, left: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(200),
                                          border: Border.all(width: 2, color: secondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(200),
                                          border: Border.all(width: 2, color: secondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(200),
                                          border: Border.all(width: 2, color: secondary),
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(200),
                                          border: Border.all(width: 2, color: secondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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

          setingEntry(CupertinoIcons.color_filter, "Color mode", settings, highlight, updatePage, textcolor),

          setingEntry(CupertinoIcons.thermometer, "Temperature", settings, highlight, updatePage, textcolor),
          setingEntry(CupertinoIcons.drop_fill, "Precipitation", settings, highlight, updatePage, textcolor),
          setingEntry(CupertinoIcons.wind, "Wind", settings, highlight, updatePage, textcolor),
          setingEntry(CupertinoIcons.timelapse, "Pressure", settings, highlight, updatePage, textcolor),
        ]
    ),
  );
}

class MyDrawer extends StatelessWidget {

  final primary;
  final back;
  final settings;

  const MyDrawer({super.key, required this.settings, required this.primary, required this.back});

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
                    back: back)),
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
