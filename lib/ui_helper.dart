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
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key.dart';
import 'caching.dart';

const WHITE = Color(0xffFFFFFF);
const BLACK = Color(0xff000000);

double getFontSize(String set) {
  double x = Platform.isLinux ? 0.75 : 0.95;

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
    {Color color = WHITE, TextAlign align = TextAlign.left, weight = FontWeight.w400}) {

  double x = getFontSize(settings["Font size"]);
  return Text(
  text,
  style: GoogleFonts.comfortaa(
    color: color,
    fontSize: size * x,
    fontWeight: weight,
  ),
  overflow: TextOverflow.ellipsis,
  maxLines: 3,
  textAlign: align,
);
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lightAccent(Color color, int intensity) {
  double x = intensity / (color.red + color.green + color.blue);
  print((x, (color.red * x).toInt(), (color.green * x).toInt(), (color.blue * x).toInt()));
  return Color.fromRGBO(sqrt(color.red * x).toInt(), sqrt(color.green * x).toInt(), sqrt(color.blue * x).toInt(), 1);
}

class DescriptionCircle extends StatelessWidget {

  final String text;
  final String undercaption;
  final String extra;
  final Color color;
  final double size;
  final settings;
  final bottom;

  const DescriptionCircle({super.key, required this.text,
      required this.undercaption, required this.color, required this.extra,
    required this.size, required this.settings, required this.bottom});

  @override
  Widget build(BuildContext context) {
    final double fontsize = size / 18;
    final double small_font = size / 25;
    final double width = size / 5;
    final double height = size / 5;
    return Container(
      //padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: height,
            width: width,
            child: Stack(
              children: [
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    border: Border.all(width: 2, color: color),
                    //color: WHITE,
                    //borderRadius: BorderRadius.circular(size * 0.09)
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        comfortatext(text, fontsize, settings, color: color, weight: FontWeight.w500),
                        Flexible(
                          child: comfortatext(extra, small_font, settings, color: color, weight: FontWeight.w500)
                        ),
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),
        Center(
          child: Container(
            padding: const EdgeInsets.only(top:5),
            width: width + 8,
            height: height * bottom,
            child: comfortatext(undercaption, small_font, settings, align: TextAlign.center, color: color, weight: FontWeight.w500)
          )
        )
      ]
      ),
    );
  }
}

Widget aqiDataPoints(String name, double value, var data) {
  return Align(
    alignment: Alignment.centerRight,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width;
        if (constraints.maxWidth > 300) {
          width = 200;
        }
        else {width = constraints.maxWidth;}

        return SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2, top: 2),
            child: Row(
              children: [
                comfortatext(name, 19, data.settings, color: data.current.textcolor,
                weight: FontWeight.w500),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.only(top:3,bottom: 3, left: 3, right: 3),
                  decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blueAccent)
                    color: data.current.textcolor,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                      value.toString(),
                      style: TextStyle(
                        color: data.current.backcolor
                      ),
                      textScaleFactor: getFontSize(data.settings["Font size"]) * 1.2
                  ),
                )
              ],
            ),
          )
        );
      }
    )
  );
}

Widget RainWidget(settings, day) {
  List<dynamic> hours = day.hourly_for_precip;

  List<double> data = [];

  for (var i = 0; i < hours.length; i+= 2) {
    double x = min(round((hours[i].precip + hours[i + 1].precip) * 4, decimals: 0) / 2, 10);
    data.add(x);
  }

  return Column(
    children: [
      Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 5, bottom: 5, top: 5),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(width: 1.2, color: WHITE)
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: MyChart(data),
                      )
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 165,
              width: 55,
              child: ListView.builder(
                  reverse: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    if (settings["Rain"] == 'in') {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10, right: 4, left: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            comfortatext((index * 0.2).toStringAsFixed(1), 17, settings),
                            comfortatext('in', 12, settings),
                          ],
                        ),
                      );
                    }
                    else {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10, right: 4, left: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            comfortatext((index * 5).toString(), 17, settings),
                            comfortatext('mm', 12, settings),
                          ],
                        ),
                      );
                    }
                  }
              ),
            )
          ]
      ),
      Padding(
          padding: const EdgeInsets.only(left: 33, top: 0, right: 70, bottom: 15),
          child: Visibility(
            visible: settings["Time mode"] == "24 hour",
            replacement: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3am", 14, settings),
                  comfortatext("9am", 14, settings),
                  comfortatext("3pm", 14, settings),
                  comfortatext("9pm", 14, settings),
                ]
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3:00", 14, settings),
                  comfortatext("9:00", 14, settings),
                  comfortatext("15:00", 14, settings),
                  comfortatext("21:00", 14, settings),
                ]
            ),
          )
      )
    ],
  );
}

class MyChart extends StatelessWidget {
  final List<double> data; // Sample data for the chart

  const MyChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarChartPainter(data),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..color = WHITE
      ..style = PaintingStyle.fill;

