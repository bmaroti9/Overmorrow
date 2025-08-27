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

import 'ui_helper.dart';

Map<String, Locale> languageNameToLocale = {
  'English': const Locale('en'),
  'Español': const Locale('es'),
  'Français': const Locale('fr'),
  'Deutsch': const Locale('de'),
  'Italiano': const Locale('it'),
  'Português': const Locale('pt'),
  'Português brasileiro' : const Locale('pt', 'BR'),
  'Русский': const Locale('ru'),
  'Magyar': const Locale('hu'),
  'Polski': const Locale('pl'),
  'Ελληνικά': const Locale('el'),
  '简体中文': const Locale('zh'),
  '繁體字' : const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  '日本語': const Locale('ja'),
  'українська': const Locale('uk'),
  'türkçe': const Locale('tr'),
  'தமிழ்' : const Locale('ta'),
  'български': const Locale('bg'),
  'Indonesia': const Locale('id'),
  'عربي': const Locale('ar'),
  'Suomi': const Locale('fi'),
  'Nederlands' : const Locale('nl'),
  'اُردُو' : const Locale('ur'),
  'Hrvat' : const Locale('hr'),
};

Map<String, String> weatherIconPathMap = {
  'Clear Night': "assets/weather_icons/clear_night.svg",
  'Partly Cloudy': "assets/weather_icons/partly_cloudy.svg",
  'Clear Sky': "assets/weather_icons/clear_sky.svg",
  'Overcast': "assets/weather_icons/cloudy.svg",
  'Haze': "assets/weather_icons/haze.svg",
  'Rain': "assets/weather_icons/rain.svg",
  'Sleet': "assets/weather_icons/sleet.svg",
  'Drizzle': "assets/weather_icons/drizzle.svg",
  'Thunderstorm': "assets/weather_icons/thunderstorm.svg",
  'Heavy Snow': "assets/weather_icons/heavy_snow.svg",
  'Fog': "assets/weather_icons/fog.svg",
  'Snow': "assets/weather_icons/snow.svg",
  'Heavy Rain': "assets/weather_icons/heavy_rain.svg",
  'Cloudy Night' : "assets/weather_icons/cloudy_night.svg",
};


//each condition has a separate unsplash collection where i selected the best images i could find
//this map links the weather conditions to the collection's id
Map<String, String> conditionToCollection = {
  'Clear Night': 'QmrZHMXsUjU',
  'Partly Cloudy': 'HAtvB157RoQ',
  'Clear Sky': 'XMGA2-GGjyw',
  'Overcast': 'lH8D73y8two',
  'Haze': 'p0Z3vz_3QDI',
  'Rain': 'EHfrmBnBxKE',
  'Sleet': '6iA4l-qOEjQ',
  'Drizzle': 'gPoFdup1ER0',
  'Thunderstorm': 'u5yh41EfPWk',
  'Heavy Snow': 'Wz6zjLX6zoQ',
  'Fog': 'lt3McWCS6sk',
  'Snow': 'IV6PyvU0Vyo',
  'Heavy Rain': '9w3d8QBzjsw',
  'Cloudy Night' : 'ymdgzsktNTE'
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

Map<int, String> oMCodes = {
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