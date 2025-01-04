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

import 'package:overmorrow/Icons/overmorrow_weather_icons_icons.dart';
import 'package:flutter/material.dart';

import 'ui_helper.dart';

Map<String, Locale> languageNameToLocale = {
  'English': const Locale('en'),
  'Español': const Locale('es'),
  'Français': const Locale('fr'),
  'Deutsch': const Locale('de'),
  'Italiano': const Locale('it'),
  'Português': const Locale('pt'),
  'Русский': const Locale('ru'),
  'Magyar': const Locale('hu'),
  'Polski': const Locale('pl'),
  'Ελληνικά': const Locale('el'),
  '简体中文': const Locale('zh'),
  '日本語': const Locale('ja'),
  'українська': const Locale('uk'),
  'türkçe': const Locale('tr'),
};

Map<String, IconData> textMaterialIcon = {
  'Clear Night': OvermorrowWeatherIcons.moon2,
  'Partly Cloudy': OvermorrowWeatherIcons.partly_cloudy2,
  'Clear Sky': OvermorrowWeatherIcons.sun2,
  'Overcast': OvermorrowWeatherIcons.cloudy2,
  'Haze': OvermorrowWeatherIcons.haze2,
  'Rain': OvermorrowWeatherIcons.rain2,
  'Sleet': OvermorrowWeatherIcons.sleet2,
  'Drizzle': OvermorrowWeatherIcons.drizzle2,
  'Thunderstorm': OvermorrowWeatherIcons.lightning2,
  'Heavy Snow': OvermorrowWeatherIcons.heavy_snow2,
  'Fog': OvermorrowWeatherIcons.fog2,
  'Snow': OvermorrowWeatherIcons.snow2,
  'Heavy Rain': OvermorrowWeatherIcons.heavy_rain2,
  'Cloudy Night' : OvermorrowWeatherIcons.cloudy_night2,
};

String? conditionTranslation(String key, localizations) {
  final localizationMap = {
    'Clear Night': localizations.clearNight,
    'Partly Cloudy': localizations.partlyCloudy,
    'Clear Sky':localizations.clearSky,
    'Overcast': localizations.overcast,
    'Haze': localizations.haze,
    'Rain': localizations.rain,
    'Sleet': localizations.sleet,
    'Drizzle': localizations.drizzle,
    'Thunderstorm': localizations.thunderstorm,
    'Heavy Snow': localizations.heavySnow,
    'Fog': localizations.fog,
    'Snow': localizations.snow,
    'Heavy Rain': localizations.heavyRain,
    'Cloudy Night' : localizations.cloudyNight,
  };

  return localizationMap[key];
}

Map<String, List<String>> assetPhotoCredits = {
  'Clear Night': [
    'https://unsplash.com/photos/time-lapse-photography-of-stars-at-nighttime-YvOT1lJ0NPQ',
    'Jack B',
    'https://unsplash.com/@nervum'
  ],
  'Partly Cloudy': [
    'https://unsplash.com/photos/ocean-under-clouds-Plkff-dVfNM',
    'Edvinas Bruzas',
    'https://unsplash.com/@edvinasbruzas'
  ],
  'Clear Sky': [
    'https://unsplash.com/photos/blue-and-white-sky-d12K_FkCUN8',
    'Irina Iriser',
    'https://unsplash.com/@iriser'
  ],
  'Overcast':[
    'https://unsplash.com/photos/view-of-calm-sea-nQM2oClouhY',
    'Lionel Gustave',
    'https://unsplash.com/@lionel_gustave'
  ],
  'Haze': [
    'https://unsplash.com/photos/silhouette-of-trees-and-sea-L-HxY2XlaaY',
    'Casey Horner',
    'https://unsplash.com/@mischievous_penguins'
  ],
  'Rain': [
    'https://unsplash.com/photos/water-droplets-on-clear-glass-1YHXFeOYpN0',
    'Max Bender',
    'https://unsplash.com/@maxwbender'
  ],
  'Sleet': [
    'https://unsplash.com/photos/snow-covered-trees-and-road-during-daytime-wyM1KmMUSbA',
    'Nikola Johnny Mirkovic',
    'https://unsplash.com/@thejohnnyme'
  ],
  'Drizzle': [
    'https://unsplash.com/photos/a-view-of-a-plane-through-a-rain-covered-window-UsYOap7yIMg',
    'Thom Milkovic',
    'https://unsplash.com/@thommilkovic',
  ],
  'Thunderstorm': [
    'https://unsplash.com/photos/lightning-strike-on-the-sky-ley4Kf2iG7Y',
    'Jonas Kaiser',
    'https://unsplash.com/@kaiser1310'
  ],
  'Heavy Snow': [
    'https://unsplash.com/photos/snowy-forest-on-mountainside-during-daytime-t4hA-zCALUQ',
    'Willian Justen de Vasconcellos',
    'https://unsplash.com/@willianjusten',
  ],
  'Fog':[
    'https://unsplash.com/photos/green-trees-on-mountain-under-white-clouds-during-daytime-obQacWYxB1I',
    'Federico Bottos',
    'https://unsplash.com/@landscapeplaces'
  ],
  'Snow': [
    'https://unsplash.com/photos/bokeh-photography-of-snows-SH4GNXNj1RA',
    'Jessica Fadel',
    'https://unsplash.com/@jessicalfadel',
  ],
  'Heavy Rain':[
    'https://unsplash.com/photos/dew-drops-on-glass-panel-bWtd1ZyEy6w',
    'Valentin Müller',
    'https://unsplash.com/@wackeltin_meem'
  ],
  'Cloudy Night': [
    'https://unsplash.com/photos/blue-and-white-starry-night-sky-NpF9JLGYfeQ',
    'Shot by Cerqueira',
    'https://unsplash.com/@shotbycerqueira'
  ],
};

