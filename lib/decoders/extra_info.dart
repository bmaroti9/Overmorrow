/*
Copyright (C) <2024>  <Balint Maroti>

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

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:palette_generator/palette_generator.dart';

import '../api_key.dart';
import '../caching.dart';

import '../ui_helper.dart';
import '../weather_refact.dart';
import 'decode_wapi.dart';

Future<List<dynamic>> getUnsplashImage(String _text, String real_loc, double lat, double lng) async {

  List<String> keys1 = textFilter.keys.toList();
  //this is all to make sure that none
  // of the banned words get somehow into the search query
  String loc = real_loc;
  for (int i = 0; i < keys1.length; i++) {
    if (loc.contains(keys1[i])) {
      loc = "";
    }
  }

  String text_query = textToUnsplashText[_text]![0];

  final params2 = {
    'client_id': access_key,
    'query' : "$text_query, $loc",
    'content_filter' : 'high',
    'count': '6',
    //'collections' : '893395, 583204, 11649432, 162468, 1492135, 42478673, 8253647, 461360'
    //'collections' : '893395, 162468, 461360'
  };

  final url2 = Uri.https('api.unsplash.com', 'photos/random', params2);

  var file2 = await cacheManager2.getSingleFile(url2.toString(), key: "$real_loc $text_query")
      .timeout(const Duration(seconds: 6));

  var response2 = await file2.readAsString();

  var unsplash_body = jsonDecode(response2);

  int index = 0;
  double best = 99999999999;

  for (int i = 0; i < unsplash_body.length; i++) {
    double lat_dif = pow((lat - (unsplash_body[i]["location"]["position"]["latitude"] ?? 9999)).abs(), 2) * 1.0;
    double lng_dif = pow((lng - (unsplash_body[i]["location"]["position"]["longitude"] ?? 9999)).abs(), 2) * 1.0;
    double unaccuracy = min(lat_dif + lng_dif, 100) * 20;

    if (unsplash_body[i]["location"]["position"]["city"] == real_loc) {
      unaccuracy -= 1000;
    }

    var desc1 = unsplash_body[i]["description"] ?? " ";
    var desc2 = unsplash_body[i]["links"]["html"];

    var desc = desc1.toLowerCase() + " " +  desc2.toLowerCase();
    List<String> keys2 = textToUnsplashText.keys.toList();
    for (int x = 0; x < textToUnsplashText.length; x ++) {
      for (int y = 0; y < textToUnsplashText[keys2[x]]!.length; y ++) {
        int reward = keys2[x] == _text ? -3000 : 1000;
        if (textToUnsplashText[_text]!.contains(textToUnsplashText[keys2[x]]![y])) {
          if (reward == 1000) {
            reward = 0;
          }
        }
        if (desc.contains(textToUnsplashText[keys2[x]]![y])) {
          print(("punished1", textToUnsplashText[keys2[x]]![y], reward));
          unaccuracy += reward; // i had to reverse it
        }
      }
    }

    for (int x = 0; x < textFilter.length; x ++) {
      if (desc.contains(keys1[x])) {
        print(("punished2", keys1[x], -textFilter[keys1[x]]!));
        unaccuracy -= textFilter[keys1[x]]!; // i had to reverse it
      }
    }

    if (desc.contains(real_loc.toLowerCase())) {
      unaccuracy -= 3000;
    }

    double ratings = unsplash_body[i]["likes"] * 0.02 ?? 0;
    ratings += unsplash_body[i]["downloads"] * 0.01 ?? 0;
    print(("ratings", ratings));

    unaccuracy -= min(ratings, 4000);

    print((i, unaccuracy.toStringAsFixed(6), (desc1 ?? "null").trim() + ", " +  desc2, unsplash_body[i]["likes"], unsplash_body[i]["downloads"]));
    if (unaccuracy < best) {
      index = i;
      best = unaccuracy;
    }
  }

  String image_path = unsplash_body[index]["urls"]["regular"];
  print(index);
  print(unsplash_body[index]["links"]["html"]);

  final String userLink = unsplash_body[index]["user"]["links"]["html"] ?? "";
  final String username = unsplash_body[index]["user"]["name"] ?? "";
  final String photoLink = unsplash_body[index]["links"]["html"] ?? "";

  print((username, userLink));

  return [Image(image: CachedNetworkImageProvider(image_path), fit: BoxFit.cover,
    width: double.infinity, height: double.infinity,), username, userLink, photoLink];
}

Future<ColorScheme> MaterialYouColor(String theme) async {
  final corePalette = await DynamicColorPlugin.getCorePalette();

  Color? mainColor;
  if (corePalette != null) {
    mainColor = corePalette.toColorScheme().primary;
  } else {
    mainColor = Colors.blue;
  }
  final ColorScheme palette = ColorScheme.fromSeed(
    seedColor: mainColor,
    brightness: theme == 'light' ? Brightness.light : Brightness.dark,
    dynamicSchemeVariant: theme == 'original' || theme == 'monochrome' ? DynamicSchemeVariant.tonalSpot :
    DynamicSchemeVariant.tonalSpot,
  );

  return palette;
}

Future<List<dynamic>> getImageColors(Image Uimage, color_mode, settings) async {

  final List<PaletteGenerator> genPalette = await _generatorPalette(Uimage);
  final PaletteGenerator pali = genPalette[0];
  final PaletteGenerator paliTotal = genPalette[1];

  ColorScheme palette;

  Color primeColor = Colors.amber;
  int bestValue = -10000;

  List<Color> paliColors = paliTotal.colors.toList();

  for (int i = 0; i < paliColors.length; i++) { //i am trying to reduce the number of blue palettes
                                                //because they are too common
    double v = paliColors[i].red * 1 + paliColors[i].green * 1 - paliColors[i].blue * 5.0;
    if (v > bestValue) {
      print(("better", i));
      bestValue = v.round();
      primeColor = paliColors[i];
    }
  }

  if (settings["Color source"] == "image") {
    palette = await _materialPalette(Uimage, color_mode, primeColor);
  }
  else {
    palette = await MaterialYouColor(color_mode);
  }

  final List<Color> used_colors = getNetworkColors([palette, BLACK, BLACK], settings);

  final List<Color> dominant = pali.colors.toList();
  Color startcolor = used_colors[2];

  Color bestcolor = startcolor;
  int bestDif = difFromBackColors(bestcolor, dominant);

  int base = (diffBetweenBackColors(dominant) * 0.7).round();
  print(("base", base));

  if (bestDif <= base + 120) {
    print("trying");
    for (int i = 1; i < 5; i++) {
      //LIGHT
      Color newcolor = lighten2(startcolor, i / 4);
      int newdif = difFromBackColors(newcolor, dominant);
      if (newdif > bestDif && newdif < base + 200) {
        bestDif = newdif;
        bestcolor = newcolor;
      }

      //DARK
      newcolor = darken2(startcolor, i / 4);
      newdif = difFromBackColors(newcolor, dominant);
      if (newdif > bestDif && newdif < base + 200) {
        bestDif = newdif;
        bestcolor = newcolor;
      }
    }
  }

  Color desc_color = used_colors[0];
  int desc_dif = difFromBackColors(desc_color, dominant);

  print(("diffs", bestDif, desc_dif));

  print(("desc_dif", desc_dif));

  if (desc_dif < base + 100) {
    desc_color = bestcolor;
  }

  return [[palette, bestcolor, desc_color], paliTotal.colors.toList()];
}

int difFromBackColors(Color frontColor, List<Color> backcolors) {
  int smallest = 2000;
  for (int i = 0; i < backcolors.length; i++) {
    smallest = min(smallest, difBetweenTwoColors(frontColor, backcolors[i]));
  }
  return smallest;
}

int diffBetweenBackColors(List<Color> backcolors) {
  int diff_sum = 0;
  for (int a = 0; a < backcolors.length; a ++) {
    for (int b = 0; b < backcolors.length; b ++) {
      if (a != b) {
        diff_sum += difBetweenTwoColors(backcolors[a], backcolors[b]);
      }
    }
  }
  return (diff_sum / (backcolors.length * (backcolors.length - 1))).round();
}

int difBetweenTwoColors(Color color1, Color color2) {
  int r = (color1.red - color2.red).abs();
  int g = (color1.green - color2.green).abs();
  int b = (color1.blue - color2.blue).abs();
  return r + g + b;
}

Color averageColor(List<Color> colors) {
  if (colors.length > 0) {
    int r = 0;
    int g = 0;
    int b = 0;
    for (int i = 0; i < colors.length; i++) {
      r += colors[i].red; g += colors[i].green; b += colors[i].blue;
    }
    r = r ~/ colors.length;
    g = g ~/ colors.length;
    b = b ~/ colors.length;
    return Color.fromARGB(255, r, g, b);
  }
  return Colors.grey;
}

Color BackColorCorrection(String text) {
  //return Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  return accentColors[text] ?? WHITE;
}

Future<List<PaletteGenerator>> _generatorPalette(Image imageWidget) async {
  final ImageProvider imageProvider = imageWidget.image;

  final Completer<ImageInfo> completer = Completer();
  final ImageStreamListener listener = ImageStreamListener((ImageInfo info, bool _) {
    if (!completer.isCompleted) {
      completer.complete(info);
    }
  });

  imageProvider.resolve(const ImageConfiguration()).addListener(listener);

  final ImageInfo imageInfo = await completer.future;
  final int imageHeight = imageInfo.image.height;
  final int imageWidth = imageInfo.image.height;

  final int desiredSquare = 400; //approximation because the top half image cropped is almost a square

  final double crop_x = desiredSquare / imageWidth;
  final double crop_y = desiredSquare / imageHeight;

  final double crop_absolute = max(crop_y, crop_x);

  final double center_x = imageWidth / 2;
  final double center_y = imageHeight / 2;

  final new_left = center_x - ((desiredSquare / 2) / crop_absolute);
  final new_top = center_y - ((desiredSquare / 2) / crop_absolute);

  final double regionWidth = 50;
  final double regionHeight = 50;
  final Rect region = Rect.fromLTWH(
    new_left + (50 / crop_absolute),
    new_top + (300 / crop_absolute),
    (regionWidth / crop_absolute),
    (regionHeight / crop_absolute),
  );

  PaletteGenerator _paletteGenerator = await PaletteGenerator.fromImage(
    imageInfo.image,
    region: region,
    maximumColorCount: 4
  );
  PaletteGenerator _paletteGenerator2 = await PaletteGenerator.fromImage(
      imageInfo.image,
      maximumColorCount: 5
  );

  imageProvider.resolve(const ImageConfiguration()).removeListener(listener);

  return [_paletteGenerator, _paletteGenerator2];
}

Future<ColorScheme> _materialPalette(Image imageWidget, theme, color) async {
  /*
  final ImageProvider imageProvider = imageWidget.image;
  return ColorScheme.fromImageProvider(
    provider: imageProvider,
    brightness: theme == 'light' ? Brightness.light : Brightness.dark,
    dynamicSchemeVariant: theme == 'light' || theme == 'dark' ? DynamicSchemeVariant.tonalSpot :
    DynamicSchemeVariant.tonalSpot,
  );
   */

  return ColorScheme.fromSeed(
    seedColor: color,
    brightness: theme == 'light' ? Brightness.light : Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot
  );
}

