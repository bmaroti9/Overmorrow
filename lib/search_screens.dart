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
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/main_ui.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:stretchy_header/stretchy_header.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'api_key.dart';

//before this the same place from 2 different providers would be registered as different,
//I am trying to fix this with this
String generateSimplifier(var split) {
  return "${split["name"]}, ${split["lat"].toStringAsFixed(2)}, ${split["lon"].toStringAsFixed(2)}";
}

Widget searchBar2(List<Color> colors, recommend,
    Function updateLocation, Function updateFav, favorites, Function updateRec, String place,
    var context, Map<String, String> settings) {

  Color primary = colors[1];
  Color onSurface = colors[4];
  Color surface = colors[0];

  return Align(
    alignment: Alignment.topCenter,
    child: GestureDetector(
      child: Hero(
        tag: 'searchBarHero',
        child: Container(
          height: 66,
          margin: EdgeInsets.only(left: 27, right: 27, top: MediaQuery.of(context).padding.top + 15),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(33)
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: Icon(Icons.place_outlined, color: primary,),
              ),
              Expanded(child: comfortatext(place, 24, settings, color: onSurface)),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(Icons.settings_outlined, color: primary, size: 25,),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HeroSearchPage(colors: colors, place: place, settings: settings, recommend: recommend,
            updateRec: updateRec, updateLocation: updateLocation, favorites: favorites, updateFav: updateFav,),

            fullscreenDialog: true,
          ),
        );
      },
    ),
  );
}

class HeroSearchPage extends StatefulWidget {

  final List<Color> colors;
  final String place;
  final settings;
  final recommend;
  final updateRec;
  final updateLocation;
  final favorites;
  final updateFav;

  const HeroSearchPage({super.key, required this.colors, required this.place, required this.settings,
    required this.recommend, required this.updateRec, required this.updateLocation, required this.favorites,
  required this.updateFav});

  @override
  State<HeroSearchPage> createState() => _HeroSearchPageState(colors: colors, place: place, settings: settings,
  recommend: recommend, updateRec: updateRec, updateLocation: updateLocation, favorites: favorites,
  updateFav: updateFav);
}


class _HeroSearchPageState extends State<HeroSearchPage> {

  final List<Color> colors;
  final String place;
  final settings;
  final recommend;
  final updateRec;
  final updateLocation;
  final favorites;
  final updateFav;

  _HeroSearchPageState({required this.colors, required this.place, required this.settings,
    required this.recommend, required this.updateRec, required this.updateLocation, required this.favorites,
  required this.updateFav});

  String text = "";
  bool isEditing = false;

  String locationSafe = "unknown";
  String placeName = "-";
  String country = "-";
  String region = "-";

