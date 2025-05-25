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
import 'package:overmorrow/settings_screens.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui_helper.dart';
import '../l10n/app_localizations.dart';

Map<String, List<String>> settingSwitches = {
  'Language' : [
    'English', //English
    'Español', //Spanish
    'Français', //French
    'Deutsch', //German
    'Italiano', //Italian
    'Português', //Portuguese
    'Русский', //Russian
    'Magyar', //Hungarian
    'Polski', //Polish
    'Ελληνικά', //Greek
    '简体中文', //Chinese
    '日本語', //Japanese
    'українська', //Ukrainian
    'türkçe', //Turkish
    'தமிழ்', //Tamil
    'български', //Bulgarian
    'Indonesia', //Indonesian
    'عربي' //Arablic
  ],
  'Temperature': ['˚C', '˚F'],
  'Precipitation': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph', 'kn'],

  'Time mode': ['12 hour', '24 hour'],
  'Date format': ['mm/dd', 'dd/mm'],

  'Font size': ['normal', 'small', 'very small', 'big'],

  'Color mode' : ['auto', 'light', 'dark'],

  'Color source' : ['image', 'wallpaper', 'custom'],
  'Image source' : ['network', 'asset'],
  'Custom color': ['#c62828', '#ff80ab', '#7b1fa2', '#9575cd', '#3949ab', '#40c4ff',
        '#4db6ac', '#4caf50', '#b2ff59', '#ffeb3b', '#ffab40',],

  'Search provider' : ['weatherapi', 'open-meteo'],

  'Layout' : ["sunstatus,rain indicator,hourly,alerts,radar,daily,air quality"],
  'Radar haptics': ["on", "off"],
};

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

Widget settingEntry(icon, text, settings, ColorScheme palette, updatePage, rawText, context) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          List<String> options = settingSwitches[rawText] ?? [""];
          return AlertDialog(
            backgroundColor: palette.surface,
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 10, left: 0),
                      child: comfortatext(text, 22, settings, color: palette.onSurface),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(options.length, (int index) {
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            updatePage(rawText, options[index]);
                          },
                          child: Row(
                            children: [
                              Radio<String>(
                                value: options[index],
                                groupValue: settings[rawText],
                                activeColor: palette.primary,
                                onChanged: (String? value) {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                  updatePage(rawText, value);
                                },
                              ),
                              comfortatext(options[index], 18, settings, color: palette.onSurface)
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
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: Icon(icon, color: palette.primary, size: 22,),
          ),
          Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                comfortatext(text, 19, settings, color: palette.onSurface),
                comfortatext(settings[rawText]!, 15, settings, color: palette.outline,),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class SettingsPage extends StatefulWidget {

  final image;

  const SettingsPage({Key? key, required this.image}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState(image: image);
}

class _SettingsPageState extends State<SettingsPage> {

  final image;

  String _locale = 'English';
  //this is so that appearance page setting changes take effect in place rather that having to exit the page
  ValueNotifier<ColorPalette> colornotify = ValueNotifier<ColorPalette>(
      const ColorPalette(palette: ColorScheme.light(), imageColors: [], regionColors: [],
          descColor: WHITE, colorPop: WHITE));

  _SettingsPageState({required this.image});

  void updatePage(String name, String to) {
    setState(() {
      //selected_temp_unit = newSelect;
      SetData('setting$name', to);
      if (name == "Language") {
        _locale = to;
      }
    });
  }
  void goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    colornotify.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: getSettingsAndColors(image),
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
        _locale = snapshot.data?[0]["Language"];
        //this is needed so flutter wont complain about setstate during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          colornotify.value = snapshot.data?[1];
        });
        return Localizations.override(
          context: context,
          locale: languageNameToLocale[_locale] ?? const Locale('en'),
          child: SettingsMain(settings: snapshot.data?[0], updatePage: updatePage, goBack: goBack, image: image,
              palette: snapshot.data?[1].palette, colornotify: colornotify,),
        );
      },
    );
  }
}


class SettingsMain extends StatelessWidget {
  final ColorScheme palette;
  final goBack;
  final settings;
  final updatePage;
  final image;
  final colornotify;

  const SettingsMain({super.key, this.settings, this.updatePage, this.goBack, this.image, required this.palette, this.colornotify});

  @override
  Widget build(BuildContext context) {
    return  Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  goBack();
                }),
            title: comfortatext(AppLocalizations.of(context)!.settings, 30, settings, color: palette.primary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          // Just some content big enough to have something to scroll.
          SliverToBoxAdapter(
            child: NewSettings(settings!, updatePage, image, palette, context, colornotify),
          ),
        ],
      ),
    );
  }
}