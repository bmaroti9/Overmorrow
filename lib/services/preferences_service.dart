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

import 'package:overmorrow/weather_refact.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'color_service.dart';

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

  String _themeSeedColorHex = "#c62828";
  Color _themeSeedColor = Colors.red;

  String _colorSource = "image";

  ColorScheme? _colorSchemeLight;
  ColorScheme? _colorSchemeDark;

  ThemeMode get getThemeMode => _themeMode;
  String get getBrightness => _brightness;

  String get getColorSource => _colorSource;

  String get getThemeSeedColorHex => _themeSeedColorHex;
  Color get getThemeSeedColor => _themeSeedColor;

  ColorScheme? get getColorSchemeLight => _colorSchemeLight;
  ColorScheme? get getColorSchemeDark => _colorSchemeDark;

  ThemeProvider() {
    _load();
  }

  void _load() {
    loadTheme();
    _loadColorSource();

    notifyListeners();
  }

  void loadTheme() {
    _brightness = PreferenceUtils.getString("Color mode", "auto");
    switch (_brightness) {
      case "light": _themeMode = ThemeMode.light;
      case "dark": _themeMode = ThemeMode.dark;
      case "auto": _themeMode = ThemeMode.system;
    }
  }

  void _loadColorSource() {
    _colorSource = PreferenceUtils.getString("Color source", "image");
    if (_colorSource == "custom") {
      loadCustomColorScheme();
    }
  }

  void loadCustomColorScheme() {
    _themeSeedColorHex = PreferenceUtils.getString("Custom color", "#c62828");
    updateCustomColorFromHex();
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

  void changeColorSchemeToImageScheme(ColorScheme lightColorScheme, ColorScheme darkColorScheme) {
    _colorSchemeLight = lightColorScheme;
    _colorSchemeDark = darkColorScheme;
    notifyListeners();
  }

  void setColorSource(String to) {
    PreferenceUtils.setString("Color source", to);
    _colorSource = to;

    if (_colorSource == "wallpaper") {
      //null it so it falls back to the dynamic palettes
      _colorSchemeLight = null;
      _colorSchemeDark = null;
    }
    else if (_colorSource == "custom") {
      loadCustomColorScheme();
    }
    notifyListeners();
  }

  void updateCustomColorFromHex() {
    _themeSeedColor = Color(getColorFromHex(_themeSeedColorHex));
    _colorSchemeLight = ColorScheme.fromSeed(seedColor: _themeSeedColor, brightness: Brightness.light);
    _colorSchemeDark = ColorScheme.fromSeed(seedColor: _themeSeedColor, brightness: Brightness.dark);
  }

  void setCustomColorScheme(String to) {
    _themeSeedColorHex = to;
    updateCustomColorFromHex();
    notifyListeners();
  }
}

class SettingsProvider with ChangeNotifier {
  String _weatherProvider = "open-meteo";

  String _tempUnit = "˚C";
  String _windUnit = "m/s";
  String _precipUnit = "mm";

  String _timeMode = "12 hour";
  String _dateFormat = "mm/dd";

  bool _radarHapticsOn = true;

  String _searchProvider = "weatherapi";

  String _imageSource = "network";

  Locale _locale = const Locale("en");
  String _localeName = "English";

  String _location = "New York";
  String _latLon = "40.7128, -74.0060";

  String get getWeatherProvider => _weatherProvider;

  String get getTempUnit => _tempUnit;
  String get getWindUnit => _windUnit;
  String get getPrecipUnit => _precipUnit;

  String get getTimeMode => _timeMode;
  String get getDateFormat => _dateFormat;

  bool get getRadarHapticsOn => _radarHapticsOn;

  String get getSearchProvider => _searchProvider;

  String get getImageSource => _imageSource;

  Locale get getLocale => _locale;
  String get getLocaleName => _localeName;

  String get getLocation => _location;
  String get getLatLon => _latLon;

  SettingsProvider() {
    _load();
    _loadLocale();

    notifyListeners();
  }

  void _load() {
    _weatherProvider = PreferenceUtils.getString("Weather provider", "open-meteo");

    _tempUnit = PreferenceUtils.getString("Temperature", "˚C");
    _windUnit = PreferenceUtils.getString("Wind", "m/s");
    _precipUnit = PreferenceUtils.getString("Precipitation", "mm");

    _timeMode = PreferenceUtils.getString("Time mode", "12 hour");
    _radarHapticsOn = PreferenceUtils.getBool("RadarHapticOn", true);

    _imageSource = PreferenceUtils.getString("Image source", "network");

    _searchProvider = PreferenceUtils.getString("Search provider", "weatherapi");

    _location = PreferenceUtils.getString("LastPlaceN", "New York");
    _latLon = PreferenceUtils.getString("LastCord", "40.7128, -74.0060");
  }

  void _loadLocale() {
    _localeName = PreferenceUtils.getString("Language", "English");
    _locale = languageNameToLocale[_localeName] ?? const Locale("en");
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

  void setImageSource(String to) {
    PreferenceUtils.setString("Image source", to);
    _imageSource = to;
    notifyListeners();
  }

  void setLocale(String to) {
    PreferenceUtils.setString("Language", to);
    _localeName = to;
    _locale = languageNameToLocale[to] ?? const Locale("en");
    notifyListeners();
  }

  void setTimeMode(String to) {
    PreferenceUtils.setString("Time mode", to);
    _timeMode = to;
    notifyListeners();
  }

  void setDateFormat(String to) {
    PreferenceUtils.setString("Date format", to);
    _dateFormat = to;
    notifyListeners();
  }

  void setRadarHaptics(bool to) {
    PreferenceUtils.setBool("Radar haptics", to);
    _radarHapticsOn = to;
    notifyListeners();
  }

  void setSearchProvider(String to) {
    PreferenceUtils.setString("Search provider", to);
    _searchProvider = to;
    notifyListeners();
  }

  void setWeatherPovider(String to) {
    PreferenceUtils.setString("Weather provider", to);
    _weatherProvider = to;
    notifyListeners();
  }
}