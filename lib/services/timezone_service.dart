/*
Copyright (C) <2026>  <Balint Maroti>

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

import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:timezone/data/latest_10y.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class TimezoneService {
  static bool _isInitialized = false;

  static DateTime getLocalTime(double lat, double lng, {DateTime? utcNow}) {
    return localDateTimeFromUtc(lat, lng, utcNow ?? DateTime.now().toUtc());
  }

  static DateTime localDateTimeFromUtc(
      double lat, double lng, DateTime utcTime) {
    _ensureInitialized();

    try {
      final timezoneName = tzmap.latLngToTimezoneString(lat, lng);
      final location = timezone.getLocation(timezoneName);
      final localTime = timezone.TZDateTime.from(utcTime.toUtc(), location);

      return _withoutTimezone(localTime);
    } catch (_) {
      return approximateLocalDateTimeFromUtc(lng, utcTime);
    }
  }

  static DateTime approximateLocalDateTimeFromUtc(
      double lng, DateTime utcTime) {
    final offsetHours = approximateOffsetHours(lng);
    final localTime = utcTime.toUtc().add(Duration(hours: offsetHours));

    return _withoutTimezone(localTime);
  }

  static int approximateOffsetHours(double lng) {
    return (lng / 15).round().clamp(-12, 14).toInt();
  }

  static void _ensureInitialized() {
    if (_isInitialized) {
      return;
    }

    timezone_data.initializeTimeZones();
    _isInitialized = true;
  }

  static DateTime _withoutTimezone(DateTime time) {
    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
  }
}