  Timer? _debounce;

  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      var result = await getRecommend(query, settings["Search provider"], settings);
      updateRec(result);
    });
  }

  onFavChanged(List<String> fav) {
    setState(() {
      updateFav(fav);
    });
  }

  onIsEditingChanged() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  findCurrentPosition() async {

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 2));
    } on TimeoutException {
      try {
        position = (await Geolocator.getLastKnownPosition())!;
    } on Error {
      setState(() {
        locationSafe = "unableToLocate";
      });
      return "unableToLocate";
    }
    } on LocationServiceDisabledException {
      setState(() {
        locationSafe = "locationServiceDisabled";
      });
      return "locationServiceDisabled";
    }

    try {

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        placeName = place.locality ?? "";
        country = place.isoCountryCode ?? "";
        region = place.administrativeArea ?? "";
      });


    } on FormatException {
      setState(() {
        placeName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });

    } on PlatformException {
      setState(() {
        placeName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });
    }
  }

  askGrantLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationSafe = "disabled";
      });
      return "disabled";
    }
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationSafe = "deniedForever";
      });
      return "deniedForever";
    }
    String x = await checkIfLocationSafe(true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (x == "enabled") {
      findCurrentPosition();
    }
  }

  Future<String> checkIfLocationSafe([bool afterAsk = false]) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationSafe = "disabled";
      });
      return "disabled";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationSafe = "deniedForever";
      });
      return "deniedForever";
    }
    if (permission == LocationPermission.denied) {
      setState(() {
        locationSafe = "denied";
      });
      return "denied";
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        locationSafe = "enabled";
      });
      return "enabled";
    }
    setState(() {
      locationSafe = "failed";
    });
    return "failed";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      checkIfLocationSafe().then((x) {
        if (x == "enabled") {
          WidgetsBinding.instance.addPostFrameCallback((_){
            findCurrentPosition();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final Color surface = colors[0];
    final Color primary = colors[1];
    final Color outline = colors[5];
    final Color highlight = colors[7];
    Color onSurface = colors[4];

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit_outlined,
                color: primary, size: 25,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onIsEditingChanged();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Hero(
            tag: 'searchBarHero',
            child: Container(
              height: 66,
              margin: const EdgeInsets.only(left: 27, right: 27, top: 30),
              decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(33)
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Material(
                    color: highlight,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: TextSelectionThemeData(
                          selectionHandleColor: primary,
                        ),
                      ),
                      child: TextField(
                        onChanged: (String to) async{
                          setState(() {
                            text = to;
                          });
                          _onSearchChanged(to);
                        },
                        onSubmitted: (String submission) {
                          HapticFeedback.lightImpact();
                          updateLocation('query', submission);
                          Navigator.pop(context);
                        },
                        autofocus: true,
                        cursorColor: primary,
                        cursorWidth: 2,
                        style: GoogleFonts.outfit(
                          color: onSurface,
                          fontSize: 23 * getFontSize(settings["Font size"]!),
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle:  GoogleFonts.outfit(
                            color: outline,
                            fontSize: 20 * getFontSize(settings["Font size"]!),
                            fontWeight: FontWeight.w300,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Align(
              key: ValueKey<bool>(text == ""),
              alignment: Alignment.topCenter,
              child: buildRecommend(text, colors, settings, favorites, recommend,
              updateLocation, onFavChanged, isEditing, locationSafe, askGrantLocationPermission,
              placeName, country, region),
            ),
          )
        ],
      ),
    );
  }
}

Widget buildRecommend(String text, colors, settings, ValueListenable<List<String>> favoritesListen,
    ValueListenable<List<String>> recommend, updateLocation, onFavChanged, isEditing, locationSafe,
    askGrantLocationPermission, placeName, country, region) {

  final Color primary = colors[1];
  final Color outline = colors[5];
  final Color highlight = colors[7];
  final Color primaryLight = colors[2];
  final Color onPrimaryLight = colors[10];
  Color onSurface = colors[4];

  return ValueListenableBuilder(
    valueListenable: favoritesListen,
    builder: (context, value, child) {
      List<String> favorites = value;
      if (text == "") {
        return Padding(
          padding: const EdgeInsets.only(left: 30, top: 40, right: 30),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 475),
                childAnimationBuilder: (widget) =>
                    SlideAnimation(
                      horizontalOffset: 0.0,
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 2),
                        child: Icon(
                          Icons.gps_fixed, color: outline, size: 17,),
                      ),
                      comfortatext(
                          "current location", 18, settings, color: outline),
                    ],
                  ),
                  CurrentLocationWidget(settings, locationSafe, primaryLight, onPrimaryLight, outline,
                      askGrantLocationPermission, placeName, country, region, updateLocation, context),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 0),
                          child: Icon(
                            Icons.star_outline, color: outline, size: 18,),
                        ),
                        comfortatext("favorites", 18, settings, color: outline),
                      ],
                    ),
                  ),
                  if (favorites.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child,
                          Animation<double> animation) {
                        return SizeTransition(
                            sizeFactor: animation, child: child);
                      },
                      child: favoritesOrReorder(isEditing, favorites, settings, onFavChanged, highlight,
                          onSurface, primary, primaryLight, outline, updateLocation, context),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
      else {
        List<String> favoriteNarrow = [];
        for (int i = 0; i < favorites.length; i++) {
          var d = jsonDecode(favorites[i]);
          favoriteNarrow.add(generateSimplifier(d));
        }
        return ValueListenableBuilder(
          valueListenable: recommend,
          builder: (context, value, child) {
            List<String> rec = value;
            return Padding(
              padding: const EdgeInsets.only(
                  top: 20, bottom: 30, left: 30, right: 30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child,
                    Animation<double> animation) {
                    return SizeTransition(
                        sizeFactor: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey<String>(rec.toString()),
                    decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: rec.isEmpty
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.all(10),
                    child: Column(
                      children: List.generate(rec.length, (index) {
                        var split = json.decode(rec[index]);
                        String name = split["name"];
                        String country = generateAbbreviation(split["country"]);
                        String region = split["region"];
                        String simplifier = generateSimplifier(split);

                        bool contained = favoriteNarrow.contains(simplifier);
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            updateLocation(
                                '${split["lat"]}, ${split["lon"]}',
                                split["name"]);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 7, top: 6, bottom: 6),
                            child:
                            Row(
                              children: [
                                Expanded(
                                    child: Column(
                                      crossAxisAlignment : CrossAxisAlignment.start,
                                      children: [
                                        comfortatext(name, 20, settings, color: onSurface),
                                        comfortatext("$region, $country", 15, settings, color: outline)
                                      ],
                                    )
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (contained) {
                                      HapticFeedback.mediumImpact();
                                      int z = favoriteNarrow.indexOf(simplifier);
                                      favorites.removeAt(z);
                                      onFavChanged(favorites);
                                    }
                                    else{
                                      HapticFeedback.lightImpact();
                                      favorites.add(rec[index]);
                                      onFavChanged(favorites);
                                    }
                                  },
                                  icon: Icon(
                                    contained? Icons.star : Icons.star_outline,
                                    color: primary, size: 24,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                      )
                    )
                  )
                ),
              ),
            );
          }
        );
      }
    }
  );
}

