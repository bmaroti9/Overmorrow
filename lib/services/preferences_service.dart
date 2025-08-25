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

  static setString(String key, String value) {
    instance.setString(key, value);
  }

  static setStringList(String key, List<String> value) {
    instance.setStringList(key, value);
  }
}


class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeSeedColor = Colors.blue;
  ColorScheme _colorSchemeLight = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
  ColorScheme _colorSchemeDark = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  ThemeMode get getThemeMode => _themeMode;
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
    String brightness = PreferenceUtils.getString("Color mode", "light");
    switch (brightness) {
      case "light": _themeMode = ThemeMode.light;
      case "dark": _themeMode = ThemeMode.dark;
      case "auto": _themeMode = ThemeMode.system;
    }
  }

  void changeTheme(String brightness) {
    PreferenceUtils.setString("Color mode", brightness);
    switch (brightness) {
      case "light": _themeMode = ThemeMode.light;
      case "dark": _themeMode = ThemeMode.dark;
      case "auto": _themeMode = ThemeMode.system;
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

  String get getTempUnit => _tempUnit;
  String get getWindUnit => _windUnit;
  String get getPrecipUnit => _precipUnit;

  SettingsProvider() {
    _load();

    notifyListeners();
  }

  void _load() {
    _tempUnit = PreferenceUtils.getString("Temperature", "˚C");
    _windUnit = PreferenceUtils.getString("Wind", "m/s");
    _precipUnit = PreferenceUtils.getString("Precipitation", "mm");
  }
}