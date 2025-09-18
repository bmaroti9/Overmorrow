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
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

int getColorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return int.parse(hexColor, radix: 16);
}

double difFromBackColor(Color front, Color back) {
  double l1 = front.computeLuminance();
  final l2 = back.computeLuminance();
  final lighter = max(l1, l2), darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
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

Future<ui.Image> getUiImageFromProvider(ImageProvider imageProvider) async {
  final Completer<ui.Image> completer = Completer<ui.Image>();
  final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
  late final ImageStreamListener listener; // Declare the listener with `late`

  listener = ImageStreamListener(
        (ImageInfo imageInfo, bool synchronousCall) {
      completer.complete(imageInfo.image);
      stream.removeListener(listener); // Remove the listener to prevent future calls
    },
    // Add an error listener to handle loading failures
    onError: (Object exception, StackTrace? stackTrace) {
      completer.completeError(exception, stackTrace);
      stream.removeListener(listener);
    },
  );

  stream.addListener(listener);
  return completer.future;
}

Future<Color> getBottomLeftColor(ImageProvider imageProvider) async {
  const widthFactor = 0.3;
  const heightFactor = 0.7;

  final ui.Image image = await getUiImageFromProvider(imageProvider);

  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  if (byteData != null) {

    int r = 0;
    int g = 0;
    int b = 0;
    int count = 0;

    for (int y = (image.height * heightFactor).round(); y < image.height; y++) {
      for (int x = 0; x < (image.width * widthFactor).round(); x++) {
        final int byteOffset = (y * image.width + x) * 4;

        r += byteData.getUint8(byteOffset);
        g += byteData.getUint8(byteOffset + 1);
        b += byteData.getUint8(byteOffset + 2);
        count += 1;
      }
    }

    return Color.fromARGB(255, (r / count).round(), (g / count).round(), (b / count).round());
  }
  return Colors.black;
}

class ColorsOnImage {
  final Color colorPop; //The color that is applied to the temperature display
  final Color descColor; //the color that is applied to the description under the temperature
  final Color regionColor;

  static const minimumContrast = 1.7;

  const ColorsOnImage({
    required this.colorPop,
    required this.descColor,
    required this.regionColor,
  });

  static ColorsOnImage getColorsOnImage(ColorScheme palette, Color backColor) {

    //the intended look is temperature with tertiaryFixedDim and description with surface
    //though that can be adjusted to help contrast

    double surfaceDif = difFromBackColor(palette.surface, backColor);
    //if the desc can keep the surface color or has to adapt to help contrast
    bool descUnique = surfaceDif >= minimumContrast;

    //predefined list of colors in order that still match the color scheme
    final colorList = [palette.tertiaryFixedDim, palette.primaryFixedDim, palette.surface,
      palette.secondaryContainer, palette.tertiary, palette.onSurface];

    Color bestColor = Colors.black;
    int bestDif = 0;

    for (int i = 0; i < colorList.length; i++) {
      final Color color = colorList[i];
      final double dif = difFromBackColor(color, backColor);
      if (dif >= minimumContrast) {
        return ColorsOnImage(
          colorPop: color,
          descColor: descUnique ? palette.surface : color,
          regionColor: backColor
        );
      }
      if (dif > bestDif) {
        bestColor = color;
      }
    }

    //none of them were "good enough" so just return the best one

    return ColorsOnImage(
      colorPop: bestColor,
      descColor: bestColor,
      regionColor: backColor
    );
  }
}

