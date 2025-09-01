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
import 'decode_wapi.dart';

class WeatherCurrent {
  final String condition;
  final double tempC;
  final int humidity;
  final double feelsLikeC;
  final int uv;
  final double precipMm;

  final double windKph;
  final int windDirA;

  WeatherCurrent({
    required this.condition,
    required this.tempC,
    required this.humidity,
    required this.feelsLikeC,
    required this.uv,
    required this.precipMm,
    required this.windKph,
    required this.windDirA,
  });

}

class WeatherDay {
  final String condition;

  final DateTime date;

  final double minTempC;
  final double maxTempC;

  final List<WeatherHour> hourly;

  final int precipProb;
  final double totalPrecipMm;

  final double windKph;
  final int windDirA;

  final int uv;

  WeatherDay ({
    required this.condition,
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.hourly,
    required this.precipProb,
    required this.totalPrecipMm,
    required this.windKph,
    required this.windDirA,
    required this.uv,
  });
}

class WeatherHour {
  final double tempC;

  final DateTime time;

  final String condition;
  final double precipMm;
  final int precipProb;
  final double windKph;
  final int windDirA;
  final double windGustKph;
  final int uv;

  WeatherHour({
    required this.tempC,
    required this.time,
    required this.condition,
    required this.precipMm,
    required this.precipProb,
    required this.windKph,
    required this.windDirA,
    required this.windGustKph,
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
  final DateTime start;
  final DateTime end;
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

    print(("fetching", provider));

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
