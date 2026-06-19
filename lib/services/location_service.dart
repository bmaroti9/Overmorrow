/*
Copyright (C) <2026>  <Balint Maroti>

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
import 'caching_service.dart';

const String _mfApiToken = '__Wj7dVSTjV9YGu1guveLyDq0g7S7TfTjaHBTPTpO0kj8__';

class LocationService {
  static Future<List<String>> getRecommendation(String query) async {
    query = _sanitizeQuery(query);
    if (query == '') {
      return [];
    }

    final results = await Future.wait([
      _getProviderRecommendations(() => _getWapiRecommendation(query)),
      _getProviderRecommendations(() => _getOMRecommendation(query)),
      _getProviderRecommendations(() => _getMfRecommendation(query)),
    ]);

    return _deduplicateRecommendations(results.expand((items) => items));
  }

  static Future<List<String>> _getProviderRecommendations(
      Future<List<String>> Function() fetchRecommendations) async {
    try {
      return await fetchRecommendations().timeout(const Duration(seconds: 5));
    } catch (e) {
      return [];
    }
  }

  static List<String> _deduplicateRecommendations(
      Iterable<String> recommendations) {
    final seen = <String>{};
    final deduplicated = <String>[];

    for (final recommendation in recommendations) {
      final dynamic decoded;
      try {
        decoded = jsonDecode(recommendation);
      } catch (e) {
        continue;
      }

      if (decoded is! Map<String, dynamic>) {
        continue;
      }

      final key = _recommendationKey(decoded);
      if (key == null || !seen.add(key)) {
        continue;
      }

      deduplicated.add(jsonEncode(decoded));
    }

    return deduplicated;
  }

  static String? _recommendationKey(Map<String, dynamic> recommendation) {
    final name = recommendation["name"]?.toString().trim().toLowerCase();
    final lat = _asDouble(recommendation["lat"]);
    final lon = _asDouble(recommendation["lon"]);

    if (name == null || name.isEmpty || lat == null || lon == null) {
      return null;
    }

    return "${name}_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}";
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
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

  static Future<List<String>> _getMfRecommendation(String query) async {
    var params = {
      'q': query,
      'token': _mfApiToken,
    };

    var url = Uri.https('webservice.meteofrance.com', 'places', params);

    var jsonbody = [];
    try {
      var file = await cacheManager.getSingleFile(url.toString(),
          key: "$query, meteo-france search",
          headers: {
            'cache-control': 'private, max-age=120'
          }).timeout(const Duration(seconds: 4));
      var response = await file.readAsString();
      jsonbody = jsonDecode(response);
    } catch (e) {
      return [];
    }

    List<String> recommendations = [];
    for (var item in jsonbody) {
      item["region"] = item["admin"] ?? item["admin2"] ?? "";
      item["country"] = item["country"] ?? "";
      item["lon"] = item["lon"] ?? item["longitude"];
      item["lat"] = item["lat"] ?? item["latitude"];
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
          headers: {
            'cache-control': 'private, max-age=120'
          }).timeout(const Duration(seconds: 4));
      var response = await file.readAsString();
      jsonbody = jsonDecode(response)["results"];
    } catch (e) {
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
    final safeInput = input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
    final trimmedInput = safeInput.trim();
    return trimmedInput.length > 100
        ? trimmedInput.substring(0, 100)
        : trimmedInput;
  }
}