Widget CurrentLocationWidget(settings, locationSafe, primaryLight, onPrimaryLight, outline, askGrantLocationPermission,
    String placeName, String country, String region, updateLocation, context) {
  if (locationSafe == "denied") {
    return GestureDetector(
      onTap: () {
        askGrantLocationPermission();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 30),
        padding: const EdgeInsets.only(
            left: 25, right: 25, top: 20, bottom: 20),
        height: 66,
        decoration: BoxDecoration(
          color: primaryLight,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_fixed,
              color: onPrimaryLight, size: 19,),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 2),
                child: comfortatext(
                      "grant location permission", 19, settings,
                      color: onPrimaryLight),
              ),
            ),

          ],
        ),
      ),
    );
  }
  if (locationSafe == "enabled") {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        updateLocation('40.7128, -74.0060', 'CurrentLocation'); // this is new york for backup
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 30),
        padding: const EdgeInsets.only(
            left: 25, right: 25, top: 19, bottom: 19),
        decoration: BoxDecoration(
          color: primaryLight,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Expanded(
                child: Column(
                  crossAxisAlignment : CrossAxisAlignment.start,
                  children: [
                    comfortatext(placeName, 20, settings, color: onPrimaryLight),
                    comfortatext("$region, $country", 15, settings, color: onPrimaryLight)
                  ],
                )
            ),
            Icon(Icons.keyboard_arrow_right_rounded,
              color: onPrimaryLight,)
          ],
        ),
      ),
    );
  }
  return Container(
    margin: const EdgeInsets.only(top: 20, bottom: 30),
    padding: const EdgeInsets.only(
        left: 25, right: 25, top: 20, bottom: 20),
    height: 66,
    decoration: BoxDecoration(
      color: primaryLight,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      children: [
        Icon(Icons.gps_off,
          color: onPrimaryLight, size: 19,),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: comfortatext(
                locationSafe, 19, settings,
                color: onPrimaryLight),
          ),
        ),

      ],
    ),
  );
}

Widget favoritesOrReorder(isEditing, favorites, settings, onFavChanged,
    highlight, onSurface, primary, primaryLight, outline, updateLocation, context) {
  if (isEditing) {
    return reorderFavorites(favorites, settings, onFavChanged, highlight, onSurface, primary, primaryLight, outline);
  }
  else {
    return Container(
      key: const ValueKey<String>("normal"),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: highlight,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
            children: List.generate(favorites.length, (index) {
              var split = json.decode(favorites[index]);
              String name = split["name"];
              String country = generateAbbreviation(split["country"]);
              String region = split["region"];
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  HapticFeedback.selectionClick();
                  updateLocation(
                      '${split["lat"]}, ${split["lon"]}', split["name"]);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 7, top: 7, bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                            crossAxisAlignment : CrossAxisAlignment.start,
                            children: [
                              comfortatext(name, 20, settings, color: onSurface),
                              comfortatext("$region, $country", 15, settings, color: outline)
                            ],
                          )
                      ),
                      Icon(Icons.keyboard_arrow_right_rounded, color: primary,)
                    ],
                  ),
                ),
              );
            })
        )
    );
  }
}