Map<String, double> textIconSizeNormalize = {
  'Clear Night': 0.77,
  'Partly Cloudy': 0.8,
  'Clear Sky': 0.8,
  'Overcast': 0.71,
  'Haze': 0.8,
  'Rain': 0.95,
  'Sleet': 1,
  'Drizzle': 1,
  'Thunderstorm': 1,
  'Heavy Snow': 0.93,
  'Fog': 0.8,
  'Snow': 0.95,
  'Heavy Rain': 0.93,
  'Cloudy Night' : 0.8,
};

Map<int, String> weatherTextMap = {
  1000: 'Clear Sky',
  1003: 'Partly Cloudy',
  1006: 'Partly Cloudy',
  1009: 'Overcast',
  1030: 'Haze',
  1063: 'Drizzle',
  1066: 'Snow',
  1069: 'Sleet',
  1072: 'Haze',
  1087: 'Thunderstorm',
  1114: 'Snow',
  1117: 'Heavy Snow',
  1135: 'Fog',
  1147: 'Fog',
  1150: 'Drizzle',
  1153: 'Drizzle',
  1168: 'Drizzle',
  1171: 'Sleet',
  1180: 'Rain',
  1183: 'Rain',
  1186: 'Rain',
  1189: 'Rain',
  1192: 'Heavy Rain',
  1195: 'Heavy Rain',
  1198: 'Sleet',
  1201: 'Sleet',
  1204: 'Sleet',
  1207: 'Sleet',
  1210: 'Snow',
  1213: 'Snow',
  1216: 'Snow',
  1219: 'Snow',
  1222: 'Heavy Snow',
  1225: 'Heavy Snow',
  1237: 'Sleet',
  1240: 'Rain',
  1243: 'Rain',
  1246: 'Heavy Rain',
  1249: 'Sleet',
  1252: 'Sleet',
  1255: 'Snow',
  1258: 'Heavy Snow',
  1261: 'Rain',
  1264: 'Heavy Rain',
  1273: 'Thunderstorm',
  1276: 'Thunderstorm',
  1279: 'Thunderstorm',
  1282: 'Thunderstorm',
};

