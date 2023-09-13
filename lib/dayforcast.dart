import 'dart:ui';

import 'weather_refact.dart' as weather_refactor;

String iconCorrection(name) {
  String p = weather_refactor.weatherIconMap[name] ?? "clear_night.png";
  return p;
}

String textCorrection(name) {
  String p = weather_refactor.weatherTextMap[name] ?? "clear_night";
  return p;
}

Color getDaysColor(date, night) {
  final splitted = date.split('-');
  final hihi = DateTime.utc(int.parse(splitted[0]),
      int.parse(splitted[1]), int.parse(splitted[2]));
  final dayIndex = (hihi.weekday * 2) - night;
  Color p =
      weather_refactor.dayColorMap[dayIndex] ?? const Color(0xff000000);
  return p;
}

class Day {
  final String date;
  final String text;
  final String icon;
  final Color color;

  const Day({
    required this.date,
    required this.text,
    required this.icon,
    required this.color,
  });

  static Day fromJson(item, night) => Day(
      date: item['date'],
      //text: item["day"]["condition"]["text"],
      //icon: "http:" + item["day"]['condition']['icon'],
      text: textCorrection(
        item["day"]["condition"]["text"],
      ),
      icon: iconCorrection(
        item["day"]["condition"]["text"],
      ),
      color: getDaysColor(item['date'], night),
  );
}
