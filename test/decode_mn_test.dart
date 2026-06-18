import 'package:flutter_test/flutter_test.dart';
import 'package:overmorrow/decoders/decode_mn.dart' as met_norway;

Map<String, dynamic> _metNHour(String time) {
  return {
    'time': time,
    'data': {
      'instant': {
        'details': {
          'air_temperature': 12.0,
          'wind_speed': 5.0,
          'wind_from_direction': 180.0,
          'ultraviolet_index_clear_sky': 1.0,
        },
      },
      'next_1_hours': {
        'summary': {'symbol_code': 'clearsky_day'},
        'details': {
          'precipitation_amount': 0.0,
          'probability_of_precipitation': 20.0,
        },
      },
    },
  };
}

Map<String, dynamic> _metNInstantOnlyHour(String time) {
  return {
    'time': time,
    'data': <String, dynamic>{
      'instant': <String, dynamic>{
        'details': <String, dynamic>{
          'air_temperature': 12.0,
          'wind_speed': 5.0,
          'wind_from_direction': 180.0,
          'ultraviolet_index_clear_sky': 1.0,
          'relative_humidity': 60.0,
        },
      },
    },
  };
}

void main() {
  test('converts Met.no UTC timestamps to the forecast location timezone', () {
    final hour = met_norway.metNWeatherHourFromJson(
      _metNHour('2026-01-15T12:00:00Z'),
      28.6139,
      77.2090,
    );

    expect(hour.time.year, 2026);
    expect(hour.time.month, 1);
    expect(hour.time.day, 15);
    expect(hour.time.hour, 17);
    expect(hour.time.minute, 30);
  });

  test('keeps Met.no hours usable when next forecast summary is missing', () {
    final hour = met_norway.metNWeatherHourFromJson(
      _metNInstantOnlyHour('2026-01-15T12:00:00Z'),
      40.7128,
      -74.0060,
    );

    expect(hour.condition, 'Clear Sky');
    expect(hour.precipMm, 0);
    expect(hour.precipProb, isNull);
  });

  test('uses longer Met.no forecast blocks when next 1 hour is missing', () {
    final item = _metNInstantOnlyHour('2026-01-15T12:00:00Z');
    item['data']['next_12_hours'] = {
      'summary': {'symbol_code': 'rain'},
      'details': {
        'precipitation_amount': 2.5,
        'probability_of_precipitation': 70,
      },
    };

    final hour = met_norway.metNWeatherHourFromJson(
      item,
      40.7128,
      -74.0060,
    );

    expect(hour.condition, 'Rain');
    expect(hour.precipMm, 2.5);
    expect(hour.precipProb, 70);
  });
}
