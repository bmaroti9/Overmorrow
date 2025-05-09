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
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/decoders/decode_mn.dart';

import '../api_key.dart';
import '../caching.dart';

import '../weather_refact.dart';
import 'decode_wapi.dart';

Future<List<dynamic>> getUnsplashImage(String _text, String real_loc, double lat, double lng) async {

  List<String> keys1 = textFilter.keys.toList();
  //this is all to make sure that none
  // of the banned words get somehow into the search query
  String loc = real_loc;
  for (int i = 0; i < keys1.length; i++) {
    if (loc.contains(keys1[i])) {
      loc = "";
    }
  }

  String text_query = textToUnsplashText[_text]![0];
  String placeName = shouldUsePlaceName[_text]! ? " $loc" : "";
  placeName = "";

  //print(("textquery", "$text_query, $loc", _text, text_query + placeName));

  final params2 = {
    'client_id': access_key,
    'query' : text_query + placeName,
    'content_filter' : 'high',
    'count': '6',
    //'collections' : '893395, 583204, 11649432, 162468, 1492135, 42478673, 8253647, 461360'
    //'collections' : '893395, 162468, 461360'
  };

  final url2 = Uri.https('api.unsplash.com', 'photos/random', params2);

  //await cacheManager2.removeFile("$text_query $loc");

  //var file2 = await cacheManager2.getSingleFile(url2.toString(), key: "$text_query $loc")
  //    .timeout(const Duration(seconds: 6));

  var file2 = await XCustomCacheManager.fetchData(url2.toString(), "$text_query $loc unsplash");

  var response2 = await file2[0].readAsString();

  var unsplash_body = jsonDecode(response2);

  int index = 0;
  double best = 99999999999;

  for (int i = 0; i < unsplash_body.length; i++) {
    double lat_dif = pow((lat - (unsplash_body[i]["location"]["position"]["latitude"] ?? 9999)).abs(), 2) * 1.0;
    double lng_dif = pow((lng - (unsplash_body[i]["location"]["position"]["longitude"] ?? 9999)).abs(), 2) * 1.0;
    double unaccuracy = min(lat_dif + lng_dif, 100) * 20;

    if (unsplash_body[i]["location"]["position"]["city"] == real_loc) {
      unaccuracy -= 1000;
    }

    var desc1 = unsplash_body[i]["description"] ?? " ";
    //var desc2 = unsplash_body[i]["links"]["html"] ?? " ";
    var desc3 = unsplash_body[i]["alt_description"] ?? " ";

    String desc = desc1.toLowerCase() + " " + desc3.toLowerCase();
    desc = " ${desc.replaceAll("-", " ")} ";
    List<String> keys2 = textToUnsplashText.keys.toList();
    for (int x = 0; x < textToUnsplashText.length; x ++) {
      for (int y = 0; y < textToUnsplashText[keys2[x]]!.length; y ++) {
        String lookFor = textToUnsplashText[keys2[x]]![y];
        int reward = keys2[x] == _text ? -3000 : 2000;
        if (textToUnsplashText[_text]!.contains(lookFor)) {
          if (reward == 2000) {
            reward = 0;
          }
        }
        if (desc.contains(lookFor)) {
          //print(("punished1", textToUnsplashText[keys2[x]]![y], reward, lookFor, textToUnsplashText[_text]));
          unaccuracy += reward; // i had to reverse it
        }
      }
    }

    for (int x = 0; x < textFilter.length; x ++) {
      if (desc.contains(keys1[x])) {
        //print(("punished2", keys1[x], -textFilter[keys1[x]]!));
        unaccuracy -= textFilter[keys1[x]]!; // i had to reverse it
      }
    }

    double ratings = unsplash_body[i]["likes"] * 0.02 ?? 0;
    ratings += unsplash_body[i]["downloads"] * 0.01 ?? 0;
    //print(("ratings", ratings));

    unaccuracy -= min(ratings, 2000);

    //print((i, unaccuracy.toStringAsFixed(6), (desc1 ?? "null").trim() + ", " +  unsplash_body[i]["likes"], unsplash_body[i]["downloads"]));
    if (unaccuracy < best) {
      index = i;
      best = unaccuracy;
    }
  }

  String image_path = unsplash_body[index]["urls"]["regular"];
  //print(index);
  //print(unsplash_body[index]["links"]["html"]);

  final String userLink = (unsplash_body[index]["user"]["links"]["html"]) ?? "";

  //i don't want emojis because they ruin the one color aspect of the app
  String username = unsplash_body[index]["user"]["name"] ?? "";
  final RegExp regExp = RegExp(r'[\u2700-\u27bf]|(?:\ud83c[\udde6-\uddff]){2}|[\ud800-\udbff][\udc00-\udfff]|[\u0023-\u0039]\ufe0f?\u20e3|\u3299|\u3297|\u303d|\u3030|\u24c2|\ud83c[\udd70-\udd71]|\ud83c[\udd7e-\udd7f]|\ud83c\udd8e|\ud83c[\udd91-\udd9a]|\ud83c[\udde6-\uddff]|\ud83c[\ude01-\ude02]|\ud83c\ude1a|\ud83c\ude2f|\ud83c[\ude32-\ude3a]|\ud83c[\ude50-\ude51]|\u203c|\u2049|[\u25aa-\u25ab]|\u25b6|\u25c0|[\u25fb-\u25fe]|\u00a9|\u00ae|\u2122|\u2139|\ud83c\udc04|[\u2600-\u26FF]|\u2b05|\u2b06|\u2b07|\u2b1b|\u2b1c|\u2b50|\u2b55|\u231a|\u231b|\u2328|\u23cf|[\u23e9-\u23f3]|[\u23f8-\u23fa]|\ud83c\udccf|\u2934|\u2935|[\u2190-\u21ff]');
  username = username.replaceAll(regExp, "_");

  final String photoLink = unsplash_body[index]["links"]["html"] ?? "";

  //final Color color = HexColor(unsplash_body[index]["color"]);

  print(unsplash_body[index]["color"]);

  //print((username, userLink));

  return [Image(image: CachedNetworkImageProvider(image_path), fit: BoxFit.cover,
    width: double.infinity, height: double.infinity,), username, userLink, photoLink];
}


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

class RainviewerRadar {
  final List<String> images;
  final List<String> times;

  const RainviewerRadar({
    required this.images,
    required this.times
  });

  static RainviewerRadar fromJson(images, times) => RainviewerRadar(
      images: images,
      times: times
  );

  static Future<RainviewerRadar> getData() async {
  const String url = 'https://api.rainviewer.com/public/weather-maps.json';

  //var file = await cacheManager2.getSingleFile(url.toString());
  var file = await XCustomCacheManager.fetchData(url.toString(), url.toString());
  var response = await file[0].readAsString();
  final Map<String, dynamic> data = json.decode(response);

  final String host = data["host"];

  List<String> images = [];
  List<String> times = [];

  final past = data["radar"]["past"];
  final future = data["radar"]["nowcast"];

  for (var x in past) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
    images.add(host + x["path"]);
    times.add("${time.hour}h ${time.minute}m");
  }

  for (var x in future) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
    images.add(host + x["path"]);
    times.add("${time.hour}h ${time.minute}m");
  }

  return RainviewerRadar.fromJson(images, times);
  }
}
