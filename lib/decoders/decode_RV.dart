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

import 'dart:convert';

import '../caching.dart';

class RainviewerRadar {
  final List<String> images;
  final List<String> times;
  final int real_hour;
  final int starting_index;

  const RainviewerRadar({
    required this.images,
    required this.times,
    required this.real_hour,
    required this.starting_index,
  });

  static Future<RainviewerRadar> getData() async {
    const String url = 'https://api.rainviewer.com/public/weather-maps.json';

    var file = await XCustomCacheManager.fetchData(url.toString(), url.toString());
    var response = await file[0].readAsString();
    final Map<String, dynamic> data = json.decode(response);

    final String host = data["host"];

    List<String> images = [];
    List<String> times = [];

    final past = data["radar"]["past"];
    final future = data["radar"]["nowcast"];

    for (var x in past) {
      DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
      images.add(host + x["path"]);
      times.add("${time.hour}h ${time.minute}m");
    }

    int real_hour = int.parse(times[times.length - 1].split("h")[0]);
    int starting_index = times.length - 1;

    for (var x in future) {
      DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
      images.add(host + x["path"]);
      times.add("${time.hour}h ${time.minute}m");
    }

    return RainviewerRadar(images: images, times: times, real_hour: real_hour, starting_index: starting_index);
  }
}