Map<String, String> metNWeatherToText = {
  'clearsky_day': 'Clear Sky',
  'clearsky_night': 'Clear Night',
  'clearsky_polartwilight': 'Clear Night',
  'cloudy': 'Overcast',
  'fair_day': 'Partly Cloudy',
  'fair_night': 'Cloudy Night',
  'fair_polartwilight' : 'Cloudy Night',
  'fog': 'Fog',
  'heavyrain' : 'Heavy Rain',
  'heavyrainandthunder' : 'Thunderstorm',
  'heavyrainshowers_day' : 'Heavy Rain',
  'heavyrainshowers_night' : 'Heavy Rain',
  'heavyrainshowers_polartwilight' : 'Heavy Rain',
  'heavyrainshowersandthunder_day' : 'Thunderstorm',
  'heavyrainshowersandthunder_night' : 'Thunderstorm',
  'heavyrainshowersandthunder_polartwilight' : 'Thunderstorm',
  'heavysleet' : 'Sleet',
  'heavysleetandthunder' : 'Thunderstorm',
  'heavysleetshowers_day' : 'Sleet',
  'heavysleetshowers_night' : 'Sleet',
  'heavysleetshowers_polartwilight' : 'Sleet',
  'heavysleetshowersandthunder_day' : 'Thunderstorm',
  'heavysleetshowersandthunder_night' : 'Thunderstorm',
  'heavysleetshowersandthunder_polartwilight' : 'Thunderstorm',
  'heavysnow' : 'Heavy Snow',
  'heavysnowandthunder' : 'Thunderstorm',
  'heavysnowshowers_day' : 'Heavy Snow',
  'heavysnowshowers_night' : 'Heavy Snow',
  'heavysnowshowers_polartwilight' : 'Heavy Snow',
  'heavysnowshowersandthunder_day' : 'Thunderstorm',
  'heavysnowshowersandthunder_night' : 'Thunderstorm',
  'heavysnowshowersandthunder_polartwilight' : 'Thunderstorm',
  'lightrain' : 'Drizzle',
  'lightrainandthunder' : 'Thunderstorm',
  'lightrainshowers_day' : 'Drizzle',
  'lightrainshowers_night' : 'Drizzle',
  'lightrainshowers_polartwilight' : 'Drizzle',
  'lightrainshowersandthunder_day' : 'Thunderstorm',
  'lightrainshowersandthunder_night' : 'Thunderstorm',
  'lightrainshowersandthunder_polartwilight' : 'Thunderstorm',
  'lightsleet' : 'Sleet',
  'lightsleetandthunder' : 'Thunderstorm',
  'lightsleetshowers_day' : 'Sleet',
  'lightsleetshowers_night' : 'Sleet',
  'lightsleetshowers_polartwilight' : 'Sleet',
  'lightsnow' : 'Snow',
  'lightsnowandthunder' : 'Thunderstorm',
  'lightsnowshowers_day' : 'Snow',
  'lightsnowshowers_night' : 'Snow',
  'lightsnowshowers_polartwilight' : 'Snow',
  'lightssleetshowersandthunder_day' : 'Thunderstorm',
  'lightssleetshowersandthunder_night' : 'Thunderstorm',
  'lightssleetshowersandthunder_polartwilight' : 'Thunderstorm',
  'lightssnowshowersandthunder_day' : 'Thunderstorm',
  'lightssnowshowersandthunder_night' : 'Thunderstorm',
  'lightssnowshowersandthunder_polartwilight' : 'Thunderstorm',
  'partlycloudy_day' : 'Partly Cloudy',
  'partlycloudy_night' : 'Cloudy Night',
  'partlycloudy_polartwilight' : 'Cloudy Night',
  'rain' : 'Rain',
  'rainandthunder' : 'Thunderstorm',
  'rainshowers_day' : 'Rain',
  'rainshowers_night' : 'Rain',
  'rainshowers_polartwilight' : 'Rain',
  'rainshowersandthunder_day' : 'Thunderstorm',
  'rainshowersandthunder_night' : 'Thunderstorm',
  'rainshowersandthunder_polartwilight' : 'Thunderstorm',
  'sleet' : 'Sleet',
  'sleetshowers_day' : 'Sleet',
  'sleetshowers_night' :  'Sleet',
  'sleetshowers_polartwilight' : 'Sleet',
  'sleetshowersandthunder_day' : 'Thunderstorm',
  'sleetshowersandthunder_night' : 'Thunderstorm',
  'sleetshowersandthunder_polartwilight' : 'Thunderstorm',
  'snow' : 'Snow',
  'snowandthunder' : 'Thunderstorm',
  'snowshowers_day' : 'Snow',
  'snowshowers_night' : 'Snow',
  'snowshowers_polartwilight' : 'Snow',
  'snowshowersandthunder_day' : 'Thunderstorm',
  'snowshowersandthunder_night' : 'Thunderstorm',
  'snowshowersandthunder_polartwilight' : 'Thunderstorm'
 };