Widget reorderFavorites(_items, settings, onFavChanged, highlight, onSurface, primary, primaryLight, outline) {
  return Container(
    key: const ValueKey<String>("editing"),
    decoration: BoxDecoration(
      color: highlight,
      borderRadius: BorderRadius.circular(30),
    ),
    child: ReorderableListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      proxyDecorator: (child, index, animation) => Material(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        for (int index = 0; index < _items.length; index += 1)
          reorderableItem(_items, index, settings, highlight, onSurface, outline, primary, onFavChanged)
      ],
      onReorder: (int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final String item = _items.removeAt(oldIndex);
        _items.insert(newIndex, item);
        onFavChanged(_items);
      },
    ),
  );
}

Widget reorderableItem(List<dynamic> items, index, settings, highlight, onSurface, outline, primary, onFavChanged) {
  var split = json.decode(items[index]);
  String name = split["name"];
  String country = generateAbbreviation(split["country"]);
  String region = split["region"];
  return Container(
    key: Key("$name, $country, $region"),
    color: highlight,
    child: Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 4, bottom: 4),
      child:
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.drag_indicator, color: outline,),
          ),
          Expanded(
              child: Column(
                crossAxisAlignment : CrossAxisAlignment.start,
                children: [
                  comfortatext(name, 20, settings, color: onSurface),
                  comfortatext("$region, $country", 15, settings, color: outline)
                ],
              )
          ),
          IconButton(
            onPressed: () {
              items.removeAt(index);
              onFavChanged(items);
            },
            icon: Icon(
              Icons.delete_outline,
              color: primary, size: 23,
            ),
          )
        ],
      ),
    ),
  );
}

Widget searchBar(List<Color> colors, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Function updateRec, String place, var context,
    bool prog, Function updateProg, Map<String, String> settings, String real_loc) {


  Color primary = colors[1];
  Color onSurface = colors[4];
  Color surface = colors[0];
  Color containerLow = colors[6];

  return FloatingSearchBar(
      hint: AppLocalizations.of(context)!.search,
      title: Container(
        padding: const EdgeInsets.only(left: 2),
        child: comfortatext(place, 24, settings, color: onSurface, weight: FontWeight.w300)
      ),
      hintStyle: GoogleFonts.outfit(
        color: onSurface,
        fontSize: 20 * getFontSize(settings["Font size"]!),
        fontWeight: FontWeight.w300,
      ),

      queryStyle: GoogleFonts.outfit(
        color: onSurface,
        fontSize: 23 * getFontSize(settings["Font size"]!),
        fontWeight: FontWeight.w300,
      ),

      margins: EdgeInsets.only(left: 27, right: 27, top: MediaQuery.of(context).padding.top + 15),

      borderRadius: BorderRadius.circular(30),
      backgroundColor: surface,
      accentColor: primary,

      elevation: 0,
      height: 64,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 500),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      debounceDelay: const Duration(milliseconds: 500),

      controller: controller,
      width: 800,

      onFocusChanged: (to) {
        HapticFeedback.selectionClick();
      },

      onQueryChanged: (query) async {
        isEditing = false;
        var result = await getRecommend(query, settings["Search provider"], settings);
        updateRec(result);
      },
      onSubmitted: (submission) {
        HapticFeedback.lightImpact();
        updateLocation('query', submission);
        controller.close();
      },

      insets: EdgeInsets.zero,
      automaticallyImplyDrawerHamburger: false,
      padding: const EdgeInsets.only(left: 10, right: 10),
      iconColor: primary,
      backdropColor: containerLow,
      closeOnBackdropTap: true,
      transition: ExpandingFloatingSearchBarTransition(),
      automaticallyImplyBackButton: false,
      leadingActions: [
        FloatingSearchBarAction(
          showIfOpened: true,
          showIfClosed: false,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircularButton(
              icon: Icon(Icons.arrow_back_outlined, color: primary, size: 22,),
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.close();
              },
            ),
          ),
        ),
        FloatingSearchBarAction(
          showIfOpened: false,
          showIfClosed: true,
          child: Padding(
            padding: const EdgeInsets.only(left: 11, right: 10),
            child: Icon(Icons.place_outlined, color: primary, size: 25,),
          ),
        ),
      ],
      actions: [
        /*
        FloatingSearchBarAction(
          showIfOpened: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 3),
            child: Visibility(
              visible: !Platform.isLinux,
              child: LocationButton(updateProg, updateLocation, color, real_loc, secondColor,
              textColor)
            ),
          ),
        ),

         */

        FloatingSearchBarAction(
          showIfOpened: false,
          showIfClosed: true,
          child: IconButton(
            icon: Icon(Icons.settings_outlined, color: primary, size: 25,),
            onPressed: () {
              HapticFeedback.selectionClick();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        FloatingSearchBarAction(
          showIfOpened: true,
          showIfClosed: false,
          child: Visibility(
            visible: controller.query != '',
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircularButton(
                icon: Icon(Icons.close, color: primary,),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.clear();
                },
              ),
            ),
          ),
        ),
      ],
      builder: (context, transition) {
        return Container();
      }
  );
}

