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
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/search_screens.dart';

import 'package:shared_preferences/shared_preferences.dart';

const WHITE = Color(0xffFFFFFF);
const BLACK = Color(0xff000000);

double getFontSize(String set) {
  double x = Platform.isLinux ? 0.75 : 0.92;

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
  return Text(
    text,
    style: GoogleFonts.outfit(
      color: color,
      fontSize: size * x * 1.1,
      fontWeight: weight,
      decoration: decoration,
      height: 1.05,
      decorationColor: color,
    ),
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

Widget RainWidget(data, day, highlight, border) {
  List<dynamic> hours = day.hourly_for_precip;

  List<double> precip = [];

  //this is done because sometimes the provider doesn't return the past hours
  // of the day so i just extend it to 24
  if (hours.length < 24) {
    for (int i = 0; i < 24 - hours.length; i++) {
      precip.add(0);
    }
  }

  for (var i = 0; i < hours.length; i++) {
    double x = min(hours[i].precip, 10);
    precip.add(x);
  }

  return Padding(
    padding: const EdgeInsets.only(left: 8, right: 8, top: 15),
    child: Container(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 450),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        //color: data.current.containerLow,
        border: data.settings["Color mode"] == "dark" || data.settings["Color mode"] == "light"
            || data.settings["Color mode"] == "auto"
          ? Border.all(width: 2.6, color: border)
          : Border.all(width: 1.6, color: data.current.primaryLight)

      ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 17, left: 17),
              child: AspectRatio(
                aspectRatio: 2.2,
                child: MyChart(precip, data, highlight)
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 14),
                child: Visibility(
                  visible: data.settings["Time mode"] == "24 hour",
                  replacement: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        comfortatext("3am", 14,data. settings, color: data.current.outline),
                        comfortatext("9am", 14, data.settings, color: data.current.outline),
                        comfortatext("3pm", 14, data.settings, color: data.current.outline),
                        comfortatext("9pm", 14, data.settings, color: data.current.outline),
                      ]
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        comfortatext("3:00", 14, data.settings, color: data.current.outline),
                        comfortatext("9:00", 14, data.settings, color: data.current.outline),
                        comfortatext("15:00", 14, data.settings, color: data.current.outline),
                        comfortatext("21:00", 14, data.settings, color: data.current.outline),
                      ]
                  ),
                )
            )
          ],
        ),
    ),
  );
}

class MyChart extends StatelessWidget {
  final List<double> precip; // Sample data for the chart
  final data;
  final highlight;

  const MyChart(this.precip, this.data, this.highlight, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarChartPainter(precip, data, highlight),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> precip;
  final data;
  final highlight;

  BarChartPainter(this.precip, this.data, this.highlight);

  @override
  void paint(Canvas canvas, Size size) {

    Paint circle_paint = Paint()
      ..color = data.current.primaryLight
      ..style = PaintingStyle.fill;

    Paint circle_paint2 = Paint()
      ..color = highlight
      ..style = PaintingStyle.fill;

    int numberOfBars = precip.length;
    double totalWidth = size.width;
    double barWidth = totalWidth / numberOfBars;

    for (int i = 0; i < numberOfBars; i++) {
      double x = i * barWidth;

      int circles = 10;
      double y_dis = size.height / circles;
      double start = size.height - barWidth * 0.5;

      int smallerThan = (precip[i] * 2).round();

      if (smallerThan == 0 && precip[i] > 0) {
        smallerThan = 1;
      }

      for (int i = 1; i < 21; i++) {
        if (i <= smallerThan) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(x + barWidth * 0.5, start - 0.05), //this small offset is there
                // to remove the small line between the two half circles
              height: barWidth * 0.8,
              width: barWidth * 0.8,
            ),
            i % 2 == 0 ? pi : pi * 2,
            pi,
            false,
            circle_paint,
          );
        }
        else {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(x + barWidth * 0.5, start),
              height: barWidth * 0.8,
              width: barWidth * 0.8,
            ),
            i % 2 == 0 ? pi : pi * 2,
            pi,
            false,
            circle_paint2,
          );
          //canvas.drawCircle(Offset(x + barWidth * 0.5, start), barWidth * 0.4, circle_paint2);
        }

        start -= i % 2 == 1 ? 0 : y_dis;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
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

