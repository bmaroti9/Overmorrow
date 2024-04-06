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
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/donation_page.dart';
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
  'Rain': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph', 'kn'],
  'Pressure' : ['mmHg', 'inHg', 'mb', 'hPa'],
  'Color mode' : ['original', 'colorful', 'light', 'dark'],
  'Time mode': ['12 hour', '24 hour'],
  'Font size': ['normal', 'small', 'very small', 'big'],
};

String translation(String text, String language) {
  int index = languageIndex[language] ?? 0;
  String translated = mainTranslate[text]![index];
  return translated;
}

List<Color> getColors(primary, back, settings) {
  Color textcolor = WHITE;
  Color color = primary;
  Color d_color = darken(primary, 0.2);

  if (settings?["Color mode"] == "colorful") {
    color = back;
    d_color = darken(back, 0.2);
  }

  if (settings?["Color mode"] == "light") {
    textcolor = lightAccent(primary, 20000);
    color = const Color(0xffeeeeee);
    d_color = primary;
  }

  else if (settings?["Color mode"] == "dark") {
    textcolor = lighten(lightAccent(primary, 30000), 0.3);
    color = BLACK;
    d_color = primary;
  }

  return [color, d_color, textcolor];
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

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit, settings) {
  List<String> Items = settingSwitches[name] ?? ['˚C', '˚F'];
  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(18),
    icon: const Padding(
      padding: EdgeInsets.only(left:5),
      child: Icon(Icons.arrow_drop_down, color: WHITE,),
    ),
    style: GoogleFonts.comfortaa(
      color: WHITE,
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

  List<Color> colors = getColors(primary, back, settings);

  return Scaffold(
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: colors[1],
          title: comfortatext(translation('Settings', settings!["Language"]!), 25, settings),
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body: settingsMain(colors[0], settings, updatePage, colors[2], colors[1]),
  );
}

Widget settingsMain(Color color, Map<String, String> settings, Function updatePage,
    Color textcolor, Color secondary) {
  var entryList = settings.entries.toList();
  return Container(
    padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
    color: color,
    child: Column(
        children: [
            ListView.builder(
              itemCount: settings.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  height: 55,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      comfortatext(translation(entryList[index].key, settings["Language"]!), 23,
                          settings, color: textcolor),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                color: secondary,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10, right: 4),
                                child: dropdown(
                                    darken(secondary),
                                    entryList[index].key,
                                    updatePage,
                                    entryList[index].value,
                                    settings,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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

    List<Color> colors = getColors(primary, back, settings);

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
                MaterialPageRoute(builder: (context) => InfoPage(color: colors[0], settings: settings,)),
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
                MaterialPageRoute(builder: (context) => DonationPage(color: colors[0], settings: settings,)),
              );
            },
          ),
        ],
      ),
    );
  }
}
