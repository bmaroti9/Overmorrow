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

  ThemeMode get getThemeMode => _themeMode;
  Color get getThemeSeedColor => _themeSeedColor;

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
}


class SettingsProvider with ChangeNotifier {
  List<String> _favorites = [];

  List<String> get getFavorites => _favorites;

  SettingsProvider() {
    _load();
  }

  void _load() {
    loadFavorites();

    notifyListeners();
  }

  void loadFavorites() {
    final ifnot = ["{\n        \"id\": 2651922,\n        \"name\": \"Nashville\",\n        \"region\": \"Tennessee\",\n        \"country\": \"United States of America\",\n        \"lat\": 36.17,\n        \"lon\": -86.78,\n        \"url\": \"nashville-tennessee-united-states-of-america\"\n    }"];
    _favorites = PreferenceUtils.getStringList('favorites', ifnot);
  }

  void changeFavorites(List<String> value) {
    PreferenceUtils.setStringList('favorites', value);
    _favorites = value;
    notifyListeners();
  }

}