Map<int, String> OMCodes = {
  0: 'Clear Sky',
  1: 'Clear Sky',
  2: 'Partly Cloudy',
  3: 'Overcast',
  45: 'Fog',
  48: 'Fog',
  51: 'Drizzle',
  53: 'Drizzle',
  55: 'Rain',
  56: 'Sleet',
  57: 'Sleet',
  61: 'Rain',
  63: 'Heavy Rain',
  65: 'Heavy Rain',
  66: 'Sleet',
  67: 'Sleet',
  71: 'Snow',
  73: 'Snow',
  75: 'Heavy Snow',
  77: 'Heavy Snow',
  80: 'Drizzle',
  81: 'Rain',
  82: 'Heavy Rain',
  85: 'Snow',
  86: 'Heavy Snow',
  95: 'Thunderstorm',
  96: 'Thunderstorm',
  99: 'Thunderstorm',
};

Map<String, String> textBackground = {
  'Clear Night': 'clear_night.jpg',
  'Partly Cloudy': 'cloudy13.jpg',
  'Clear Sky': 'clear_sky3.jpg',
  'Overcast': 'overcast4.jpg',
  'Haze': 'haze.jpg',
  'Rain': 'rainy_colorfull.jpg',
  'Sleet': 'sleet.jpg',
  'Drizzle': 'drizzle.jpg',
  'Thunderstorm': 'thunderstorm4.jpg',
  'Heavy Snow': 'heavy_snow.jpg',
  'Fog': 'fog2.jpg',
  'Snow': 'snowy_sky.jpg',
  'Heavy Rain': 'heavy_rainy_sky.jpg',
  'Cloudy Night' : 'clear_night_color.jpg'
};

Map<String, List<Color>> textFontColor = {
  'Clear Night': const [BLACK, WHITE],
  'Partly Cloudy': const [WHITE, WHITE],
  'Clear Sky': const [WHITE, BLACK],
  'Overcast': const [WHITE, WHITE],
  'Haze': const [WHITE, WHITE],
  'Rain': const [WHITE, WHITE],
  'Sleet': const [WHITE, WHITE],
  'Drizzle': const [WHITE, WHITE],
  'Thunderstorm': const [WHITE, WHITE],
  'Heavy Snow': const [WHITE, WHITE],
  'Fog': const [WHITE, WHITE],
  'Snow': const [WHITE, WHITE],
  'Heavy Rain': const [WHITE, WHITE],
  'Cloudy Night': const [BLACK, WHITE]
};

Map<String, Color> textBackColor = {
  'Clear Night': const Color(0xff2d2b3f),
  'Partly Cloudy': const Color(0xffc3beb2),
  'Clear Sky': const Color(0xff3570A7),
  'Overcast': const Color(0xff1C293A),
  'Haze': const Color(0xff18374A),
  'Rain': const Color(0xff807699),
  'Sleet': const Color(0xff7A94B9),
  'Drizzle': const Color(0xff959f9c),
  'Thunderstorm': const Color(0xff776475),
  'Heavy Snow': const Color(0xffb0c4ba),
  'Fog': const Color(0xff151E1B),
  'Snow': const Color(0xff919186),
  'Heavy Rain': const Color(0xff314949),
  'Cloudy Night': const Color(0xff112f56)
};

Map<String, Color> accentColors = {
  'Clear Night': const Color(0xFF8D8F7D),
  'Partly Cloudy': const Color(0xff526181),
  'Clear Sky': const Color(0xFFA1C1D2),
  'Overcast': const Color(0xFFCDA07E),
  'Haze': const Color(0xFF968C82),
  'Rain': const Color(0xFF262A3D),
  'Sleet': const Color(0xFFD2B1C5),
  'Drizzle': const Color(0xFF45516D),
  'Thunderstorm': const Color(0xFF889B8A),
  'Heavy Snow': const Color(0xFF4A5258),
  'Fog': const Color(0xFF4C6381),
  'Snow': const Color(0xFF9BC5BD),
  'Heavy Rain': const Color(0xFF8A8667),
  'Cloudy Night': const Color(0xFF998BB5),
};

Map<String, List<int>> colorPop = {
  'Clear Night': [0, 2],
  'Partly Cloudy': [0, 0],
  'Clear Sky': [0, 0],
  'Overcast': [0, 0],
  'Haze': [0, 0],
  'Rain': [1, 0],
  'Sleet': [0, 0],
  'Drizzle': [0, 0],
  'Thunderstorm': [0, 0],
  'Heavy Snow': [0, 0],
  'Fog': [0, 0],
  'Snow': [0, 0],
  'Heavy Rain': [0, 0],
  'Cloudy Night': [0, 0],
};

