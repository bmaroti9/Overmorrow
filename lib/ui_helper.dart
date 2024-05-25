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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:latlong2/latlong.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key.dart';
import 'caching.dart';

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

class UpdatedNotifier extends StatefulWidget {
  final data;
  final time;

  UpdatedNotifier({Key? key, required this.data, required this.time}) : super(key: key);

  @override
  _FadeWidgetState createState() => _FadeWidgetState();
}

class _FadeWidgetState extends State<UpdatedNotifier> with AutomaticKeepAliveClientMixin<UpdatedNotifier> {
  bool _hasBeenShown = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_hasBeenShown) {
      _hasBeenShown = true;
      return FadingWidget(data: widget.data, time: widget.time);
    }
    return Container();
  }
}

class FadingWidget extends StatefulWidget  {
  final data;
  final time;

  const FadingWidget({super.key, required this.data, required this.time});

  @override
  _FadingWidgetState createState() => _FadingWidgetState();
}

class _FadingWidgetState extends State<FadingWidget> {
  bool _isVisible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
    _timer = Timer(Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer in the dispose method
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final dif = widget.time.difference(widget.data.fetch_datetime).inMinutes;

    String text = translation('updated, just now', widget.data.settings["Language"]);

    print(dif);

    if (dif > 0) {
      text = translation('updated, x min ago', widget.data.settings["Language"]);
      text = text.replaceAll('x', dif.toString());
    }

    List<String> split = text.split(',');

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _isVisible ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(Icons.access_time, color: widget.data.current.textcolor, size: 13,),
            ),
            comfortatext('${split[0]},', 13, widget.data.settings,
                color: widget.data.current.textcolor, weight: FontWeight.w500),

            comfortatext(split[1], 13, widget.data.settings,
                color: widget.data.current.primary, weight: FontWeight.w500),
          ],
        ),
      ),
    );
  }
}

class DescriptionCircle extends StatelessWidget {

  final String text;
  final String undercaption;
  final String extra;
  final Color color;
  final double size;
  final settings;
  final bottom;
  final dir;

  const DescriptionCircle({super.key, required this.text,
      required this.undercaption, required this.color, required this.extra,
    required this.size, required this.settings, required this.bottom, required this.dir});

  @override
  Widget build(BuildContext context) {
    final double fontsize = size / 18;
    final double small_font = size / 25;
    final double width = size / 4.9;
    final double height = size / 4.9;
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
                        comfortatext(text, fontsize, settings, color: color, weight: FontWeight.w400),
                        Flexible(
                          child: comfortatext(extra, small_font, settings, color: color, weight: FontWeight.w500)
                        ),
                      ],
                    ),
                  )
                ),
                Visibility(
                  visible: dir != -1,
                  child:   Center(
                      child: RotationTransition(
                          turns: AlwaysStoppedAnimation(dir / 360),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: height * 0.75),
                            child: Icon(Icons.keyboard_arrow_up_outlined, color: color, size: 17,)
                          )
                      ),
                    )
                ),
              ],
            ),
          ),
        Center(
          child: Container(
            padding: const EdgeInsets.only(top:7),
            width: width + 8,
            height: height * bottom,
            child: comfortatext(undercaption, size / 28, settings, align: TextAlign.center, color: color, weight: FontWeight.w500)
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
                  padding: const EdgeInsets.only(top:5,bottom: 3, left: 4, right: 4),
                  decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blueAccent)
                    color: data.current.primary,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: comfortatext(value.toString(), 18, data.settings,
                      color: data.current.highlight, weight: FontWeight.w600)
                )
              ],
            ),
          )
        );
      }
    )
  );
}

Widget WindWidget(data, day) {
  List<dynamic> hours = day.hourly_for_precip;

  List<double> wind = [];

  for (var i = 0; i < hours.length; i+= 2) {
    double x = min(round((hours[i].wind + hours[i + 1].wind) * 0.5, decimals: 0) / 2, 10);
    print((hours[i].wind, x));
    wind.add(x);
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
                        child: MyChart(wind, data),
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 10, right: 4, left: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          comfortatext((index * 10).round().toString(), 17, data.settings),
                          comfortatext('m/s', 12, data.settings),
                        ],
                      ),
                    );
                  }
              ),
            )
          ]
      ),
      Padding(
          padding: const EdgeInsets.only(left: 33, top: 0, right: 70, bottom: 15),
          child: Visibility(
            visible: data.settings["Time mode"] == "24 hour",
            replacement: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3am", 14,data. settings),
                  comfortatext("9am", 14, data.settings),
                  comfortatext("3pm", 14, data.settings),
                  comfortatext("9pm", 14, data.settings),
                ]
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3:00", 14, data.settings),
                  comfortatext("9:00", 14, data.settings),
                  comfortatext("15:00", 14, data.settings),
                  comfortatext("21:00", 14, data.settings),
                ]
            ),
          )
      )
    ],
  );
}