Widget decideSearch(List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, String entered, Map<String, String> settings,
    context, List<Color> colors) {

  if (entered == '') {
    return defaultSearchScreen(updateLocation,
        controller, updateIsEditing, isEditing, updateFav, favorites, settings, context, colors);
  }
  else{
    if (recommend.isNotEmpty) {
      return recommendSearchScreen(
          recommend, updateLocation, controller,
          favorites, updateFav, settings, colors);
    }
  }
  return Container();
}

Widget defaultSearchScreen(Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Map<String, String> settings, context, colors) {

  return Container(color: Colors.pink,);

  /*
  List<Icon> Myicon = [
    const Icon(null),
    Icon(Icons.close, color: color, size: 20,),
  ];

  Icon editIcon = const Icon(Icons.icecream, color: WHITE,);
  Color rectColor = textColor;
  Color text = textColor;
  List<int> icons = [];
  if (isEditing) {
    for (String _ in favorites) {
      icons.add(1);
    }
    editIcon = Icon(Icons.check, color: color, size: 20,);
    rectColor = textColor;
    text = color;
  }
  else{
    for (String _ in favorites) {
      icons.add(0);
    }
    editIcon = Icon(Icons.create_outlined, color: textColor, size: 20,);
    rectColor = color;
    text = textColor;
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top:5, bottom: 8, right: 20, left: 20),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 1, top: 4, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(
                    AppLocalizations.of(context)!.favorites, 20,
                    settings,
                    color: extraTextColor),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child,);
              },
              child: SizedBox(
                key: ValueKey<bool> (isEditing),
                height: 45,
                width: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.all(2),
                      backgroundColor: rectColor,
                      shape: RoundedRectangleBorder(
                        //side: BorderSide(color: rectColor, width: 1.5),
                          borderRadius: BorderRadius.circular(18)
                      )
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    updateIsEditing(!isEditing);
                  },
                  child: editIcon,
                ),
              ),
            ),
          ],
        ),
      ),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child,);
          },
          child: Container(
            key: ValueKey<Color>(rectColor),
            padding: const EdgeInsets.only(top:10, bottom: 10),
            decoration: BoxDecoration(
              color: rectColor,
              //border: Border.all(width: 1.2, color: WHITE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                var split = json.decode(favorites[index]);
                //var split = favorites[index].split("/");
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    updateLocation('${split["lat"]}, ${split["lon"]}', split["name"]);
                    controller.close();
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, bottom: 1, right: 10, top: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              comfortatext(split["name"], 24 * getFontSize(settings["Font size"]!), settings,
                                  color: text),
                              comfortatext(split["region"] + ", " +  generateAbbreviation(split["country"]), 16
                                  * getFontSize(settings["Font size"]!), settings, color: extraTextColor)
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Myicon[icons[index]],
                          onPressed: () {
                            if (isEditing) {
                              HapticFeedback.mediumImpact();
                              favorites.remove(favorites[index]);
                              updateFav(favorites);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ),
    ],
  );

   */
}

