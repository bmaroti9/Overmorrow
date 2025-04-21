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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/donation_page.dart';
import 'package:overmorrow/services/color_service.dart';
import 'package:overmorrow/settings_screens.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'decoders/extra_info.dart';
import 'main.dart';
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

  'Color mode' : ['auto', 'original', 'colorful', 'mono', 'light', 'dark'],

  'Color source' : ['image', 'wallpaper', 'custom'],
  'Image source' : ['network', 'asset'],
  'Custom color': ['#c62828', '#ff80ab', '#7b1fa2', '#9575cd', '#3949ab', '#40c4ff',
        '#4db6ac', '#4caf50', '#b2ff59', '#ffeb3b', '#ffab40',],

  'Search provider' : ['weatherapi', 'open-meteo'],
  'networkImageDialogShown' : ["false", "true"],

  'Layout order' : ["sunstatus,rain indicator,alerts,air quality,radar,forecast,daily"],
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

Widget settingEntry(icon, text, settings, ColorScheme palette, updatePage, rawText) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 3, left: 35, right: 35),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 13, bottom: 2),
          child: Icon(icon, color: palette.primary, size: 21,),
        ),
        Expanded(
          flex: 10,
          child: comfortatext(
            text,
            19,
            settings,
            color: palette.onSurface,
          ),
        ),
        const Spacer(),
        dropdown(
            palette.surfaceContainer, text, updatePage, settings[rawText]!, settings, palette.onSurface, palette.primaryContainer, rawText
        ),
      ],
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

class MyDrawer extends StatelessWidget {

  final settings;
  final image;

  final ColorScheme palette;

  const MyDrawer({super.key, required this.settings, required this.image, required this.palette});

  @override
  Widget build(BuildContext context) {

    return Drawer(
      backgroundColor: palette.surface,
      elevation: 0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: palette.surfaceContainer,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: comfortatext('OVRMRW', 40, settings, color: palette.primary, weight: FontWeight.w400),
                )
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          ListTile(
            title: comfortatext(AppLocalizations.of(context)!.settings, 24,
                settings, color: palette.onSurface),
            leading: Icon(Icons.settings_outlined, color: palette.primary, size: 24,),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(image: image),
                ),
              ).then((value) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return const MyApp();
                    },
                  ),
                );
              });
            },
          ),
          /*
          ListTile(
            title: comfortatext(AppLocalizations.of(context)!.about, 24,
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
            title: comfortatext(AppLocalizations.of(context)!.donate, 24,
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

           */
        ],
      ),
    );
  }
}
