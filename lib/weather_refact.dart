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

import 'dart:ui';
import 'ui_helper.dart';

Map<String, String> textIconMap = {
  'Clear Night': 'moon.png',
  'Partly Cloudy': 'partly_cloudy.png',
  'Clear Sky': 'sun.png',
  'Overcast': 'cloudy.png',
  'Haze': 'haze.png',
  'Rain': 'rainy.png',
  'Sleet': 'sleet.png',
  'Drizzle': 'drizzle.png',
  'Thunderstorm': 'lightning.png',
  'Heavy Snow': 'heavy_snow.png',
  'Fog': 'fog.png',
  'Snow': 'snow.png',
  'Heavy Rain': 'heavy_rain.png',
  'Cloudy Night' : 'cloudy_night.png',
};

Map<String, String> weatherTextMap = {
  'Clear': 'Clear Sky',
  'Sunny': 'Clear Sky',
  'Cloudy': 'Overcast',
  'Partly Cloudy': 'Partly Cloudy',
  'Overcast': 'Overcast',
  'Mist': 'Haze',
  'Patchy rain possible': 'Rain',
  'Patchy snow possible': 'Snow',
  'Patchy sleet possible': 'Sleet',
  'Patchy freezing drizzle possible': 'Drizzle',
  'Thundery outbreaks possible': 'Thunderstorm',
  'Blowing snow': 'Heavy Snow',
  'Blizzard': 'Heavy Snow',
  'Fog': 'Fog',
  'Freezing fog': 'Fog',
  'Patchy light drizzle': 'Drizzle',
  'Light drizzle': 'Drizzle',
  'Freezing drizzle': 'Drizzle',
  'Heavy freezing drizzle': 'Drizzle',
  'Patchy light rain': 'Drizzle',
  'Light rain': 'Drizzle',
  'Moderate rain at times': 'Rain',
  'Moderate rain': 'Rain',
  'Heavy rain at times': 'Heavy Rain',
  'Heavy rain': 'Heavy Rain',
  'Light freezing rain': 'Sleet',
  'Moderate or heavy freezing rain': 'Sleet',
  'Light sleet': 'Sleet',
  'Moderate or heavy sleet': 'Sleet',
  'Patchy light snow': 'Snow',
  'Light snow': 'Snow',
  'Patchy moderate snow': 'Snow',
  'Moderate snow': 'Heavy Snow',
  'Patchy heavy snow': 'Heavy Snow',
  'Heavy snow': 'Heavy Snow',
  'Ice pellets': 'Sleet',
  'Light rain shower': 'Drizzle',
  'Moderate or heavy rain shower': 'Rain',
  'Torrential rain shower': 'Rain',
  'Light sleet showers': 'Sleet',
  'Moderate or heavy sleet showers': 'Sleet',
  'Light snow showers': 'Snow',
  'Moderate or heavy snow showers': 'Heavy Snow',
  'Light showers of ice pellets': 'Sleet',
  'Moderate or heavy showers of ice pellets': 'Sleet',
  'Patchy light rain with thunder': 'Thunderstorm',
  'Moderate or heavy rain with thunder': 'Thunderstorm',
  'Patchy light snow with thunder': 'Thunderstorm',
  'Moderate or heavy snow with thunder': 'Thunderstorm'
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
  99: 'thunderstorm',
};


Map<String, String> textBackground = {
  'Clear Night': 'clear_night.jpg',
  'Partly Cloudy': 'cloudy13.jpg',
  'Clear Sky': 'very_clear.jpg',
  'Overcast': 'overcast2.jpg',
  'Haze': 'haze.jpg',
  'Rain': 'rainy_colorfull.jpg',
  'Sleet': 'sleet.jpg',
  'Drizzle': 'drizzle.jpg',
  'Thunderstorm': 'thunderstorm.jpg',
  'Heavy Snow': 'heavy_snow.jpg',
  'Fog': 'haze.jpg',
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
  'Clear Night': const Color(0xff201F2D),
  'Partly Cloudy': const Color(0xffc3beb2),
  'Clear Sky': const Color(0xff97bddb),
  'Overcast': const Color(0xff567286),
  'Haze': const Color(0xff3C5261),
  'Rain': const Color(0xff807699),
  'Sleet': const Color(0xffd5c3cf),
  'Drizzle': const Color(0xff959f9c),
  'Thunderstorm': const Color(0xff654463),
  'Heavy Snow': const Color(0xffc6d4cc),
  'Fog': const Color(0xff2E3638),
  'Snow': const Color(0xff949590),
  'Heavy Rain': const Color(0xff314949),
  'Cloudy Night': const Color(0xff053960)
};

Map<String, Color> accentColors = {
  'Clear Night': const Color(0xFFEACD63), // Light Gold
  'Partly Cloudy': const Color(0xFF9E639F), // Lavender
  'Clear Sky': const Color(0xFF7EA3CC), // Steel Blue
  'Overcast': const Color(0xFF67878A), // Blue-Gray
  'Haze': const Color(0xFF7E8C96), // Slate Gray
  'Rain': const Color(0xFFB58EAC), // Rose Taupe
  'Sleet': const Color(0xFFD8B7C2), // Misty Rose
  'Drizzle': const Color(0xFF9FA39D), // Ash Gray
  'Thunderstorm': const Color(0xFF7F707A), // Old Lavender
  'Heavy Snow': const Color(0xFFB3C9C7), // Iceberg
  'Fog': const Color(0xFF445F61), // Raisin Black
  'Snow': const Color(0xFF6E7270), // Gray
  'Heavy Rain': const Color(0xFF6F6D70), // Quicksilver
  'Cloudy Night': const Color(0xFF35424A), // Outer Space
};

Map<int, Color> aqi_colors = {
  1: const Color(0xFFb5cbbb),
  2: const Color(0xFFFAC898),
  3: const Color(0xffE0B4D0),
  4: const Color(0xffEE8591),
  5: const Color(0xffA0025C),
  6: const Color(0xff121212),
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
  'Haze': 3,
  'Rain': 11,  // you can't go wrong by choosing the less extreme one
  'Sleet': 8,
  'Drizzle': 9,
  'Thunderstorm': 14,  // super rare
  'Heavy Snow': 12,
  'Fog': 7,
  'Snow': 13,  // you can't go wrong by choosing the less extreme one
  'Heavy Rain': 10,
  'Cloudy Night' : 1, // you don't want night in the daily summary
};