Widget RainWidget(data, day) {
  List<dynamic> hours = day.hourly_for_precip;

  List<double> precip = [];

  for (var i = 0; i < hours.length; i+= 2) {
    double x = min(round((hours[i].precip + hours[i + 1].precip) * 4, decimals: 0) / 2, 10);
    precip.add(x);
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
                        child: MyChart(precip, data),
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    if (data.settings["Precipitation"] == 'in') {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10, right: 4, left: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            comfortatext((index * 0.2).toStringAsFixed(1), 17, data.settings),
                            comfortatext('in', 12, data.settings),
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
                            comfortatext((index * 5).toString(), 17, data.settings),
                            comfortatext('mm', 12, data.settings),
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
            visible: data.settings["Time mode"] == "24 hour",
            replacement: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3am", 14,data. settings),
                  comfortatext("9am", 14, data.settings),
                  comfortatext("3pm", 14, data.settings),
                  comfortatext("9pm", 14, data.settings),
                ]
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  comfortatext("3:00", 14, data.settings),
                  comfortatext("9:00", 14, data.settings),
                  comfortatext("15:00", 14, data.settings),
                  comfortatext("21:00", 14, data.settings),
                ]
            ),
          )
      )
    ],
  );
}

class MyChart extends StatelessWidget {
  final List<double> precip; // Sample data for the chart
  final data;

  const MyChart(this.precip, this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarChartPainter(precip, data),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> precip;
  final data;

  BarChartPainter(this.precip, this.data);

  @override
  void paint(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..color = data.current.primary
      ..style = PaintingStyle.fill;

    double maxValue = 10;
    double scaleY = size.height / maxValue;

    int numberOfBars = precip.length; // get rid of the extra precip points
    double totalWidth = size.width; // Subtract padding
    double barWidth = totalWidth / numberOfBars;

    for (int i = 0; i < numberOfBars; i++) {
      double barHeight = precip[i] * scaleY;
      double x = i * barWidth; // Add half of the remaining padding
      double y = size.height - barHeight;

      double topRadius = 6.0;

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

Future<List<String>> getWapiRecomend(String query) async {
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

  List<String> recomendations = [];
  for (var item in jsonbody) {
    recomendations.add(json.encode(item));
  }

  return recomendations;
}

Future<List<String>> getOMReccomend(String query, settings) async {
  var params = {
    'name': query,
    'count': '4',
    'language': translation('Search translation', settings["Language"]),
  };

  var url = Uri.http('geocoding-api.open-meteo.com', 'v1/search', params);

  var jsonbody = [];
  try {
    var file = await cacheManager.getSingleFile(
        url.toString(), headers: {'cache-control': 'private, max-age=120'});
    var response = await file.readAsString();
    jsonbody = jsonDecode(response)["results"];
  } on Error {
    return [];
  }

  //jsonbody = jsonDecode(response.body);

  List<String> recomendations = [];
  for (var item in jsonbody) {
    String pre = json.encode(item);

    if (!pre.contains('"admin1"')) {
      item["region"] = "";
    }
    else {
      item["region"] = item['admin1'];
    }

    if (!pre.contains('"country"')) {
      item["country"] = "";
    }

    String x = json.encode(item);

    x = x.replaceAll('latitude', "lat");
    x = x.replaceAll('longitude', "lon");

    print(('got here', x));

    recomendations.add(x);
  }
  return recomendations;
}

Future<List<String>> getRecommend(String query, searchProvider, settings) async {

  if (query == '') {
    return [];
  }

  if (searchProvider == "weatherapi") {
    return getWapiRecomend(query);
  }
  else {
    return getOMReccomend(query, settings);
  }
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
  final highlightColor;

  const MySearchParent({super.key, required this.updateLocation,
    required this.color, required this.place, required this.controller, required this.settings,
    required this.real_loc, required this.secondColor, required this.textColor,
    required this.highlightColor});

  @override
  _MySearchParentState createState() => _MySearchParentState(color: color,
  place: place, controller: controller, settings: settings, real_loc: real_loc,
      secondColor: secondColor, textColor: textColor, highlightColor: highlightColor);
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
  final highlightColor;

  _MySearchParentState({required this.color, required this.place,
  required this.controller, required this.settings, required this.real_loc, required this.secondColor,
  required this.textColor, required this.highlightColor});

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
            color: color, favorites: favorites, prefs: snapshot.data,
        place: place, controller: controller, settings: settings, real_loc: real_loc,
        secondColor: secondColor, textColor: textColor, highlightColor: highlightColor,);
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
  final highlightColor;

  const MySearchWidget({super.key, required this.color, required this.updateLocation,
  required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings, required this.real_loc,
    required this.secondColor, required this.textColor, required this.highlightColor});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(color: color,
  updateLocation: updateLocation, favorites: favorites,
      prefs: prefs, place: place, controller: controller, settings: settings, real_loc: real_loc,
  secondColor: secondColor, textColor: textColor, highlightColor: highlightColor);
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
  final highlightColor;

  List<String> favorites;

  bool isEditing = false;
  bool prog = false;

  _MySearchWidgetState({required this.color, required this.updateLocation,
        required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings, required this.real_loc,
    required this.secondColor, required this.textColor, required this.highlightColor});

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
    textColor, highlightColor);

  }
}