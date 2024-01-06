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

import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
    if (url.toString().contains("search.json")) {
      return DateTime.now().add(const Duration(days: 20));
    }

    return DateTime.now().add(
        Duration(minutes: 60 - DateTime.now().minute,
            seconds: 60 - DateTime.now().second)
    );
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

    print((hihi.validTill, 'hihi'));
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
