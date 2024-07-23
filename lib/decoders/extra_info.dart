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
import 'package:flutter/material.dart';
import 'package:overmorrow/decoders/decode_OM.dart';
import 'package:palette_generator/palette_generator.dart';

import '../api_key.dart';
import '../caching.dart';

import '../ui_helper.dart';
import '../weather_refact.dart';
import 'decode_wapi.dart';

Future<Image> getUnsplashImage(String _text, String real_loc) async {

  String text_query = textToUnsplashText[_text]!;

  //String addon = wapi_body["current"]["is_day"] == 1 ? 'daytime' : 'nighttime';

  final params2 = {
    'client_id': access_key,
    'query' : "$text_query, $real_loc",
    'content_filter' : 'high',
    'count': '3',
    //'collections' : '893395, 1319040, 583204, 11649432, 162468, 1492135',
  };

  final url2 = Uri.https('api.unsplash.com', 'photos/random', params2);

  var file2 = await cacheManager2.getSingleFile(url2.toString(), key: "$real_loc $text_query ")
      .timeout(const Duration(seconds: 6));

  var response2 = await file2.readAsString();

  var unsplash_body = jsonDecode(response2);

  var rng = Random();

  String image_path = unsplash_body[rng.nextInt(3)]["urls"]["regular"];

  print(image_path);

  return Image(image: CachedNetworkImageProvider(image_path), fit: BoxFit.cover,);
}

Future<dynamic> getImageColors(Image Uimage, color_mode) async {
  final ColorScheme palette = await _materialPalette(Uimage, color_mode);
  final PaletteGenerator pali = await _generatorPalette(Uimage);

  final List<Color> dominant = pali.colors.toList();

  Color startcolor = palette.primaryFixedDim;

  Color bestcolor = palette.primaryFixedDim;
  int bestDif = difFromBackColors(bestcolor, dominant);

  if (bestDif < 300) {
    for (int i = 1; i < 4; i++) {
      //LIGHT
      Color newcolor = lighten2(startcolor, i / 20);
      int newdif = difFromBackColors(newcolor, dominant);
      if (newdif > bestDif && newdif < 400) {
        bestDif = newdif;
        bestcolor = newcolor;
      }

      //DARK
      newcolor = darken2(startcolor, i / 20);
      newdif = difFromBackColors(newcolor, dominant);
      if (newdif > bestDif && newdif < 400) {
        bestDif = newdif;
        bestcolor = newcolor;
      }
    }
  }

  Color desc_color = palette.surface;
  int desc_dif = difFromBackColors(desc_color, dominant);

  print(("desc_dif", desc_dif));

  if (desc_dif < 200) {
    desc_color = bestcolor;
  }

  List<Color> gradientColors = getGradientColors(palette.primaryFixedDim, palette.error, 10);

  return [palette, bestcolor, desc_color, gradientColors, dominant];
}

List<Color> getGradientColors(Color color1, Color color2, int number) {
  int r = color1.red; int g = color1.green; int b = color1.blue;
  int dif_r = (color2.red - color1.red) ~/ number;
  int dif_g = (color2.green - color1.green) ~/ number;
  int dif_b = (color2.blue - color1.blue) ~/ number;

  List<Color> colors = [];

  for (int i = 0; i < number; i++) {
    r += dif_r; b += dif_b; g += dif_g;
    colors.add(Color.fromARGB(255, r, g, b));
  }

  return colors;
}

int difFromBackColors(Color frontColor, List<Color> backcolors) {
  int smallest = 2000;
  for (int i = 0; i < backcolors.length; i++) {
    smallest = min(smallest, difBetweenTwoColors(frontColor, backcolors[i]));
  }
  return smallest;
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

Future<PaletteGenerator> _generatorPalette(Image imageWidget) async {
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
    maximumColorCount: 3
  );

  imageProvider.resolve(const ImageConfiguration()).removeListener(listener);

  return _paletteGenerator;
}


Future<ColorScheme> _materialPalette(Image imageWidget, theme) async {
  final ImageProvider imageProvider = imageWidget.image;

  return ColorScheme.fromImageProvider(
    provider: imageProvider,
    brightness: theme == 'light' ? Brightness.light : Brightness.dark,
    dynamicSchemeVariant: theme == 'original' || theme == 'monochrome' ? DynamicSchemeVariant.fruitSalad :
    DynamicSchemeVariant.tonalSpot,
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
  final String provider;
  final String real_loc;

  final double lat;
  final double lng;

  final updatedTime;

  final days;
  final current;
  final aqi;
  final sunstatus;
  final radar;
  final minutely_15_precip;

  final fetch_datetime;

  final image;
  final localtime;

  final palette;
  final colorpop;
  final desc_color;

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
    required this.image,
    required this.localtime,

    required this.minutely_15_precip,

    required this.palette,
    required this.colorpop,
    required this.desc_color,
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