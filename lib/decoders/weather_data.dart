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

import 'dart:async';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/decoders/decode_mn.dart';
import 'decode_wapi.dart';

class WeatherData {
  final Map<String, String> settings;

  final String place;
  final String real_loc;
  final double lat;
  final double lng;

  final String provider;

  final updatedTime;
  final fetch_datetime;
  final bool isonline;

  final localtime;

  final days;
  final hourly72;
  final current;
  final aqi;
  final sunstatus;
  final radar;
  final minutely_15_precip;
  final alerts;

  final List<double> dailyMinMaxTemp;

  WeatherData({
    required this.place,
    required this.settings,
    required this.provider,
    required this.real_loc,
    required this.lat,
    required this.lng,
    required this.sunstatus,
    required this.aqi,
    required this.radar,
    required this.days,
    required this.hourly72,
    required this.current,
    required this.fetch_datetime,
    required this.isonline,
    required this.updatedTime,
    required this.localtime,

    required this.minutely_15_precip,
    required this.alerts,

    required this.dailyMinMaxTemp
  });

  static Future<WeatherData> getFullData(settings, placeName, real_loc, latlong, provider, localizations) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    if (provider == 'weatherapi.com') {
      return WapiGetWeatherData(lat, lng, real_loc, settings, placeName, localizations);
    }
    else if (provider == "met norway"){
      return MetNGetWeatherData(lat, lng, real_loc, settings, placeName, localizations);
    }
    else {
      return OMGetWeatherData(lat, lng, real_loc, settings, placeName, localizations);
    }
  }
}


//A more lightweight version of data fetching for the current weather widgets to use
class LightCurrentWeatherData {
  final String place;
  final int temp;
  final String condition;
  final String updatedTime;
  final String dateString;

  LightCurrentWeatherData({
    required this.place,
    required this.updatedTime,
    required this.condition,
    required this.temp,
    required this.dateString,
  });

  static Future<LightCurrentWeatherData> getLightCurrentWeatherData(placeName, latlong, provider, settings) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightCurrentData(settings, placeName, lat, lng);
      case "met-norway":
        return metNGetLightCurrentData(settings, placeName, lat, lng);
      default:
        return omGetLightCurrentData(settings, placeName, lat, lng);
    }
  }
}

class LightWindData {
  final int windSpeed;
  final int windDirAngle;
  final String windUnit;

  LightWindData({
    required this.windDirAngle,
    required this.windSpeed,
    required this.windUnit,
  });

  static Future<LightWindData> getLightWindData(placeName, latlong, provider, settings) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lon = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightWindData(settings, placeName, lat, lon);
      case "met-norway":
        return metNGetLightWindData(settings, placeName, lat, lon);
      default:
        return omGetLightWindData(settings, lat, lon);
    }
  }
}

class LightHourlyForecastData {
  final int currentTemp;
  final String currentCondition;
  final String place;
  final String updatedTime;
  final String hourlyConditions;
  final String hourlyTemps;
  final String hourlyNames;

  LightHourlyForecastData({
    required this.place,
    required this.currentCondition,
    required this.currentTemp,
    required this.updatedTime,
    required this.hourlyConditions,
    required this.hourlyNames,
    required this.hourlyTemps
  });

  static Future<LightHourlyForecastData> getLightForecastData(placeName, latLon, provider, settings) async {

    List<String> split = latLon.split(",");
    double lat = double.parse(split[0]);
    double lon = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightHourlyData(settings, placeName, lat, lon);
      case "met-norway":
        return metNGetLightHourlyData(settings, placeName, lat, lon);
      default:
        return omGetHourlyForecast(settings, placeName, lat, lon);
    }
  }
}
