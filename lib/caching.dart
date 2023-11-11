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
    print(url);
    if (url.toString().contains("forecast.json")) {
      return DateTime.now().add(
          Duration(minutes: 60 - DateTime.now().minute,
          seconds: 60 - DateTime.now().second)
      );
    }
    return DateTime.now().add(const Duration(days: 20));
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
  stalePeriod: const Duration(hours: 3),
  fileService: MyFileService(),
));
