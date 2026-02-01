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


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overmorrow/decoders/weather_data.dart';

import '../weather_refact.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const androidDetails = AndroidNotificationDetails(
    'basic_channel',
    'Alerts',
    importance: Importance.max,
    priority: Priority.high,
    //icon: "@drawable/icon_info"
  );

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@drawable/weather_partly_cloudy');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showSimpleNotification() async {
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Hello World',
      'message',
      details,
    );
  }

  Future<void> showOngoingNotification(LightCurrentWeatherData data) async {

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'weather_ongoing',
      'Ongoing Weather',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      icon: weatherIconResMap[data.condition] ?? "@drawable/weather_partly_cloudy"
    );

    await _plugin.show(
      1,
      '${data.temp}° ${data.condition}',
      data.place,
      NotificationDetails(android: androidNotificationDetails,),
    );
  }

}