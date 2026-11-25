import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:overmorrow/decoders/decode_RV.dart';
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/gadgetbridge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

WeatherDay day(DateTime date, {String condition = 'Rain'}) => WeatherDay(
      date: date,
      condition: condition,
      minTempC: -2,
      maxTempC: 12,
      hourly: [],
      precipProb: 70,
      totalPrecipMm: 3,
      windKmh: 18,
      windDirA: null,
      uv: null,
    );

WeatherData weather({String provider = 'open-meteo', List<WeatherDay>? days}) {
  return WeatherData(
    place: 'Paris',
    lat: 48.8566,
    lng: 2.3522,
    provider: provider,
    updatedTime: DateTime.utc(2026, 7, 1, 10),
    fetchDatetime: DateTime.utc(2026, 7, 1, 9),
    localTime: DateTime(2026, 7, 1, 12),
    isOnline: true,
    days: days ?? [day(DateTime(2026, 7, 1)), day(DateTime(2026, 7, 2))],
    hourly72: [
      WeatherHour(
        time: DateTime(2026, 7, 1, 14),
        tempC: 20,
        condition: 'Thunderstorm',
        precipMm: 1,
        precipProb: 30,
        windKmh: 36,
        windDirA: 180,
        windGustKmh: null,
        uv: null,
      ),
    ],
    current: WeatherCurrent(
      condition: 'Clear Sky',
      tempC: 20,
      humidity: 65,
      feelsLikeC: 19,
      uv: 3,
      precipMm: 0,
      windKmh: 36,
      windDirA: 180,
    ),
    aqi: WeatherAqi(aqiIndex: 1),
    sunStatus: WeatherSunStatus(
      sunrise: DateTime(1970, 1, 1, 6),
      sunset: DateTime(1970, 1, 1, 22),
      sunstatus: 0.5,
    ),
    minutely15Precip: WeatherRain15Minutes(
      text: '', timeTo: 0, precipSumMm: 0, precipListMm: [],
    ),
    alerts: [],
    radar: const RainviewerRadar(images: [], times: [], startingIndex: 0),
    dailyMinMaxTemp: [-2, 12],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodes GadgetBridge weather with location time and future forecasts', () {
    final data = weather(days: [
      day(DateTime(2026, 7, 3), condition: 'Snow'),
      day(DateTime(2026, 6, 30)),
      day(DateTime(2026, 7, 1)),
      day(DateTime(2026, 7, 2)),
    ]);
    final decoded = jsonDecode(utf8.decode(gzip.decode(GadgetbridgeService.payload(data)))) as List;
    expect(decoded, hasLength(1));
    final spec = decoded.single as Map<String, dynamic>;
    expect(spec['timestamp'], DateTime.utc(2026, 7, 1, 9).millisecondsSinceEpoch ~/ 1000);
    expect(spec['currentTemp'], 293);
    expect(spec['todayMinTemp'], 271);
    expect(spec['todayMaxTemp'], 285);
    expect(spec['windSpeed'], 36);
    expect(spec['currentConditionCode'], 800);
    expect(spec['sunRise'], DateTime.utc(2026, 7, 1, 4).millisecondsSinceEpoch ~/ 1000);
    final forecasts = spec['forecasts'] as List;
    expect(forecasts.map((item) => item['conditionCode']), [501, 601]);
    final hour = (spec['hourly'] as List).single;
    expect(hour['timestamp'], DateTime.utc(2026, 7, 1, 12).millisecondsSinceEpoch ~/ 1000);
    expect(hour['conditionCode'], 200);
  });

  test('rejects weather without today rather than sending incorrect temperatures', () {
    expect(() => GadgetbridgeService.payload(weather(days: [day(DateTime(2026, 7, 2))])),
        throwsStateError);
  });

  test('uses Meteo-France hourly timestamps as absolute instants', () {
    final spec = GadgetbridgeService.weatherSpec(weather(provider: 'meteo-france'));
    final hour = (spec['hourly'] as List).single as Map;
    expect(hour['timestamp'], DateTime(2026, 7, 1, 14).millisecondsSinceEpoch ~/ 1000);
  });

  test('broadcasts gzip bytes only for the enabled selected location and provider', () async {
    SharedPreferences.setMockInitialValues({
      'GadgetBridge enabled': true,
      'LastPlaceN': 'Paris',
      'LastCord': '48.8566, 2.3522',
      'Weather provider': 'weatherapi',
    });
    final packages = <String>[];
    Future<void> send(String package, List<int> bytes) async {
      packages.add(package);
      expect(jsonDecode(utf8.decode(gzip.decode(bytes))), hasLength(1));
    }
    final prefs = await SharedPreferences.getInstance();

    await GadgetbridgeService.sendIfSelected(weather(provider: 'weatherapi.com'), prefs, send: send);
    expect(packages, hasLength(5));
    expect(packages, contains('nodomain.freeyourgadget.gadgetbridge'));

    await prefs.setBool('GadgetBridge enabled', false);
    await GadgetbridgeService.sendIfSelected(weather(provider: 'weatherapi.com'), prefs, send: send);
    await prefs.setBool('GadgetBridge enabled', true);
    await prefs.setString('LastCord', '0, 0');
    await GadgetbridgeService.sendIfSelected(weather(provider: 'weatherapi.com'), prefs, send: send);
    await prefs.setString('LastCord', '48.8566, 2.3522');
    await prefs.setString('Weather provider', 'met-norway');
    await GadgetbridgeService.sendIfSelected(weather(provider: 'weatherapi.com'), prefs, send: send);
    expect(packages, hasLength(5));
    await GadgetbridgeService.sendIfSelected(weather(provider: 'met norway'), prefs, send: send);
    expect(packages, hasLength(10));
  });
}
