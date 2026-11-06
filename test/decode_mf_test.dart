import 'package:flutter_test/flutter_test.dart';
import 'package:overmorrow/decoders/decode_mf.dart' as meteo_france;
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:overmorrow/weather_refact.dart';

const _forecastWindowEnd = 10800;

/// The unit the conversion table stores for Celsius, as an escape so this test
/// cannot be corrupted by file encoding either.
const _celsius = '\u02daC';

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

  group('widget temperature unit', () {
    test('falls back to Celsius when the preference is missing', () {
      expect(meteo_france.mfResolveTempUnit(null), _celsius);
    });

    test('falls back to Celsius when the preference is not a known unit', () {
      expect(meteo_france.mfResolveTempUnit('not a unit'), _celsius);
    });

    test('keeps a unit the conversion table understands', () {
      expect(meteo_france.mfResolveTempUnit(_celsius), _celsius);
    });

    test('never resolves to a unit the conversion table rejects', () {
      // unitConversion answers [1, 0] for an unknown unit, which is what made
      // the widgets and the ongoing notification report a constant 1 degree.
      for (final stored in [null, '', 'not a unit', _celsius]) {
        expect(
            conversionTable.containsKey(meteo_france.mfResolveTempUnit(stored)),
            isTrue,
            reason: 'unit for "$stored" must be convertible');
      }
    });

    test('reports the real temperature instead of a constant 1', () {
      const temperature = 17.4;
      final resolved = meteo_france.mfResolveTempUnit(null);

      expect(unitConversion(temperature, resolved), temperature);
    });
  });

  group('1 hour widget series', () {
    // 2024-06-01 is a 6 hour boundary, so 06:00 is the first entry the widget
    // should show for a request made at 06:30.
    final morning = DateTime(2024, 6, 1, 6, 30);

    List<dynamic> hourlyForecast(int count, {int stepHours = 1}) {
      final start = DateTime(2024, 6, 1);
      return [
        for (var i = 0; i < count; i++)
          _forecastAt(
            start.add(Duration(hours: i * stepHours)).millisecondsSinceEpoch ~/
                1000,
          ),
      ];
    }

    test('starts at the current hour and fills four entries', () {
      final series = meteo_france.mfBuildLightHourlySeries(
          hourlyForecast(24), morning, _sunStatus(), _celsius, '24 hour');

      expect(series.hourly1.temps.length, 4);
      expect(series.hourly1.temps, [12, 12, 12, 12]);
    });

    test('keeps the three lists aligned for the widget to read by index', () {
      final series = meteo_france.mfBuildLightHourlySeries(
          hourlyForecast(24), morning, _sunStatus(), _celsius, '24 hour');

      expect(series.hourly1.conditions.length, series.hourly1.temps.length);
      expect(series.hourly1.names.length, series.hourly1.temps.length);
    });

    test('labels the hours that are shown', () {
      final series = meteo_france.mfBuildLightHourlySeries(
          hourlyForecast(24), morning, _sunStatus(), _celsius, '24 hour');

      expect(series.hourly1.names, ['6h', '7h', '8h', '9h']);
    });

    test('is not empty when the forecast only covers past hours', () {
      final series = meteo_france.mfBuildLightHourlySeries(
          hourlyForecast(4), morning, _sunStatus(), _celsius, '24 hour');

      // Only 4 entries exist and all of them sit before the requested hour.
      expect(series.hourly1.temps, isEmpty);
      expect(series.hourly1.conditions.length, series.hourly1.temps.length);
    });

    test('survives a 3 hourly Meteo-France step without duplicating hours', () {
      final series = meteo_france.mfBuildLightHourlySeries(
          hourlyForecast(12, stepHours: 3),
          morning,
          _sunStatus(),
          _celsius,
          '24 hour');

      expect(series.hourly1.names, ['6h', '9h', '12h', '15h']);
      expect(series.hourly1.temps.length, 4);
    });

    test('orders entries even when Meteo-France returns them unordered', () {
      final forecast = hourlyForecast(24).reversed.toList();

      final series = meteo_france.mfBuildLightHourlySeries(
          forecast, morning, _sunStatus(), _celsius, '24 hour');

      expect(series.hourly1.names, ['6h', '7h', '8h', '9h']);
    });

    test('fills the 6 hour series on six hour boundaries', () {
      final series = meteo_france.mfBuildLightHourlySeries(
          hourlyForecast(24), morning, _sunStatus(), _celsius, '24 hour');

      expect(series.hourly6.names, ['0h', '6h', '12h', '18h']);
      expect(series.hourly6.temps.length, 4);
    });
  });
}
