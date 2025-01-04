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
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:latlong2/latlong.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    {Color color = WHITE, TextAlign align = TextAlign.left, weight = FontWeight.w400,
      decoration = TextDecoration.none}) {

  double x = getFontSize(settings["Font size"]);
  return Text(
    text,
    style: GoogleFonts.comfortaa(
      color: color,
      fontSize: size * x,
      fontWeight: weight,
      height: 1.1,
      decoration: decoration,
      decorationColor: color,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 40,
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
      c.alpha,
      (c.red * f).round(),
      (c.green  * f).round(),
      (c.blue * f).round()
  );
}

Color lighten2(Color c, [double amount = 0.1]) {
  assert(0 <= amount && amount <= 1);
  return Color.fromARGB(
      c.alpha,
      c.red + ((255 - c.red) * amount).round(),
      c.green + ((255 - c.green) * amount).round(),
      c.blue + ((255 - c.blue) * amount).round()
  );
}

Color lightAccent(Color color, int intensity) {
  double x = intensity / (color.red + color.green + color.blue);
  return Color.fromRGBO(sqrt(color.red * x).toInt(), sqrt(color.green * x).toInt(), sqrt(color.blue * x).toInt(), 1);
}

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

class FadingWidget extends StatefulWidget  {
  final data;
  final time;

  const FadingWidget({super.key, required this.data, required this.time});

  @override
  _FadingWidgetState createState() => _FadingWidgetState();
}

class _FadingWidgetState extends State<FadingWidget> with AutomaticKeepAliveClientMixin {
  bool _isVisible = true;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
    _timer = Timer(const Duration(milliseconds: 2000), () {
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
    super.build(context);

    final dif = widget.time.difference(widget.data.fetch_datetime).inMinutes;

    String text = AppLocalizations.of(context)!.updatedJustNow;

    if (dif > 0 && dif < 45) {
      text = AppLocalizations.of(context)!.updatedXMinAgo;
      text = text.replaceAll('x', dif.toString());
    }
    else if (dif >= 45 && dif < 1440) {
      int hour = (dif + 30) ~/ 60;
      if (hour == 1) {
        text = "updated, x hour ago";
      }
      else {
        text = "updated, x hours ago";
      }

      text = text.replaceAll('x', hour.toString());
    }
    else if (dif >= 1440) { //number of minutes in a day
      int day = (dif + 720) ~/ 1440;
      if (day == 1) {
        text = "updated, x day ago";
      }
      else {
        text = "updated, x days ago";
      }

      text = text.replaceAll('x', day.toString());
    }

    List<String> split = text.split(',');

    return Container(
      color: widget.data.isonline ? widget.data.current.surface : widget.data.current.primaryLight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final inAnimation = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
          );
          final outAnimation = CurvedAnimation(
            parent: animation,
            curve: const Interval(1.0, 0.5, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: _isVisible ? outAnimation : inAnimation,
            child: child,
          );
        },
        child: SinceLastUpdate(
          key: ValueKey<bool>(_isVisible),
          split: split,
          data: widget.data,
          isVisible: _isVisible,
        ),
      ),
    );
  }
}


class SinceLastUpdate extends StatefulWidget {
  final split;
  final data;
  final isVisible;

  SinceLastUpdate({Key? key, required this.data, required this.split, required this.isVisible}) : super(key: key);

  @override
  _SinceLastUpdateState createState() => _SinceLastUpdateState();
}

class _SinceLastUpdateState extends State<SinceLastUpdate>{