Color PrimaryColorCorrection(String text) {
  return textBackColor[text] ?? BLACK;
}

List<int> ColorPopCorrection(String text) {
  return colorPop[text] ?? [0, 0];
}

class WeatherData {
  final Map<String, String> settings;

  final String place;
  final String real_loc;
  final double lat;
  final double lng;

  final String provider;

  final updatedTime;
  final fetch_datetime;
  final localtime;

  final days;
  final current;
  final aqi;
  final sunstatus;
  final radar;
  final minutely_15_precip;

  WeatherData({
    required this.place,
    required this.settings,
    required this.provider,
    required this.real_loc,
    required this.lat,
    required this.lng,
    required this.sunstatus,
    required this.aqi,
    required this.radar,
    required this.days,
    required this.current,
    required this.fetch_datetime,
    required this.updatedTime,
    required this.localtime,

    required this.minutely_15_precip,
  });

  static Future<WeatherData> getFullData(settings, placeName, real_loc, latlong, provider) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    if (provider == 'weatherapi.com') {
      return WapiGetWeatherData(lat, lng, real_loc, settings, placeName);
    }
    else {
      return OMGetWeatherData(lat, lng, real_loc, settings, placeName);
    }
  }
}

class RainviewerRadar {
  final List<String> images;
  final List<String> times;

  const RainviewerRadar({
    required this.images,
    required this.times
  });

  static RainviewerRadar fromJson(images, times) => RainviewerRadar(
      images: images,
      times: times
  );

  static Future<RainviewerRadar> getData() async {
  const String url = 'https://api.rainviewer.com/public/weather-maps.json';

  var file = await cacheManager2.getSingleFile(url.toString());
  var response = await file.readAsString();
  final Map<String, dynamic> data = json.decode(response);

  final String host = data["host"];

  //int timenow = DateTime.now().toUtc().microsecond;

  List<String> images = [];
  List<String> times = [];

  final past = data["radar"]["past"];
  final future = data["radar"]["nowcast"];

  for (var x in past) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
    images.add(host + x["path"]);
    times.add("${time.hour}h ${time.minute}m");
  }

  for (var x in future) {
    //int dif = x["time"] * 1000 - timenow;
    DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
    images.add(host + x["path"]);
    times.add("${time.hour}h ${time.minute}m");
  }

  return RainviewerRadar.fromJson(images, times);
  }
}