import 'package:flutter_test/flutter_test.dart';
import 'package:overmorrow/services/timezone_service.dart';

void expectLocalFields(
  DateTime time, {
  required int year,
  required int month,
  required int day,
  required int hour,
  int minute = 0,
}) {
  expect(time.isUtc, isFalse);
  expect(time.year, year);
  expect(time.month, month);
  expect(time.day, day);
  expect(time.hour, hour);
  expect(time.minute, minute);
}

void main() {
  test('converts Paris UTC time with summer DST offset', () {
    final localTime = TimezoneService.localDateTimeFromUtc(
      48.8566,
      2.3522,
      DateTime.utc(2026, 7, 1, 12),
    );

    expectLocalFields(localTime, year: 2026, month: 7, day: 1, hour: 14);
  });

  test('converts New York UTC time with winter standard offset', () {
    final localTime = TimezoneService.localDateTimeFromUtc(
      40.7128,
      -74.0060,
      DateTime.utc(2026, 1, 15, 12),
    );

    expectLocalFields(localTime, year: 2026, month: 1, day: 15, hour: 7);
  });

  test('converts Kolkata UTC time with fractional offset', () {
    final localTime = TimezoneService.localDateTimeFromUtc(
      22.5726,
      88.3639,
      DateTime.utc(2026, 1, 15, 12),
    );

    expectLocalFields(localTime,
        year: 2026, month: 1, day: 15, hour: 17, minute: 30);
  });

  test('uses longitude approximation fallback with clamped offsets', () {
    final localTime = TimezoneService.approximateLocalDateTimeFromUtc(
      30,
      DateTime.utc(2026, 1, 1, 23, 30),
    );

    expectLocalFields(localTime,
        year: 2026, month: 1, day: 2, hour: 1, minute: 30);
    expect(TimezoneService.approximateOffsetHours(240), 14);
    expect(TimezoneService.approximateOffsetHours(-240), -12);
  });
}
