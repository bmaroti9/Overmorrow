/*
Copyright (C) <2023>  <Balint Maroti>

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
import 'package:hihi_haha/dayforcast.dart';
import 'package:hihi_haha/donation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'ui_helper.dart';

List<String> settingsList = ['Language', 'Temperature', 'Rain', 'Wind', 'Pressure'];

Map<String, List<String>> settingSwitches = {
  'Language' : [
    'English', 'Magyar', 'Español', 'Français', 'Deutsch', 'Italiano',
    'Português', 'Русский', '简体中文', '日本語'
  ],
  'Temperature': ['˚C', '˚F'],
  'Rain': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph'],
  'Pressure' : ['mmHg', 'inHg', 'mb', 'hPa']
};

Future<List<String>> getSettingsUsed() async {
  List<String> units = [];
  for (String name in settingsList) {
    final prefs = await SharedPreferences.getInstance();
    final ifnot = settingSwitches[name] ?? ['˚C', '˚F'];
    final used = prefs.getString('setting$name') ?? ifnot[0];
    units.add(used);
  }
  return units;
}

class SnackbarGlobal {
  static GlobalKey<ScaffoldMessengerState> key =
  GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    key.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: comfortatext(message, 26, color: WHITE),
        backgroundColor: BLACK,)
      );
  }
}

Future<bool> isLocationSafe() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      SnackbarGlobal.show('permission denied');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    SnackbarGlobal.show('permission denied forever');
  }
  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    return true;
  }
  return false;
}

Future<String> getLastPlace() async {
  final prefs = await SharedPreferences.getInstance();
  final used = prefs.getString('LastPlace') ?? 'Szeged';
  return used;
}

SetData(String name, String to) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(name, to);
}

Widget leftpad(Widget child, double hihimargin) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(left: hihimargin, top: 10),
      child: child,
    ),
  );
}

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit) {
  List<String> Items = settingSwitches[name] ?? ['˚C', '˚F'];
  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(20),
    icon: const Padding(
      padding: EdgeInsets.only(left:5),
      child: Icon(Icons.arrow_drop_down, color: WHITE,),
    ),
    style: GoogleFonts.comfortaa(
      color: WHITE,
      fontSize: 20,
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
  final Color color;

  const SettingsPage({Key? key, required this.color}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState(color: color);
}

class _SettingsPageState extends State<SettingsPage> {
  // You can add your state variables here

  final color;
  _SettingsPageState({required this.color});

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
          return MyApp(); // Replace with the actual widget you want to reload.
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getSettingsUsed(),
      builder: (BuildContext context,
          AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            //child: ErrorWidget(snapshot.error as Object),
            child: comfortatext('A problem occurred: ${snapshot.error}', 20, color: BLACK),
          );
        }
        return SettingsMain(color, snapshot.data, updatePage, goBack);
      },
    );
  }
}

Widget SettingsMain(Color color, List<String>? settings, Function updatePage,
    Function goBack) {
  return Scaffold(
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: darken(color, 0.3),
          title: comfortatext(translation('Settings', settings![0]), 25),
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body: UnitsMain(color, settings, updatePage),
  );
}

Widget UnitsMain(Color color, List<String>? settings, Function updatePage) {
  return Container(
    padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
    color: color,
    child: Column(
        children: [
          leftpad(
            SizedBox(
              height: 70.0 * settings!.length,
              child: ListView.builder(
                itemCount: settings.length,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 70,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        comfortatext(translation(settingsList[index], settings[0]), 23),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: darken(color, 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10, right: 4),
                                  child: dropdown(
                                      darken(color, 0.2),
                                      settingsList[index],
                                      updatePage,
                                      settings[index]
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
            ),
            10
          )
        ]
    ),
  );
}

class MyDrawer extends StatelessWidget {

  final color;
  final settings;

  const MyDrawer({super.key, required this.color, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: color,
      elevation: 0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: darken(color, 0.5),
            ),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: comfortatext('Overmorrow', 30, color: color)
                ),
                Align(
                  alignment: Alignment.centerRight,
                    child: comfortatext('Weather', 30, color: color)
                ),
              ],
            ),
          ),
          ListTile(
            title: comfortatext(translation('Settings', settings[0]), 25),
            leading: const Icon(Icons.settings, color: WHITE,),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(color: color,)),
              );
            },
          ),
          ListTile(
            title: comfortatext(translation('About', settings[0]), 25),
            leading: const Icon(Icons.info_outline, color: WHITE,),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InfoPage(color: color, settings: settings,)),
              );
            },
          ),
          ListTile(
            title: comfortatext(translation('Donate', settings[0]), 25),
            leading: const Icon(Icons.favorite_border, color: WHITE,),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DonationPage(color: color, settings: settings,)),
              );
            },
          ),
        ],
      ),
    );
  }
}
