import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/search_screens.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key.dart';

const WHITE = Color(0xffFFFFFF);
const BLACK = Color(0xff000000);

Widget comfortatext(String text, double size, {Color color = WHITE}) {
  return Text(
    text,
    style: GoogleFonts.comfortaa(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w300,
    ),
    overflow: TextOverflow.ellipsis,
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
  final double fontsize = 21;
  final double width = 73;
  final double height = 73;
  final Color color;

  const DescriptionCircle({super.key, required this.text,
      required this.undercaption, required this.color, required this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2.5, color: Colors.white),
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
                  Text(
                    extra,
                    style: GoogleFonts.comfortaa(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            )
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
                fontSize: 15,
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

Future<List<String>> getRecommend(String query, List<String> favorites) async {

  if (query == '') {
    return [];
  }

  var params = {
    'key': apiKey,
    'q': query,
  };
  var url = Uri.http('api.weatherapi.com', 'v1/search.json', params);
  var response = await http.post(url);
  var jsonbody = jsonDecode(response.body);

  List<String> recomendations = [];
  for (var item in jsonbody) {
    recomendations.add(item["name"]);
  }

  return recomendations;
}
class MySearchParent extends StatefulWidget{
  final Function(String) updateLocation;
  final data;

  const MySearchParent({super.key, required this.updateLocation,
    required this.data});

  @override
  _MySearchParentState createState() => _MySearchParentState(
      data: data);
}

class _MySearchParentState extends State<MySearchParent> {
  bool isEditing = false;

  final data;

  _MySearchParentState({required this.data});

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
            data: data, favorites: favorites, prefs: snapshot.data);
      },
    );
  }
}

class MySearchWidget extends StatefulWidget{
  final data;
  final updateLocation;
  final favorites;
  final prefs;

  MySearchWidget({required this.data, required this.updateLocation,
  required this.favorites, required this.prefs});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(data: data,
  updateLocation: updateLocation, favorites: favorites, prefs: prefs);
}

class _MySearchWidgetState extends State<MySearchWidget> {
  final FloatingSearchBarController _controller = FloatingSearchBarController();
  final data;
  final updateLocation;
  final prefs;

  List<String> favorites;

  bool isEditing = false;

  _MySearchWidgetState({required this.data, required this.updateLocation,
        required this.favorites, required this.prefs});

  List<String> recommend = [];

  void updateFav(List<String> fav){
    prefs.setStringList('favorites', fav);
    setState(() {
      favorites = fav;
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
    return buildHihiSearch(data.current.backcolor);
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
        _controller, updateIsEditing, isEditing, updateFav, favorites,
        updateRec, data);

  }
}