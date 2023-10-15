import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:http/http.dart' as http;

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
  final double fontsize = 22;
  final double width = 72;
  final double height = 72;
  final Color color;

  const DescriptionCircle({super.key, required this.text,
      required this.undercaption, required this.color, required this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
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
            width: width,
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

const favorites = ['Szeged', 'Nashville', 'New York', 'Phoenix',
        'Alsoors'];

Future<List<String>> getRecommend(String query) async {

  if (query == '') {
    return favorites;
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

  return recomendations; // Return the list of Recomend objects
}

class MySearchWidget extends StatefulWidget {
  final Function(String) updateLocation;
  final data;

  MySearchWidget({required this.updateLocation,
  required this.data});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState(
        data: data);
}

class _MySearchWidgetState extends State<MySearchWidget> {
  final FloatingSearchBarController _controller = FloatingSearchBarController();

  final data;
  _MySearchWidgetState({required this.data});

  var recommend = [];

  void updateRec(List<String> rec) {
    setState(() {
      recommend = rec;
    });
  }

  @override
  Widget build(BuildContext context) {
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

    return FloatingSearchBar(
      hint: 'Search...',
      title: Container(
        padding: const EdgeInsets.only(left: 0, top: 3),
        child: Text(
          data.place,
          style: GoogleFonts.comfortaa(
            color: WHITE,
            fontSize: 28,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      hintStyle: GoogleFonts.comfortaa(
        color: WHITE,
        fontSize: 20,
        fontWeight: FontWeight.w100,
      ),

      queryStyle: GoogleFonts.comfortaa(
        color: WHITE,
        fontSize: 25,
        fontWeight: FontWeight.w100,
      ),

      borderRadius: BorderRadius.circular(25),
      backgroundColor: color,
      border: const BorderSide(width: 1.0, color: WHITE),

      elevation: 0,
      height: 60,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      debounceDelay: const Duration(milliseconds: 500),

      controller: _controller,

      onFocusChanged: (change) async {
        if (change) {
          var result = favorites;
          updateRec(result);
          print(('hihihihihi', recommend));
        }
        else {_controller.close();}
      },

      onQueryChanged: (query) async {
        var result = await getRecommend(query);
        updateRec(result);
        print(('hihihihihi', recommend));
      },
      onSubmitted: (submission) {
        widget.updateLocation(submission); // Call the callback to update the location
        _controller.close();
      },

      iconColor: WHITE,
      //backdropColor: darken(color, 0.5),
      closeOnBackdropTap: true,
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.place, color: WHITE,),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction(
          showIfOpened: true,
          showIfClosed: false,
          child: CircularButton(
            icon: const Icon(Icons.close, color: WHITE,),
            onPressed: () {
              _controller.close();
            },
          ),
        ),
      ],
      builder: (context, transition) {
        if (recommend.length > 0) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.only(top:10, bottom: 10),
              color: color,
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 12),
                itemCount: recommend.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      widget.updateLocation(recommend[index]);
                      _controller.close();
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, bottom: 12),
                      child: comfortatext(recommend[index], 27, color: WHITE),
                    ),
                  );
                },
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}
