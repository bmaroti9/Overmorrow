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
import 'dart:math';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:palette_generator/palette_generator.dart';

import '../ui_helper.dart';

int getColorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return int.parse(hexColor, radix: 16);
}

double difFromBackColors(Color front, List<Color> backs) {
  double worst = double.infinity;
  double l1 = front.computeLuminance();
  for (var b in backs) {
    final l2 = b.computeLuminance();
    final lighter = max(l1, l2), darker = min(l1, l2);
    worst = min(worst, (lighter + 0.05) / (darker + 0.05));
  }
  return worst;
}

class ImageColorList {
  final List<Color> imageColors; //a list of colors for the whole image
  final List<Color> regionColors; //a list of colors for the region where the text will appear

  const ImageColorList({
    required this.imageColors,
    required this.regionColors
  });

  static Future<ImageColorList> getImageColorList(Image imageWidget) async {
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

    PaletteGenerator regionColors = await PaletteGenerator.fromImage(
      imageInfo.image,
      region: region,
      maximumColorCount: 4,
      filters: [],
    );
    PaletteGenerator imageColors = await PaletteGenerator.fromImage(
      imageInfo.image,
      maximumColorCount: 3,
      filters: [],
    );

    imageProvider.resolve(const ImageConfiguration()).removeListener(listener);

    return ImageColorList(
      imageColors: imageColors.colors.toList(),
      regionColors: regionColors.colors.toList()
    );
  }
}

class ColorPalette {
  final ColorScheme palette;
  final Color colorPop; //The color that is applied to the temperature display
  final Color descColor; //the color that is applied to the description under the temperature

  //used for debugging to see what colors the palette generator sees
  final List<Color> imageColors;
  final List<Color> regionColors;

  const ColorPalette({
    required this.palette,
    required this.colorPop,
    required this.descColor,
    required this.imageColors,
    required this.regionColors,
  });


  //make sure the temperature and description text remain readable
  static List<Color> checkTextContrast(List<Color> regionColors, ColorScheme palette) {

    //the intended look is temperature with primaryContainer and description with surface
    //though that can be adjusted to help contrast

    double surfaceDif = difFromBackColors(palette.surface, regionColors);
    //if the desc can keep the surface color or has to adapt to help contrast
    bool descUnique = surfaceDif >= 1.9;

    double dif = difFromBackColors(palette.primaryFixedDim, regionColors);
    if (dif >= 1.9) {
      return [palette.primaryFixedDim, descUnique ? palette.surface : palette.primaryFixedDim];
    }

    print(("dif surf", surfaceDif));
    if (surfaceDif >= 1.9) {
      return [palette.surface, palette.surface];
    }

    dif = difFromBackColors(palette.primary, regionColors);
    if (dif >= 1.9) {
      return [palette.primary, descUnique ? palette.surface : palette.primary];
    }

    //at this point neither of the predefined colors have enough contrast
    //loop through all brightnesses to see which works best

    Color newColor;
    Color bestColor = Colors.blue;
    double bestDif = -1;
    for (int i = 1; i < 5; i++) {
      //LIGHT
      newColor = lighten(palette.primaryContainer, i / 4);
      dif = difFromBackColors(newColor, regionColors);
      if (dif > bestDif) {
        if (dif >= 1.9) { //try to keep it close as possible to the palette while still readable
          return [newColor, newColor];
        }
        bestDif = dif;
        bestColor = newColor;
      }

      //DARK
      newColor = darken(palette.primaryContainer, i / 4);
      dif = difFromBackColors(newColor, regionColors);
      if (dif > bestDif) {
        if (dif >= 1.9) { //try to keep it close as possible to the palette while still readable
          return [newColor, newColor];
        }
        bestDif = dif;
        bestColor = newColor;
      }
    }

    return [bestColor, bestColor];
  }

  static Future<ColorPalette> getColorPalette(Image image, String theme, settings) async {

    ImageColorList colorList = await ImageColorList.getImageColorList(image);
    List<Color> regionColors = colorList.regionColors;
    List<Color> imageColors = colorList.imageColors;

    if (theme == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      theme= brightness == Brightness.dark ? "dark" : "light";
    }

    ColorScheme palette;

    if (settings["Color source"] == "wallpaper") {
      palette = await getWallpaperPalette(theme);
    }
    else if (settings["Color source"] == "custom") {
      palette = getCustomColorPalette(theme, settings);
    }
    else {
      palette = getImagePalette(theme, regionColors);
    }

    List<Color> textColors = checkTextContrast(regionColors, palette);

    return ColorPalette(
      palette: palette,
      colorPop: textColors[0],
      descColor: textColors[1],
      regionColors: regionColors,
      imageColors: imageColors,
    );
  }

  static ColorScheme getImagePalette(String theme, regionColors) {

    Color seedColor = Colors.blue;
    int bestValue = -10000;

    //try to reduce blue palettes because they are too common
    for (int i = 0; i < regionColors.length; i++) {
      double v = regionColors[i].r * 1 + regionColors[i].g * 1 - regionColors[i].b * 5.0;
      if (v > bestValue) {
        bestValue = v.round();
        seedColor = regionColors[i];
      }
    }

    if (theme == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      theme= brightness == Brightness.dark ? "dark" : "light";
    }

    //generate color palette with that seedColor
    ColorScheme palette = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: theme == 'light' ? Brightness.light : Brightness.dark
    );

    return palette;

  }

  static Future<ColorScheme> getWallpaperPalette(String theme) async {
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

  static ColorScheme getCustomColorPalette(String theme, settings) {
    Color mainColor = Color(getColorFromHex(settings["Custom color"]));

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

}