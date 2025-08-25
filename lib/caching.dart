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

import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';

class MyGetResponse implements FileServiceResponse {
  var url;

  MyGetResponse(this._response, this.url);

  final FileServiceResponse _response;

  @override
  int get statusCode => _response.statusCode;

  @override
  Stream<List<int>> get content => _response.content;

  @override
  int? get contentLength => _response.contentLength;

  @override
  DateTime get validTill {
    if (url.toString().contains("search")) { //search results are stored for 40 days
      return DateTime.now().add(const Duration(days: 40));
    }

    //snap to the next quarter hour because that's when the weather data updates
    DateTime now = DateTime.now();
    int minutes = now.minute;
    int nextQuarter = (minutes + 15 - minutes % 15) % 60;
    int hoursToAdd = nextQuarter == 0 ? 1 : 0;

    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + hoursToAdd,
      nextQuarter,
    );

    /*
    return DateTime.now().add(
        Duration(minutes: 60 - DateTime.now().minute,
            seconds: 60 - DateTime.now().second)
    );
     */
  }

  @override
  String? get eTag => _response.eTag;

  @override
  String get fileExtension => _response.fileExtension;

}

class MyFileService extends HttpFileService {
  MyFileService({http.Client? httpClient}) : super(httpClient: httpClient) {}

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    var result = await super.get(url, headers: headers);

    var hihi = MyGetResponse(result, url);
    return hihi;
  }
}

CacheManager cacheManager = CacheManager(Config(
  "pudzikey",
  stalePeriod: const Duration(days: 20),
  fileService: MyFileService(),
));


CacheManager cacheManager2 = CacheManager(Config(
  "hihikey",
  stalePeriod: const Duration(hours: 3),
  fileService: MyFileService(),
));

CustomCacheManager XCustomCacheManager = CustomCacheManager();

class CustomCacheManager {
  static const cacheKey = "myCacheKey";
  static final CacheManager _cacheManager = CacheManager(Config(
    "hehekey",
    stalePeriod: const Duration(days: 7),
    fileService: MyFileService(),
  ));

  Future<List<dynamic>> fetchData(String url, String cacheKey, {headers}) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(cacheKey);

      //print(("got here", fileInfo?.validTill, fileInfo?.validTill.difference(DateTime.now())));

      if (fileInfo == null || fileInfo.validTill.difference(DateTime.now()).isNegative) {
        final file = await _cacheManager.downloadFile(url, key: cacheKey, authHeaders: headers).timeout(const Duration(seconds: 7));
        return [file.file, true];
      } else {
        return [fileInfo.file, true];
      }
    } catch (error) {
      print("last data");
      try {
        final FileInfo? fileInfo = await _cacheManager.getFileFromCache(cacheKey);
        return [fileInfo!.file, false];
      }
      catch (error) {
        throw const SocketException("no wifi");
      }

      //final cachedFile = await _cacheManager.getSingleFile(url);
      //return cachedFile;
    }
  }
}