class MySearchParent extends StatefulWidget{
  final updateLocation;
  final ColorScheme palette;
  final place;
  final settings;
  final Image image;

  const MySearchParent({super.key, required this.updateLocation,
    required this.palette, required this.place, required this.settings, required this.image});

  @override
  _MySearchParentState createState() => _MySearchParentState(palette: palette,
  place: place,settings: settings, image: image);
}

class _MySearchParentState extends State<MySearchParent> {
  bool isEditing = false;

  final ColorScheme palette;
  final place;
  final settings;
  final Image image;

  _MySearchParentState({required this.palette, required this.place, required this.settings, required this.image});

  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }

  List<String> getFavorites(SharedPreferences? prefs){
    final ifnot = ["{\n        \"id\": 2651922,\n        \"name\": \"Nashville\",\n        \"region\": \"Tennessee\",\n        \"country\": \"United States of America\",\n        \"lat\": 36.17,\n        \"lon\": -86.78,\n        \"url\": \"nashville-tennessee-united-states-of-america\"\n    }"];
    final used = prefs?.getStringList('favorites') ?? ifnot;
    int n = 0;
    while (n < used.length){
      try {
        jsonDecode(used[n]);
        n += 1;
      } on FormatException {
        used.remove(used[n]);
      }
    }
    return used;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (BuildContext context,
          AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: ErrorWidget(snapshot.error as Object),
          );
        }
        List<String> favorites = getFavorites(snapshot.data);
        //return buildWholeThing(snapshot.data);
        return MySearchWidget(updateLocation: widget.updateLocation,
            palette: palette, favorites: favorites, prefs: snapshot.data,
        place: place, settings: settings, image: image);
      },
    );
  }
}

class MySearchWidget extends StatefulWidget{
  final ColorScheme palette;
  final place;
  final updateLocation;
  final favorites;
  final prefs;
  final settings;
  final Image image;

  const MySearchWidget({super.key, required this.palette, required this.updateLocation,
  required this.favorites, required this.prefs, required this.place, required this.settings,
  required this.image});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(palette: palette,
  updateLocation: updateLocation, beginFavorites: favorites,
      prefs: prefs, place: place, settings: settings, image: image);
}

class _MySearchWidgetState extends State<MySearchWidget> {
  //final FloatingSearchBarController _controller = FloatingSearchBarController();
  final ColorScheme palette;
  final place;
  final updateLocation;
  final prefs;
  final settings;
  final Image image;

  final List<String> beginFavorites;

  _MySearchWidgetState({required this.palette, required this.updateLocation,
        required this.beginFavorites, required this.prefs, required this.place,
  required this.settings, required this.image});

  final ValueNotifier<List<String>> recommend = ValueNotifier<List<String>>([]);
  ValueNotifier<List<String>> favorites = ValueNotifier<List<String>>([]);

  @override
  void initState() {
    super.initState();
    favorites = ValueNotifier<List<String>>(beginFavorites);
  }

  void updateFav(List<String> fav){
    prefs.setStringList('favorites', fav);
    setState(() {
      favorites.value = fav;
    });
  }

  void updateRec(List<String> rec) {
    setState(() {
      recommend.value = rec;
    });
  }

  @override
  Widget build(BuildContext context){
    return buildHihiSearch();
  }

  Widget buildHihiSearch() {
    return buildFloatingSearchBar();
  }

  Widget buildFloatingSearchBar() {

    return searchBar2(palette, recommend, updateLocation,
        updateFav, favorites, updateRec, place, context, settings, image);

  }
}