  @override
  Widget build(BuildContext context) {

    Color text = widget.data.isonline ? widget.data.current.onSurface : widget.data.current.onPrimaryLight;
    Color highlight = widget.data.isonline ? widget.data.current.primary : widget.data.current.onPrimaryLight;

    if (widget.isVisible) {
      return SizedBox(
        height: 21,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13,),
              ),
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 7),
                child: comfortatext(AppLocalizations.of(context)!.offline, 13, widget.data.settings,
                    color: highlight, weight: FontWeight.w600),
              ),
              if (widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(Icons.access_time, color: highlight, size: 13,),
              ),
              comfortatext('${widget.split[0]},', 13, widget.data.settings,
                  color: widget.data.isonline ? highlight
                      : text, weight: FontWeight.w500),

              comfortatext(widget.split.length > 1 ? widget.split[1] : "", 13, widget.data.settings,
                  color: text, weight: FontWeight.w500),
            ],
          ),
        ),
      );
    } else{
      List<String> split = AppLocalizations.of(context)!.photoByXOnUnsplash.split(",");
      return SizedBox(
        height: 21,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13,),
              ),
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 7),
                child: comfortatext(AppLocalizations.of(context)!.offline, 13, widget.data.settings,
                    color: highlight, weight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  await _launchUrl(widget.data.current.photoUrl + "?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                   padding: const EdgeInsets.all(1),
                    minimumSize: const Size(0, 22),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(split[0], 12.5, widget.data.settings, color: text,
                    decoration: TextDecoration.underline),
              ),
              comfortatext(split[1], 12.5, widget.data.settings, color: text),
              TextButton(
                onPressed: () async {
                  await _launchUrl(widget.data.current.photographerUrl + "?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(widget.data.current.photographerName, 12.5, widget.data.settings, color: text,
                    decoration: TextDecoration.underline),
              ),
              comfortatext(split[3], 12.5, widget.data.settings, color: text),
              TextButton(
                onPressed: () async {
                  await _launchUrl("https://unsplash.com/?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(split[4], 12.5, widget.data.settings, color: text,
                    decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      );
    }
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

                    border: Border.all(width: 1.9, color: color),
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
                          child: comfortatext(extra, small_font, settings, color: color, weight: FontWeight.w400)
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
    'language': 'en',
  };

  var url = Uri.http('geocoding-api.open-meteo.com', 'v1/search', params);

  var jsonbody = [];
  try {
    print("got here");
    var file = await cacheManager.getSingleFile(url.toString(), key: "$query, open-meteo search",
        headers: {'cache-control': 'private, max-age=120'}).timeout(const Duration(seconds: 3));
    print("never got here");
    var response = await file.readAsString();
    jsonbody = jsonDecode(response)["results"];
  } catch(e) {
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
  final extraTextColor;

  const MySearchParent({super.key, required this.updateLocation,
    required this.color, required this.place, required this.controller, required this.settings,
    required this.real_loc, required this.secondColor, required this.textColor,
    required this.highlightColor, required this.extraTextColor});

  @override
  _MySearchParentState createState() => _MySearchParentState(color: color,
  place: place, controller: controller, settings: settings, real_loc: real_loc,
      secondColor: secondColor, textColor: textColor, highlightColor: highlightColor,
    extraTextColor: extraTextColor);
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
  final extraTextColor;

  _MySearchParentState({required this.color, required this.place,
  required this.controller, required this.settings, required this.real_loc, required this.secondColor,
  required this.textColor, required this.highlightColor, required this.extraTextColor});

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
        secondColor: secondColor, textColor: textColor, highlightColor: highlightColor,
        extraTextColor: extraTextColor,);
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
  final extraTextColor;

  const MySearchWidget({super.key, required this.color, required this.updateLocation,
  required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings, required this.real_loc,
    required this.secondColor, required this.textColor, required this.highlightColor,
    required this.extraTextColor});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(color: color,
  updateLocation: updateLocation, favorites: favorites,
      prefs: prefs, place: place, controller: controller, settings: settings, real_loc: real_loc,
  secondColor: secondColor, textColor: textColor, highlightColor: highlightColor,
  extraTextColor: extraTextColor);
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
  final extraTextColor;

  List<String> favorites;

  bool isEditing = false;
  bool prog = false;

  _MySearchWidgetState({required this.color, required this.updateLocation,
        required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings, required this.real_loc,
    required this.secondColor, required this.textColor, required this.highlightColor,
  required this.extraTextColor});

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
    textColor, highlightColor, extraTextColor);

  }
}