Widget recommendSearchScreen(List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller, List<String> favorites,
    Function updateFav, var settings, colors) {
  List<Icon> icons = [];

  return Container();

  /*

  for (String n in recommend) {
    if (favorites.contains(n)) {
      icons.add(Icon(Icons.favorite, color: textColor, size: 21,),);
    }
    else{
      icons.add(Icon(Icons.favorite_border, color: textColor, size: 21,),);
    }
  }

  return Container(
    key: ValueKey<int>(recommend.length),
    padding: const EdgeInsets.only(top:10, bottom: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 0),
      itemCount: recommend.length,
      itemBuilder: (context, index) {
        var split = json.decode(recommend[index]);
        //var split = recommend[index].split("/");
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            HapticFeedback.selectionClick();
            updateLocation('${split["lat"]}, ${split["lon"]}', split["name"]);
            controller.close();
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20, bottom: 1,
                  right: 10, top: 1),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      comfortatext(split["name"], 24 * getFontSize(settings["Font size"]),
                          settings, color: textColor),
                      comfortatext(split["region"] + ", " +  generateAbbreviation(split["country"]), 16 * getFontSize(settings["Font size"]),
                          settings, color: extraTextColor)
                      //comfortatext(split[0], 23)
                    ],
                  ),
                ),

                IconButton(onPressed: () {
                  if (favorites.contains(recommend[index])) {
                    HapticFeedback.mediumImpact();
                    favorites.remove(recommend[index]);
                    updateFav(favorites);
                  }
                  else{
                    HapticFeedback.lightImpact();
                    favorites.add(recommend[index]);
                    updateFav(favorites);
                  }
                },
                  icon: icons[index]
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget LocationButton(Function updateProg, Function updateLocation, Color color, String real_loc,
    Color secondColor, Color textColor) {
  if (real_loc == 'CurrentLocation') {
    return Padding(
      padding: const EdgeInsets.only(right: 7, top: 4.5, bottom: 4.5),
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.all(10),
              backgroundColor: textColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19)
              )
          ),
          onPressed: () async {},
          child: Icon(Icons.place_outlined, color: color,),
        ),
      ),
    );
  }
  else{
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 3, bottom: 3),
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.all(10),
              backgroundColor: color,
              side: BorderSide(width: 1.7, color: secondColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)
            )
          ),
          onPressed: () async {
            HapticFeedback.lightImpact();
            updateLocation('40.7128, 74.0060', 'CurrentLocation');
          },                   //^ this is new york for backup
          child: Icon(Icons.place_outlined, color: textColor,),
        ),
      ),
    );
  }

   */
}



class dumbySearch extends StatelessWidget {
  final errorMessage;
  final updateLocation;
  final place;
  final icon;
  final settings;
  final provider;
  final latlng;
  final shouldAdd;

  dumbySearch({super.key, required this.errorMessage,
    required this.updateLocation, required this.icon, required this.place,
  required this.settings, required this.provider, required this.latlng, this.shouldAdd});

  final FloatingSearchBarController controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext context) {

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;

    const replacement = "<api_key>";
    String newStr = errorMessage.toString().replaceAll(wapi_Key, replacement);
    newStr = newStr.replaceAll(access_key, replacement);
    newStr = newStr.replaceAll(timezonedbKey, replacement);

    Color primary = const Color(0xffc2b9c2);
    Color back = const Color(0xff847F83);

    List<Color> colors = getColors(primary, back, settings, 0);

    return Scaffold(
      drawer: MyDrawer(backupprimary: primary, settings: settings, backupback: back, image: Image.asset("assets/backdrops/grayscale_snow2.jpg",
        fit: BoxFit.cover, width: double.infinity, height: double.infinity), surface: colors[0],
        onSurface: colors[4], primary: colors[1], hihglight: colors[6]
      ),
      backgroundColor: colors[0],
      body: StretchyHeader.singleChild(
        displacement: 150,
        onRefresh: () async {
          await updateLocation(latlng, place, time: 400);
        },
        headerData: HeaderData(
            blurContent: false,
            headerHeight: max(size.height * 0.51, 400), //we don't want it to be smaller than 400
            header: ParrallaxBackground(image: Image.asset("assets/backdrops/grayscale_snow2.jpg", fit: BoxFit.cover,), key: Key(place),
              color: darken(colors[0], 0.1),),
            overlay: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 50, bottom: 20),
                          child: Icon(icon, color: Colors.black54, size: 20),
                        ),
                        comfortatext(newStr, 17, settings, color: Colors.black54, weight: FontWeight.w500,
                        align: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                MySearchParent(updateLocation: updateLocation,
                    colors: colors, place: place, settings: settings,)
              ],
            )
        ),
        child:
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: comfortatext(shouldAdd ?? "", 16, settings, color: colors[4], weight: FontWeight.w400,),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: providerSelector(settings, updateLocation, colors[4], colors[7],
                    colors[1], provider, latlng, place, context),
              ),
            ],
          ),
      ),
    );
  }
}