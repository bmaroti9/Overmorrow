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
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/services/color_service.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/widget_service.dart';
import 'package:overmorrow/settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui_helper.dart';
import '../l10n/app_localizations.dart';


Future<List<dynamic>> getSettingsAndColors(image) async {
  Map<String, String> settings = await getSettingsUsed();
  ColorPalette colorPalette = await ColorPalette.getColorPalette(image, settings["Color mode"]!, settings);
  return [settings, colorPalette];
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

Future<String> isLocationSafe(translationProv) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return translationProv.locationServicesAreDisabled;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return translationProv.locationPermissionIsDenied;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return translationProv.locationPermissionDeniedForever;
  }
  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    return "enabled";
  }
  return translationProv.failedToAccessGps;
}


//the last place you viewed in the app,
// so that's where it will start up next time you open it
Future<List<String>> getLastPlace() async {
  final prefs = await SharedPreferences.getInstance();
  final place = prefs.getString('LastPlaceN') ?? 'New York';
  final cord = prefs.getString('LastCord') ?? '40.7128, -74.0060';
  return [place, cord];
}

setLastPlace(String place, String cord) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('LastPlaceN', place);
  await prefs.setString('LastCord', cord);
}

//the actual last known current location
Future<List<String>> getLastKnownLocation() async {
  final prefs = await SharedPreferences.getInstance();
  final place = prefs.getString('LastKnownPositionName') ?? 'unknown';
  final cord = prefs.getString('LastKnownPositionCord') ?? 'unknown';
  return [place, cord];
}

setLastKnownLocation(String place, String cord) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('LastKnownPositionName', place);
  await prefs.setString('LastKnownPositionCord', cord);
  WidgetService.saveData("widget.lastKnownPlace", place); //save the name of the place to the widgets
}

Future<String> getWeatherProvider() async {
  final prefs = await SharedPreferences.getInstance();
  final used = prefs.getString('weather_provider') ?? 'open-meteo';
  return used;
}

Future<String> getLanguageUsed() async {
  final prefs = await SharedPreferences.getInstance();
  final used = prefs.getString('settingLanguage') ?? 'English';
  return used;
}

SetData(String name, String to) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(name, to);
}

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit, settings, textcolor,
    Color primary, rawName) {
  List<String> Items = settingSwitches[rawName] ?? ['˚C', '˚F'];

  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(18),
    icon: Padding(
      padding: const EdgeInsets.only(left:10),
      child: Icon(Icons.arrow_drop_down_circle_rounded, color: primary,),
    ),
    style: GoogleFonts.comfortaa(
      color: textcolor,
      fontSize: 19 * getFontSize(settings["Font size"]),
      fontWeight: FontWeight.w300,
    ),
    alignment: Alignment.centerRight,
    value: unit,
    items: Items.map((item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item),
      );
    }).toList(),
    onChanged: (Object? value) {
      HapticFeedback.lightImpact();
      settings[rawName] = value;
      updatePage(rawName, value);
    }
  );
}

Widget circleBorderIcon(IconData icon, context) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(30),
    ),
    width: 50,
    height: 50,
    child: Center(child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24,)),
  );
}

class SettingsEntry extends StatelessWidget {
  final IconData icon;
  final String text;
  final String rawText;
  final String selected;
  final Function update;

  const SettingsEntry({super.key, required this.icon, required this.text, required this.rawText,
  required this.selected, required this.update});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              List<String> options = settingSwitches[rawText] ?? [""];
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 10, left: 0),
                          child: Text(text, style: const TextStyle(fontSize: 22),),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List<Widget>.generate(options.length, (int index) {
                            return GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                update(options[index]);
                              },
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: options[index],
                                    groupValue: selected,
                                    onChanged: (String? value) {
                                      HapticFeedback.lightImpact();
                                      update(options[index]);
                                      Navigator.pop(context, value);
                                    },
                                  ),
                                  Text(options[index], style: const TextStyle(fontSize: 18),)
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              );
            }
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 14),
        child: Row(
          children: [
            circleBorderIcon(icon, context),
            const SizedBox(width: 20,),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(fontSize: 20, height: 1.2),),
                  Text(selected, style: TextStyle(color: Theme.of(context).colorScheme.outline,
                      fontSize: 15, height: 1.2),)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SwitchSettingEntry extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final Function update;

  const SwitchSettingEntry({super.key, required this.icon, required this.text,
    required this.selected, required this.update});

  static const WidgetStateProperty<Icon> thumbIcon = WidgetStateProperty<Icon>.fromMap(
    <WidgetStatesConstraint, Icon>{
      WidgetState.selected: Icon(Icons.check),
      WidgetState.any: Icon(Icons.close),
    },
  );

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      child: Row(
        children: [
          circleBorderIcon(icon, context),
          const SizedBox(width: 20,),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 20, height: 1.2),),),
          Switch(
            value: selected,
            onChanged: (bool value) {
              HapticFeedback.mediumImpact();
              update(value);
            },
            thumbIcon: thumbIcon,
          ),
        ],
      ),
    ) ;
  }

}

class SettingsPage extends StatefulWidget {

  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  void goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return  Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  goBack();
                }),
            title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontSize: 30),),
            pinned: false,
          ),

          const SliverToBoxAdapter(
            child: NewSettings(),
          ),

        ],
      ),
    );
  }
}