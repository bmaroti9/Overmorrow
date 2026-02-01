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
import 'package:overmorrow/decoders/decode_RV.dart';
import 'package:overmorrow/decoders/decode_mn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'decode_wapi.dart';
import 'package:flutter/material.dart';

class WeatherCurrent {
  final String condition;
  final double tempC;
  final int humidity;
  final double feelsLikeC;
  final int uv;
  final double precipMm;

  final double windKmh;
  final int windDirA;

  WeatherCurrent({
    required this.condition,
    required this.tempC,
    required this.humidity,
    required this.feelsLikeC,
    required this.uv,
    required this.precipMm,
    required this.windKmh,
    required this.windDirA,
  });

}

class WeatherDay {
  final String condition;

  final DateTime date;

  final double minTempC;
  final double maxTempC;

  final List<WeatherHour> hourly;

  final int? precipProb;
  final double totalPrecipMm;

  final double windKmh;
  final int? windDirA;

  final int? uv;

  WeatherDay ({
    required this.condition,
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.hourly,
    required this.precipProb,
    required this.totalPrecipMm,
    required this.windKmh,
    required this.windDirA,
    required this.uv,
  });
}

class WeatherHour {
  final double tempC;

  final DateTime time;

  final String condition;
  final double precipMm;
  final int? precipProb;
  final double windKmh;
  final int? windDirA;
  final double? windGustKmh;
  final int? uv;

  WeatherHour({
    required this.tempC,
    required this.time,
    required this.condition,
    required this.precipMm,
    required this.precipProb,
    required this.windKmh,
    required this.windDirA,
    required this.windGustKmh,
    required this.uv,
  });
}

class WeatherSunStatus {
  final DateTime sunrise;
  final DateTime sunset;
  final double sunstatus;

  WeatherSunStatus({
    required this.sunrise,
    required this.sunset,
    required this.sunstatus,
  });
}

class WeatherAlert {
  final String headline;
  final DateTime? start;
  final DateTime? end;
  final String desc;
  final String event;
  final String urgency;
  final String severity;
  final String certainty;
  final String areas;

  const WeatherAlert({
    required this.headline,
    required this.start,
    required this.end,
    required this.desc,
    required this.event,
    required this.urgency,
    required this.severity,
    required this.certainty,
    required this.areas,
  });
}

class WeatherRain15Minutes {
  final String text;
  final int timeTo;
  final double precipSumMm;
  final List<double> precipListMm;

  WeatherRain15Minutes({
    required this.text,
    required this.timeTo,
    required this.precipSumMm,
    required this.precipListMm,
  });
}

class WeatherAqi {
  //this used to be bigger but i've moved stuff out and only the index remains
  //still gonna keep it a class in case i want to add more stuff in the future

  final int aqiIndex;

  WeatherAqi({
    required this.aqiIndex
  });
}

class WeatherData {

  final String place;
  final double lat;
  final double lng;

  final String provider;

  final DateTime updatedTime;
  final DateTime fetchDatetime;
  final DateTime localTime;

  final bool isOnline;

  final List<WeatherDay> days;
  final List<dynamic> hourly72;
  final WeatherCurrent current;
  final WeatherAqi aqi;
  final WeatherSunStatus sunStatus;
  final WeatherRain15Minutes minutely15Precip;
  final List<WeatherAlert> alerts;

  final RainviewerRadar radar;

  final List<double> dailyMinMaxTemp;

  WeatherData({
    required this.place,
    required this.lat,
    required this.lng,

    required this.provider,

    required this.sunStatus,
    required this.aqi,
    required this.radar,
    required this.days,
    required this.hourly72,
    required this.current,
    required this.fetchDatetime,
    required this.isOnline,
    required this.updatedTime,
    required this.localTime,

    required this.minutely15Precip,
    required this.alerts,

    required this.dailyMinMaxTemp
  });

  static Future<WeatherData> getFullData(String placeName, latLon, String provider) async {

    List<String> split = latLon.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    if (provider == 'weatherapi') {
      return WapiGetWeatherData(lat, lng, placeName);
    }
    else if (provider == "met-norway"){
      return MetNGetWeatherData(lat, lng, placeName);
    }
    else {
      return oMGetWeatherData(lat, lng, placeName);
    }

  }
}


class WeatherError {
  String? errorTitle;
  String? errorDesc;
  IconData? errorIcon;
  String latLon;
  String location;

  WeatherError({
    this.errorTitle,
    this.errorDesc,
    this.errorIcon,
    required this.location,
    required this.latLon,
  });
}


//---------------------------------- WIDGET DATA CLASSES -------------------------------------

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

  static Future<LightCurrentWeatherData> getLightCurrentWeatherData(placeName, latlong, provider, SharedPreferences prefs) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightCurrentData(placeName, lat, lng, prefs);
      case "met-norway":
        return metNGetLightCurrentData(placeName, lat, lng, prefs);
      default:
        return omGetLightCurrentData(placeName, lat, lng, prefs);
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

  static Future<LightWindData> getLightWindData(placeName, latlong, provider, SharedPreferences prefs) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lon = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightWindData(lat, lon, prefs);
      case "met-norway":
        return metNGetLightWindData(lat, lon, prefs);
      default:
        return omGetLightWindData(lat, lon, prefs);
    }
  }
}

class LightUvData {
  final int uv;

  LightUvData({
    required this.uv
  });

  static Future<LightUvData> getLightUvData(placeName, latlong, provider, SharedPreferences prefs) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lon = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightUvData(lat, lon, prefs);
      case "met-norway":
        return metNGetLightUvData(lat, lon, prefs);
      default:
        return omGetLightUvData(lat, lon, prefs);
    }
  }
}

class LightHourlyForecastData {
  final int currentTemp;
  final String currentCondition;
  final String place;
  final String updatedTime;

  //hours with 6 hourly interval
  final String hourly6Conditions;
  final String hourly6Temps;
  final String hourly6Names;

  //hours with 1 hourly interval
  final String hourly1Conditions;
  final String hourly1Temps;
  final String hourly1Names;

  LightHourlyForecastData({
    required this.place,
    required this.currentCondition,
    required this.currentTemp,
    required this.updatedTime,
    required this.hourly6Conditions,
    required this.hourly6Names,
    required this.hourly6Temps,
    required this.hourly1Conditions,
    required this.hourly1Names,
    required this.hourly1Temps
  });

  static Future<LightHourlyForecastData> getLightForecastData(placeName, latLon, provider, SharedPreferences prefs) async {

    List<String> split = latLon.split(",");
    double lat = double.parse(split[0]);
    double lon = double.parse(split[1]);

    switch (provider) {
      case "weatherapi":
        return wapiGetLightHourlyData(placeName, lat, lon, prefs);
      case "met-norway":
        return metNGetLightHourlyData(placeName, lat, lon, prefs);
      default:
        return omGetHourlyForecast(placeName, lat, lon, prefs);
    }
  }
}