Map<String, List<double>> conversionTable = {
  '˚C': [0, 1],
  '˚F': [32, 1.8],
  'mm': [0, 1],
  'in': [0, 0.0393701],
  'kph': [0, 1],
  'm/s': [0, 0.277778],
  'mph': [0, 0.621371],
  'kn' : [0, 0.539957],
  'inHg': [0, 1],
  'mmHg': [0, 25.4],
  'mb': [0, 33.864],
  'hPa': [0, 33.863886],
};

//I am trying to convert conditions to text that unsplash better understands
//for example: blue sky instead of clear sky tends to help a lot
// the ones with spaces around them is so that only the work itself will count (sun <- yes, sunglasses <- no)
Map<String, List<String>> textToUnsplashText = {
  'Clear Night': ['night', 'clear', 'moon'], //somehow just 'night' always gives you clear skies: stars or moon
  'Partly Cloudy': ['cloud'], //this is also some simplification which improves a lot
  'Clear Sky': ['sunny clear', 'sunny', ' sun ', 'clear', 'blue sky'], //it doesn't understand clear as much so i use blue instead
  'Overcast': ['overcast', 'cloud'],
  'Haze': ['haze', 'fog', 'mist'],
  'Rain': ['rain', 'drop', 'rainy', 'raining', 'drops'],
  'Sleet': ['freezing rain', 'sleet', 'ice'],//this works much better
  'Drizzle': ['light rain', 'rain', 'rainy', 'raining', 'drop', 'drops'], //somehow understands it more though still not perfect
  'Thunderstorm': ['thunderstorm', 'lightning', 'storm', 'thunder'],
  'Heavy Snow': ['heavy snow', 'snow', 'snowing', 'snows'],
  'Fog': ['fog', 'mist', 'haze'],
  'Snow': ['snow', 'snowing', 'snows'],
  'Heavy Rain': ['heavy rain', 'rain', 'drop', 'rainy', 'raining', 'drops'],
  'Cloudy Night' : ['cloud night', 'night', 'moon']
};

Map<String, bool> shouldUsePlaceName = {
  'Clear Night': true,
  'Partly Cloudy': true,
  'Clear Sky': true,
  'Overcast': true,
  'Haze': false,
  'Rain': false,
  'Sleet': false,
  'Drizzle': false,
  'Thunderstorm': false,
  'Heavy Snow': false,
  'Fog': false,
  'Snow': false,
  'Heavy Rain': false,
  'Cloudy Night': true,
};

//trying to assign values for words (for example sky will be rewarded)
//-10000 is basically taboo
Map<String, int> textFilter = {
  'sky' : 1000,
  'tree' : 500,
  'flower': 500,
  'mountain': 500,
  'ice': -10000,
  'icy': -10000,
  'bubble': -10000,
  'smoke' : -2000,
  'instagram': -2000,
  'ring': -10000,
  'during': 10000,
  'fabric': -10000,
  'texture': -10000,
  'pattern': -10000,
  'text': -10000,
  'eclipse': -10000, //it gets put in during days and it looks like night
  'wall':-10000,
  'sign': -10000,
  'grayscale' : -100000,
  'black and white' : -100000,
  'graffiti' : -2000,
  'meat' : -5000,
  'toy' : -100000,
  'man': -10000000, //trying to not have people in images
  'men': -10000000,
  'male': -1000000,
  'couple': -1000000,
  'female': -1000000,
  'human': -1000000,
  'girl': -1000000,
  'boy': -1000000,
  'kid': -1000000,
  'toddler': -1000000,
  'woman': -10000000,
  'women': -10000000,
  'person': -10000000,
  'child': -10000000,
  'crowd': -10000,
  'people': -100000,
  'hand': -100000,
  'feet': -100000,
  'bikini': -1000000,
  'swimsuit': -1000000,
};

//if i have to get the average of two weather conditions then the condition
// with the highest value will be chosen
Map<String, int> weatherConditionBiassTable = {
  'Clear Night': 1, // you don't want night in the daily summary
  'Partly Cloudy': 6,
  'Clear Sky': 5,
  'Overcast': 4,
  'Haze': 8,
  'Rain': 31,
  'Sleet': 8,
  'Drizzle': 25,
  'Thunderstorm': 35,  // super rare
  'Heavy Snow': 30,
  'Fog': 10,
  'Snow': 13,  // you can't go wrong by choosing the less extreme one
  'Heavy Rain': 30,
  'Cloudy Night' : 1, // you don't want night in the daily summary
};