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

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:overmorrow/decoders/decode_mn.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:palette_generator/palette_generator.dart';

import '../api_key.dart';
import '../caching.dart';

import '../ui_helper.dart';
import '../weather_refact.dart';
import 'decode_wapi.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

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
  String placeName = shouldUsePlaceName[_text]! ? " $loc" : "";

  //print(("textquery", "$text_query, $loc", _text, text_query + placeName));

  final params2 = {
    'client_id': access_key,
    'query' : text_query + placeName,
    'content_filter' : 'high',
    'count': '6',
    //'collections' : '893395, 583204, 11649432, 162468, 1492135, 42478673, 8253647, 461360'
    //'collections' : '893395, 162468, 461360'
  };

  final url2 = Uri.https('api.unsplash.com', 'photos/random', params2);

  //await cacheManager2.removeFile("$text_query $loc");

  //var file2 = await cacheManager2.getSingleFile(url2.toString(), key: "$text_query $loc")
  //    .timeout(const Duration(seconds: 6));

  var file2 = await XCustomCacheManager.fetchData(url2.toString(), "$text_query $loc unsplash");

  var response2 = await file2[0].readAsString();

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
    //var desc2 = unsplash_body[i]["links"]["html"] ?? " ";
    var desc3 = unsplash_body[i]["alt_description"] ?? " ";

    String desc = desc1.toLowerCase() + " " + desc3.toLowerCase();
    desc = " ${desc.replaceAll("-", " ")} ";
    List<String> keys2 = textToUnsplashText.keys.toList();
    for (int x = 0; x < textToUnsplashText.length; x ++) {
      for (int y = 0; y < textToUnsplashText[keys2[x]]!.length; y ++) {
        String lookFor = textToUnsplashText[keys2[x]]![y];
        int reward = keys2[x] == _text ? -3000 : 2000;
        if (textToUnsplashText[_text]!.contains(lookFor)) {
          if (reward == 2000) {
            reward = 0;
          }
        }
        if (desc.contains(lookFor)) {
          //print(("punished1", textToUnsplashText[keys2[x]]![y], reward, lookFor, textToUnsplashText[_text]));
          unaccuracy += reward; // i had to reverse it
        }
      }
    }

    for (int x = 0; x < textFilter.length; x ++) {
      if (desc.contains(keys1[x])) {
        //print(("punished2", keys1[x], -textFilter[keys1[x]]!));
        unaccuracy -= textFilter[keys1[x]]!; // i had to reverse it
      }
    }

    double ratings = unsplash_body[i]["likes"] * 0.02 ?? 0;
    ratings += unsplash_body[i]["downloads"] * 0.01 ?? 0;
    //print(("ratings", ratings));

    unaccuracy -= min(ratings, 2000);

    //print((i, unaccuracy.toStringAsFixed(6), (desc1 ?? "null").trim() + ", " +  desc2, unsplash_body[i]["likes"], unsplash_body[i]["downloads"]));
    if (unaccuracy < best) {
      index = i;
      best = unaccuracy;
    }
  }

  String image_path = unsplash_body[index]["urls"]["regular"];
  //print(index);
  //print(unsplash_body[index]["links"]["html"]);

  final String userLink = (unsplash_body[index]["user"]["links"]["html"]) ?? "";

  //i don't want emojis because they ruin the one color aspect of the app
  String username = unsplash_body[index]["user"]["name"] ?? "";
  final RegExp regExp = RegExp(r'[\u2700-\u27bf]|(?:\ud83c[\udde6-\uddff]){2}|[\ud800-\udbff][\udc00-\udfff]|[\u0023-\u0039]\ufe0f?\u20e3|\u3299|\u3297|\u303d|\u3030|\u24c2|\ud83c[\udd70-\udd71]|\ud83c[\udd7e-\udd7f]|\ud83c\udd8e|\ud83c[\udd91-\udd9a]|\ud83c[\udde6-\uddff]|\ud83c[\ude01-\ude02]|\ud83c\ude1a|\ud83c\ude2f|\ud83c[\ude32-\ude3a]|\ud83c[\ude50-\ude51]|\u203c|\u2049|[\u25aa-\u25ab]|\u25b6|\u25c0|[\u25fb-\u25fe]|\u00a9|\u00ae|\u2122|\u2139|\ud83c\udc04|[\u2600-\u26FF]|\u2b05|\u2b06|\u2b07|\u2b1b|\u2b1c|\u2b50|\u2b55|\u231a|\u231b|\u2328|\u23cf|[\u23e9-\u23f3]|[\u23f8-\u23fa]|\ud83c\udccf|\u2934|\u2935|[\u2190-\u21ff]');
  username = username.replaceAll(regExp, "_");

  final String photoLink = unsplash_body[index]["links"]["html"] ?? "";

  //final Color color = HexColor(unsplash_body[index]["color"]);

  print(unsplash_body[index]["color"]);

  //print((username, userLink));

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

  if (theme == "auto") {
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    theme= brightness == Brightness.dark ? "dark" : "light";
  }

  final ColorScheme palette = ColorScheme.fromSeed(
    seedColor: mainColor,
    brightness: theme == 'light' ? Brightness.light : Brightness.dark,
    dynamicSchemeVariant: theme == 'original' || theme == 'mono' ? DynamicSchemeVariant.tonalSpot :
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
  //print(("base", base));

  if (bestDif <= base + 120) {
    for (int i = 1; i < 5; i++) {
      //LIGHT
      Color newcolor = lighten(startcolor, i / 4);
      int newdif = difFromBackColors(newcolor, dominant);
      if (newdif > bestDif && newdif < base + 200) {
        bestDif = newdif;
        bestcolor = newcolor;
      }

      //DARK
      newcolor = darken(startcolor, i / 4);
      newdif = difFromBackColors(newcolor, dominant);
      if (newdif > bestDif && newdif < base + 200) {
        bestDif = newdif;
        bestcolor = newcolor;
      }
    }
  }

  Color desc_color = used_colors[0];
  int desc_dif = difFromBackColors(desc_color, dominant);

  //print(("diffs", bestDif, desc_dif));

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
  return (diff_sum / max((backcolors.length * (backcolors.length - 1)), 1)).round();
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

  const int desiredSquare = 400; //approximation because the top half image cropped is almost a square

  final double cropX = desiredSquare / imageWidth;
  final double cropY = desiredSquare / imageHeight;

  final double cropAbsolute = max(cropY, cropX);

  final double centerX = imageWidth / 2;
  final double centerY = imageHeight / 2;

  final newLeft = centerX - ((desiredSquare / 2) / cropAbsolute);
  final newTop = centerY - ((desiredSquare / 2) / cropAbsolute);

  const double regionWidth = 50;
  const double regionHeight = 50;
  final Rect region = Rect.fromLTWH(
    newLeft + (50 / cropAbsolute),
    newTop + (300 / cropAbsolute),
    (regionWidth / cropAbsolute),
    (regionHeight / cropAbsolute),
  );

  PaletteGenerator _paletteGenerator = await PaletteGenerator.fromImage(
    imageInfo.image,
    region: region,
    maximumColorCount: 4,
    filters: [],
  );
  PaletteGenerator _paletteGenerator2 = await PaletteGenerator.fromImage(
      imageInfo.image,
      maximumColorCount: 3,
    filters: [],
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
  if (theme == "auto") {
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    theme= brightness == Brightness.dark ? "dark" : "light";
  }

  return ColorScheme.fromSeed(
    seedColor: color,
    brightness: theme == 'light' ? Brightness.light : Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
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
  final bool isonline;

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
    required this.isonline,
    required this.updatedTime,
    required this.localtime,

    required this.minutely_15_precip,
  });

  static Future<WeatherData> getFullData(settings, placeName, real_loc, latlong, provider, localizations) async {

    List<String> split = latlong.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    if (provider == 'weatherapi.com') {
      return WapiGetWeatherData(lat, lng, real_loc, settings, placeName, localizations);
    }
    else if (provider == "met norway"){
      return MetNGetWeatherData(lat, lng, real_loc, settings, placeName, localizations);
    }
    else {
      return OMGetWeatherData(lat, lng, real_loc, settings, placeName, localizations);
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

  //var file = await cacheManager2.getSingleFile(url.toString());
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

  for (var x in future) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(x["time"] * 1000);
    images.add(host + x["path"]);
    times.add("${time.hour}h ${time.minute}m");
  }

  return RainviewerRadar.fromJson(images, times);
  }
}

List<String> assetImageCredit(String name){
  return assetPhotoCredits[name] ?? ["", "", ""];
}