    double maxValue = 10;
    double scaleY = size.height / maxValue;

    int numberOfBars = data.length; // get rid of the extra data points
    double totalWidth = size.width; // Subtract padding
    double barWidth = totalWidth / numberOfBars;

    for (int i = 0; i < numberOfBars; i++) {
      double barHeight = data[i] * scaleY;
      double x = i * barWidth; // Add half of the remaining padding
      double y = size.height - barHeight;

      double topRadius = 6.0; // Adjust the radius for the desired rounding

      RRect roundedRect = RRect.fromLTRBR(
        x + barWidth * 0.1,
        y,
        x + barWidth * 0.9,
        size.height,
        Radius.circular(topRadius),
      );

      canvas.drawRRect(roundedRect, paint);
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

Future<List<String>> getRecommend(String query) async {

  if (query == '') {
    return [];
  }

  var params = {
    'key': wapi_Key,
    'q': query,
  };
  var url = Uri.http('api.weatherapi.com', 'v1/search.json', params);
  //var response = await http.post(url);

  var jsonbody = [];
  try {
    var file = await cacheManager.getSingleFile(url.toString(), headers: {'cache-control': 'private, max-age=120'});
    var response = await file.readAsString();
    jsonbody = jsonDecode(response);
  } on SocketException{
    return [];
  }

  //var jsonbody = jsonDecode(response.body);

  List<String> recomendations = [];
  for (var item in jsonbody) {
    //recomendations.add(item["name"] + "/" + item["region"] + ", " + generateAbbreviation(item["country"]));
    //recomendations.add(item["name"]);
    recomendations.add(json.encode(item));
  }

  return recomendations;
}
class MySearchParent extends StatefulWidget{
  final updateLocation;
  final color;
  final place;
  final controller;
  final settings;
  final real_loc;
  final secondColor;
  final textColor;

  const MySearchParent({super.key, required this.updateLocation,
    required this.color, required this.place, required this.controller, required this.settings,
    required this.real_loc, required this.secondColor, required this.textColor});

  @override
  _MySearchParentState createState() => _MySearchParentState(color: color,
  place: place, controller: controller, settings: settings, real_loc: real_loc,
      secondColor: secondColor, textColor: textColor);
}

class _MySearchParentState extends State<MySearchParent> {
  bool isEditing = false;

  final color;
  final place;
  final controller;
  final settings;
  final real_loc;
  final secondColor;
  final textColor;

  _MySearchParentState({required this.color, required this.place,
  required this.controller, required this.settings, required this.real_loc, required this.secondColor,
  required this.textColor});

  Future<SharedPreferences> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
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
      future: getPrefs(),
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
            color: color, favorites: favorites, prefs: snapshot.data,
        place: place, controller: controller, settings: settings, real_loc: real_loc,
        secondColor: secondColor, textColor: textColor,);
      },
    );
  }
}

class MySearchWidget extends StatefulWidget{
  final color;
  final place;
  final updateLocation;
  final favorites;
  final prefs;
  final controller;
  final settings;
  final real_loc;
  final secondColor;
  final textColor;

  const MySearchWidget({super.key, required this.color, required this.updateLocation,
  required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings, required this.real_loc,
    required this.secondColor, required this.textColor});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(color: color,
  updateLocation: updateLocation, favorites: favorites,
      prefs: prefs, place: place, controller: controller, settings: settings, real_loc: real_loc,
  secondColor: secondColor, textColor: textColor);
}

class _MySearchWidgetState extends State<MySearchWidget> {
  //final FloatingSearchBarController _controller = FloatingSearchBarController();
  final controller;
  final color;
  final place;
  final updateLocation;
  final prefs;
  final settings;
  final real_loc;
  final secondColor;
  final textColor;

  List<String> favorites;

  bool isEditing = false;
  bool prog = false;

  _MySearchWidgetState({required this.color, required this.updateLocation,
        required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings, required this.real_loc,
    required this.secondColor, required this.textColor});

  List<String> recommend = [];

  void updateFav(List<String> fav){
    prefs.setStringList('favorites', fav);
    setState(() {
      favorites = fav;
    });
  }
  void updateProg(bool to) {
    setState(() {
      prog = to;
    });
  }

  void updateRec(List<String> rec) {
    setState(() {
      recommend = rec;
    });
  }

  void updateIsEditing(bool h) {
    setState(() {
      isEditing = h;
    });
  }

  @override
  Widget build(BuildContext context){
    return buildHihiSearch(color);
  }

  Widget buildHihiSearch(Color color) {
    return Stack(
      fit: StackFit.expand,
      children: [
        buildFloatingSearchBar(color),
      ],
    );
  }

  Widget buildFloatingSearchBar(Color color) {
    return searchBar(color, recommend, updateLocation,
        controller, updateIsEditing, isEditing, updateFav, favorites,
        updateRec, place, context, prog, updateProg, settings, real_loc, secondColor,
    textColor);

  }
}