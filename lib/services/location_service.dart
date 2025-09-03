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

import 'dart:io';
import 'dart:convert';

import '../api_key.dart';
import '../caching.dart';

class LocationService {

  static Future<List<String>> getRecommendation(String query, String searchProvider) async {

    query = _sanitizeQuery(query);
    if (query == '') {
      return [];
    }

    if (searchProvider == "weatherapi") {
      return _getWapiRecommendation(query);
    } else {
      return _getOMRecommendation(query);
    }
  }

  static Future<List<String>> _getWapiRecommendation(String query) async {
    var params = {
      'key': wapi_Key,
      'q': query,
    };
    var url = Uri.https('api.weatherapi.com', 'v1/search.json', params);

    var jsonbody = [];
    try {
      var file = await cacheManager.getSingleFile(url.toString(), 
        headers: {'cache-control': 'private, max-age=120'});
      var response = await file.readAsString();
      jsonbody = jsonDecode(response);
    } on SocketException {
      return [];
    }

    List<String> recommendations = [];
    for (var item in jsonbody) {
      recommendations.add(json.encode(item));
    }

    return recommendations;
  }

  static Future<List<String>> _getOMRecommendation(String query) async {
    var params = {
      'name': query,
      'count': '10',
      'language': 'en',
    };

    var url = Uri.https('geocoding-api.open-meteo.com', 'v1/search', params);

    var jsonbody = [];
    try {
      var file = await cacheManager.getSingleFile(url.toString(), 
        key: "$query, open-meteo search",
        headers: {'cache-control': 'private, max-age=120'})
        .timeout(const Duration(seconds: 4));
      var response = await file.readAsString();
      jsonbody = jsonDecode(response)["results"];
    } catch(e) {
      return [];
    }

    List<String> recommendations = [];
    for (var item in jsonbody) {
      String pre = json.encode(item);

      if (!pre.contains('"admin1"')) {
        item["region"] = "";
      } else {
        item["region"] = item['admin1'];
      }

      if (!pre.contains('"country"')) {
        item["country"] = "";
      }

      String x = json.encode(item);
      x = x.replaceAll('latitude', "lat");
      x = x.replaceAll('longitude', "lon");

      recommendations.add(x);
    }
    return recommendations;
  }

  /// Sanitizes the input query string by removing unsafe characters and limiting length
  static String _sanitizeQuery(String input) {
    final safeInput = input.replaceAll(RegExp(r'[^\w\s,\-]'), '');
    final trimmedInput = safeInput.trim();
    return trimmedInput.length > 100 ? trimmedInput.substring(0, 100) : trimmedInput;
  }
}