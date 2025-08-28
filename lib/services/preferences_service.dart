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

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';


Map<String, List<String>> settingSwitches = {
  'Language' : [
    'English', //English
    'Español', //Spanish
    'Français', //French
    'Deutsch', //German
    'Italiano', //Italian
    'Português', //Portuguese
    'Português brasileiro', //Portugeese (Brazilian)
    'Русский', //Russian
    'Magyar', //Hungarian
    'Polski', //Polish
    'Ελληνικά', //Greek
    '简体中文', //Chinese (Simplified Han)
    '繁體字', //Chinese (Traditional Han)
    '日本語', //Japanese
    'українська', //Ukrainian
    'türkçe', //Turkish
    'தமிழ்', //Tamil
    'български', //Bulgarian
    'Indonesia', //Indonesian
    'عربي', //Arablic
    'Suomi', //Finnish
    'Nederlands', //Dutch
    'اُردُو', //Urdu
    'Hrvat', //Croatian
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

class PreferenceUtils {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  static String getString(String key, String defValue) {
    return instance.getString(key) ?? defValue;
  }

  static getStringList(String key, List<String> defValue) {
    return instance.getStringList(key) ?? defValue;
  }

  static getBool(String key, bool defValue) {
    return instance.getBool(key) ?? defValue;
  }

  static setString(String key, String value) {
    instance.setString(key, value);
  }

  static setStringList(String key, List<String> value) {
    instance.setStringList(key, value);
  }

  static setBool(String key, bool value) {
    instance.setBool(key, value);
  }
}


class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _brightness = "auto";
  Color _themeSeedColor = Colors.blue;
  ColorScheme _colorSchemeLight = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
  ColorScheme _colorSchemeDark = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  ThemeMode get getThemeMode => _themeMode;
  String get getBrightness => _brightness;

  Color get getThemeSeedColor => _themeSeedColor;
  ColorScheme get getColorSchemeLight => _colorSchemeLight;
  ColorScheme get getColorSchemeDark => _colorSchemeDark;

  ThemeProvider() {
    _load();
  }

  void _load() {
    loadTheme();

    notifyListeners();
  }

  void loadTheme() {
    _brightness = PreferenceUtils.getString("Color mode", "light");
    switch (_brightness) {
      case "light": _themeMode = ThemeMode.light;
      case "dark": _themeMode = ThemeMode.dark;
      case "auto": _themeMode = ThemeMode.system;
    }
  }

  void setBrightness(String brightness) {
    PreferenceUtils.setString("Color mode", brightness);
    switch (brightness) {
      case "light": _themeMode = ThemeMode.light; _brightness = brightness;
      case "dark": _themeMode = ThemeMode.dark; _brightness = brightness;
      case "auto": _themeMode = ThemeMode.system; _brightness = brightness;
    }
    notifyListeners();
  }

  void changeThemeSeedColor(Color color) {
    _themeSeedColor = color;
    notifyListeners();
  }

  Future<void> changeColorSchemeToImageScheme(ColorScheme lightColorScheme, ColorScheme darkColorScheme) async {
    _colorSchemeLight = lightColorScheme;
    _colorSchemeDark = darkColorScheme;
    notifyListeners();
  }
}

class SettingsProvider with ChangeNotifier {
  String _tempUnit = "˚C";
  String _windUnit = "m/s";
  String _precipUnit = "mm";

  String _timeMode = "12 hour";
  bool _radarHapticsOn = true;

  String _location = "New York";
  String _latLon = "40.7128, -74.0060";

  String get getTempUnit => _tempUnit;
  String get getWindUnit => _windUnit;
  String get getPrecipUnit => _precipUnit;

  String get getTimeMode => _timeMode;
  bool get getRadarHapticsOn => _radarHapticsOn;

  String get getLocation => _location;
  String get getLatLon => _latLon;

  SettingsProvider() {
    _load();

    notifyListeners();
  }

  void _load() {
    _tempUnit = PreferenceUtils.getString("Temperature", "˚C");
    _windUnit = PreferenceUtils.getString("Wind", "m/s");
    _precipUnit = PreferenceUtils.getString("Precipitation", "mm");

    _timeMode = PreferenceUtils.getString("Time mode", "12 hour");
    _radarHapticsOn = PreferenceUtils.getBool("RadarHapticOn", true);

    _location = PreferenceUtils.getString("LastPlaceN", "New York");
    _latLon = PreferenceUtils.getString("LastCord", "40.7128, -74.0060");
  }

  void setLocationAndLatLon(String location, String latLon) {
    PreferenceUtils.setString("LastPlaceN", location);
    PreferenceUtils.setString("LastCord", latLon);

    _location = location;
    _latLon = latLon;

    notifyListeners();
  }

  void setTempUnit(String to) {
    PreferenceUtils.setString("Temperature", to);
    _tempUnit = to;
    notifyListeners();
  }

  void setPrecipUnit(String to) {
    PreferenceUtils.setString("Precipitation", to);
    _precipUnit = to;
    notifyListeners();
  }

  void setWindUnit(String to) {
    PreferenceUtils.setString("Wind", to);
    _windUnit = to;
    notifyListeners();
  }
}