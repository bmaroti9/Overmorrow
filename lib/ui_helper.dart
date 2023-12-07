/*
Copyright (C) <2023>  <Balint Maroti>

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

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/search_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key.dart';
import 'caching.dart';

const WHITE = Color(0xffFFFFFF);
const BLACK = Color(0xff000000);

Widget comfortatext(String text, double size,
    {Color color = WHITE, TextAlign align = TextAlign.left }) {
  return Text(
    text,
    style: GoogleFonts.comfortaa(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w300,
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

class DescriptionCircle extends StatelessWidget {

  final String text;
  final String undercaption;
  final String extra;
  final Color color;
  final double size;

  const DescriptionCircle({super.key, required this.text,
      required this.undercaption, required this.color, required this.extra, required this.size});

  @override
  Widget build(BuildContext context) {
    final double fontsize = size / 17;
    final double small_font = size / 25;
    final double width = size / 5;
    final double height = size / 5;
    return Container(
      //padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: width,
            child: Stack(
              children: [
                /*
                Align(
                  alignment: Alignment.bottomCenter,
                    child: RainCircle(rainAmount: 0.3)
                ),
                 */
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    //shape: BoxShape.circle,
                    border: Border.all(width: 2.5, color: Colors.white),
                    //color: WHITE,
                    borderRadius: BorderRadius.circular(35)
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          text,
                          style: GoogleFonts.comfortaa(
                            color: color,
                            fontSize: fontsize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            extra,
                            style: GoogleFonts.comfortaa(
                              color: color,
                              fontSize: small_font,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
            height: height,
            child: Text(
              undercaption,
              textAlign: TextAlign.center,
              style: GoogleFonts.comfortaa(
                color: color,
                fontSize: small_font,
                fontWeight: FontWeight.w300,
              ),
            ),
          )
        )
      ]
      ),
    );
  }
}

Widget aqiDataPoints(String name, double value) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 2, top: 2),
    child: Row(
      children: [
        comfortatext(name, 22),
        Spacer(),
        Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
              //border: Border.all(color: Colors.blueAccent)
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(10)
          ),
          child: Text(value.toString(), textScaleFactor: 1.2,),
        )
      ],
    ),
  );
}

Future<List<String>> getRecommend(String query, List<String> favorites) async {

  if (query == '') {
    return [];
  }

  var params = {
    'key': apiKey,
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
    recomendations.add(item["name"]);
  }

  return recomendations;
}
class MySearchParent extends StatefulWidget{
  final Function(String) updateLocation;
  final color;
  final place;
  final controller;
  final settings;

  const MySearchParent({super.key, required this.updateLocation,
    required this.color, required this.place, required this.controller, required this.settings});

  @override
  _MySearchParentState createState() => _MySearchParentState(color: color,
  place: place, controller: controller, settings: settings);
}


class RainCircle extends StatelessWidget {
  final double rainAmount;

  RainCircle({required this.rainAmount});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: rainAmount,
        child: Container(
          width: 73, // Adjust the size as needed
          height: 73, // Make sure it's a square container
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue, // You can change the color to represent the rain
          ),
        ),
      ),
    );
  }
}

class _MySearchParentState extends State<MySearchParent> {
  bool isEditing = false;

  final color;
  final place;
  final controller;
  final settings;

  _MySearchParentState({required this.color, required this.place,
  required this.controller, required this.settings});

  Future<SharedPreferences> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  List<String> getFavorites(SharedPreferences? prefs){
    final ifnot = ['Nashville'];
    final used = prefs?.getStringList('favorites') ?? ifnot;
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
        place: place, controller: controller, settings: settings,);
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

  const MySearchWidget({super.key, required this.color, required this.updateLocation,
  required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settings});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(color: color,
  updateLocation: updateLocation, favorites: favorites,
      prefs: prefs, place: place, controller: controller, settins: settings);
}

class _MySearchWidgetState extends State<MySearchWidget> {
  //final FloatingSearchBarController _controller = FloatingSearchBarController();
  final controller;
  final color;
  final place;
  final updateLocation;
  final prefs;
  final settins;

  List<String> favorites;

  bool isEditing = false;
  bool prog = false;

  _MySearchWidgetState({required this.color, required this.updateLocation,
        required this.favorites, required this.prefs, required this.place,
  required this.controller, required this.settins});

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
        updateRec, place, context, prog, updateProg, settins);

  }
}