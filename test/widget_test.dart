import 'package:flutter_test/flutter_test.dart';
import 'package:overmorrow/decoders/decode_mf.dart' as meteo_france;
import 'package:overmorrow/decoders/weather_data.dart';

void main() {
  test('Meteo France decoder entry points are available', () {
    expect(meteo_france.MfGetWeatherData, isNotNull);
    expect(meteo_france.mfGetLightCurrentData, isNotNull);
    expect(meteo_france.mfGetLightWindData, isNotNull);
    expect(meteo_france.mfGetLightUvData, isNotNull);
    expect(meteo_france.mfGetLightHourlyData, isNotNull);
    expect(WeatherData.getFullData, isNotNull);
  });
}
