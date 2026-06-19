import 'package:flutter_test/flutter_test.dart';
import 'package:overmorrow/decoders/decode_mf.dart' as meteo_france;
import 'package:overmorrow/decoders/weather_data.dart';

const _forecastWindowEnd = 10800;

Map<String, dynamic> _forecastAt(int timestamp) {
  return {
    'dt': timestamp,
    'T': {'value': 12},
    'weather': {'desc': 'Ciel clair'},
    'rain': {'1h': 0},
    'snow': {'1h': 0},
    'wind': {'speed': 5, 'direction': 180},
  };
}

WeatherSunStatus _sunStatus() {
  return WeatherSunStatus(
    sunrise: DateTime(1970, 1, 1, 6),
    sunset: DateTime(1970, 1, 1, 18),
    sunstatus: 0.5,
  );
}

Map<int, dynamic> _probabilities() {
  return {
    _forecastWindowEnd: {
      'dt': _forecastWindowEnd,
      'rain': {'3h': 40, '6h': 80},
      'snow': {'3h': 0, '6h': 0},
    },
  };
}

void main() {
  test('fills hourly precipitation probability from Meteo-France windows', () {
    final hour = meteo_france.mfWeatherHourFromJson(
      _forecastAt(3600),
      _probabilities(),
      null,
      _sunStatus(),
    );

    expect(hour.precipProb, 40);
  });

  test('prefers the shortest matching Meteo-France probability window', () {
    final hour = meteo_france.mfWeatherHourFromJson(
      _forecastAt(_forecastWindowEnd),
      _probabilities(),
      null,
      _sunStatus(),
    );

    expect(hour.precipProb, 40);
  });
}
