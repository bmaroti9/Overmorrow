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

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


const WHITE = Color(0xffFFFFFF);
const BLACK = Color(0xff000000);

double getFontSize(String set) {
  double x = Platform.isLinux ? 0.85 : 0.92;

  if (set == "small")  {
    x = 0.85 * x;
  }
  else if (set == "very small") {
    x = 0.75 * x;
  }
  else if (set == 'big') {
    x = 1.1 * x;
  }
  return x;
}

Widget comfortatext(String text, double size, settings,
    {Color color = WHITE, TextAlign align = TextAlign.left, weight = FontWeight.w400,
      decoration = TextDecoration.none, maxLines = 40}) {

  double x = getFontSize(settings["Font size"]);
  final baseStyle = GoogleFonts.outfit(
    color: color,
    fontSize: size * x * 1.1,
    fontWeight: weight,
    decoration: decoration,
    height: 1.05,
    decorationColor: color,
  );

  final styleWithFallback = baseStyle.copyWith(
    fontFamilyFallback: [
      'NotoSans',
    ],
  );

  return Text(
    text,
    style: styleWithFallback,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines,
    textAlign: align,
  );
}

bool estimateBrightnessForColor(Color color) {
  final double relativeLuminance = color.computeLuminance();

  const double kThreshold = 0.15;
  return (relativeLuminance + 0.05) * (relativeLuminance + 0.05) > kThreshold;
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}

Color darken2(Color c, [double amount = 0.1]) {
  assert(0 <= amount && amount <= 1);
  var f = 1 - amount;
  return Color.fromARGB(
      c.a.toInt(),
      (c.r * f).round(),
      (c.g  * f).round(),
      (c.b * f).round()
  );
}

Color lighten2(Color c, [double amount = 0.1]) {
  assert(0 <= amount && amount <= 1);
  return Color.fromARGB(
      c.a.toInt(),
      c.r.toInt() + ((255 - c.r) * amount).round(),
      c.g.toInt() + ((255 - c.g) * amount).round(),
      c.b.toInt() + ((255 - c.b) * amount).round()
  );
}

Color lightAccent(Color color, int intensity) {
  double x = intensity / (color.r + color.g + color.b);
  return Color.fromRGBO(sqrt(color.r * x).toInt(), sqrt(color.g * x).toInt(), sqrt(color.b* x).toInt(), 1);
}


Widget NewAqiDataPoints(String name, double value, var data, [double size = 15]) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      comfortatext(name, size, data.settings, color: data.current.primary,
      align: TextAlign.end, weight: FontWeight.w500),
      Padding(
        padding: const EdgeInsets.all(3.0),
        child: Container(
          width: 2.5,
          height: 2.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: data.current.primarySecond,
          ),
        ),
      ),
      comfortatext(value.toString(), size, data.settings, color: data.current.primarySecond,
          align: TextAlign.end, weight: FontWeight.w600),
    ],
  );
}

bool isUppercase(String str){
  return str == str.toUpperCase();
}

String generateAbbreviation(String countryName) {
  List<String> words = countryName.split(' ');

  if (words.length == 1) {
    return countryName;
  } else {
    String abbreviation = '';
    for (String word in words) {
      if (word.isNotEmpty && isUppercase(word[0])) {
        abbreviation += word[0];
      }
    }
    return abbreviation;
  }
}
