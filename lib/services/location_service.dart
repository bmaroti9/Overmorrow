import 'dart:io';
import 'dart:convert';
import '../api_key.dart';
import '../caching.dart';

class LocationService {

  static Future<List<String>> getRecommendation(String query, String? searchProvider, settings) async {
    query = _sanitizeQuery(query);
    if (query == '') {
      return [];
    }

    if (searchProvider == "weatherapi") {
      return _getWapiRecommendation(query);
    } else {
      return _getOMRecommendation(query, settings);
    }
  }

  static Future<List<String>> _getWapiRecommendation(String query) async {
    var params = {
      'key': wapi_Key,
      'q': query,
    };
    var url = Uri.http('api.weatherapi.com', 'v1/search.json', params);

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

  static Future<List<String>> _getOMRecommendation(String query, settings) async {
    var params = {
      'name': query,
      'count': '6',
      'language': 'en',
    };

    var url = Uri.http('geocoding-api.open-meteo.com', 'v1/search', params);

    var jsonbody = [];
    try {
      var file = await cacheManager.getSingleFile(url.toString(), 
        key: "$query, open-meteo search",
        headers: {'cache-control': 'private, max-age=120'})
        .timeout(const Duration(seconds: 3));
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
    return safeInput.trim().substring(0, input.length.clamp(0, 100));
  }
}