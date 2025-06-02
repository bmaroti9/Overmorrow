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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/services/location_service.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'l10n/app_localizations.dart';
import 'main.dart';

//before this the same place from 2 different providers would be registered as different,
//I am trying to fix this with this
String generateSimplifier(var split) {
  return "${split["name"]}, ${split["lat"].toStringAsFixed(2)}, ${split["lon"].toStringAsFixed(2)}";
}

Widget searchBar2(ColorScheme palette, recommend,
    Function updateLocation, Function updateFav, favorites, Function updateRec, String place,
    var context, Map<String, String> settings, Image image) {

  return Align(
    alignment: Alignment.topCenter,
    child: GestureDetector(
      child: Hero(
        tag: 'searchBarHero',
        child: Container(
          height: 67,
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 15, left: 28, right: 28),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(33)
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 13),
                child: Icon(Icons.place_outlined, color: palette.primary,),
              ),
              Expanded(child: comfortatext(place, 23, settings, color: palette.onSurface, maxLines: 1)),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: Icon(Icons.settings_outlined, color: palette.primary, size: 25,),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(image: image),
                      ),
                    ).then((value) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) {
                            return const MyApp();
                          },
                        ),
                      );
                    });
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
            builder: (context) => HeroSearchPage(palette: palette, place: place, settings: settings, recommend: recommend,
            updateRec: updateRec, updateLocation: updateLocation, favorites: favorites, updateFav: updateFav,
              isTabletMode: false, image: image,),
            fullscreenDialog: true
          ),
        );
      },
    ),
  );
}

class HeroSearchPage extends StatefulWidget {

  final ColorScheme palette;
  final String place;
  final settings;
  final recommend;
  final updateRec;
  final updateLocation;
  final favorites;
  final updateFav;
  final isTabletMode;
  final Image image;

  const HeroSearchPage({super.key, required this.palette, required this.place, required this.settings,
    required this.recommend, required this.updateRec, required this.updateLocation, required this.favorites,
  required this.updateFav, required this.isTabletMode, required this.image});

  @override
  State<HeroSearchPage> createState() => _HeroSearchPageState(palette: palette, place: place, settings: settings,
  recommend: recommend, updateRec: updateRec, updateLocation: updateLocation, favorites: favorites,
  updateFav: updateFav, isTabletMode: isTabletMode, image: image);
}


class _HeroSearchPageState extends State<HeroSearchPage> {

  final ColorScheme palette;
  final String place;
  final settings;
  final recommend;
  final updateRec;
  final updateLocation;
  final favorites;
  final updateFav;
  final isTabletMode;
  final image;

  _HeroSearchPageState({required this.palette, required this.place, required this.settings,
    required this.recommend, required this.updateRec, required this.updateLocation, required this.favorites,
  required this.updateFav, required this.isTabletMode, required this.image});

  String text = "";
  bool isEditing = false;

  String locationState = "unknown";
  String locationMessage = "unknown";
  String placeName = "-";
  String country = "-";
  String region = "-";

  Timer? _debounce;
  late FocusNode focusNode;

  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      var result = await LocationService.getRecommendation(query, settings["Search provider"], settings);
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
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 20)
          )
      );
    } on TimeoutException {
      try {
        position = (await Geolocator.getLastKnownPosition())!;
    } on Error {
      setState(() {
        locationState = "disabled";
        locationMessage = AppLocalizations.of(context)!.unableToLocateDevice;
      });
      return "disabled";
    }
    } on LocationServiceDisabledException {
      setState(() {
        locationState = "disabled";
        locationMessage = AppLocalizations.of(context)!.locationServicesAreDisabled;
      });
      return "disabled";
    }

    try {

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        placeName = place.locality ?? "";
        country = place.isoCountryCode ?? "";
        region = place.administrativeArea ?? "";
        locationState = "enabled";
      });

    } on Error {
      setState(() {
        placeName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });
    }
  }

  askGrantLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationState = "disabled";
        locationMessage = AppLocalizations.of(context)!.locationServicesAreDisabled;
      });
      return "disabled";
    }
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationState = "deniedForever";
        locationMessage = AppLocalizations.of(context)!.locationPermissionDeniedForever;
      });
      return "disabled";
    }
    String x = await checkIflocationState(true);
    if (x == "enabled") {
      await findCurrentPosition();
    }
  }

  Future<String> checkIflocationState([bool afterAsk = false]) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationState = "disabled";
        locationMessage = AppLocalizations.of(context)!.locationServicesAreDisabled;
      });
      return "disabled";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationState = "deniedForever";
        locationMessage = AppLocalizations.of(context)!.locationPermissionDeniedForever;
      });
      return "disabled";
    }
    if (permission == LocationPermission.denied) {
      setState(() {
        locationState = "denied";
        locationMessage = AppLocalizations.of(context)!.locationPermissionIsDenied;
      });
      return "disabled";
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        locationState = "enabled";
      });
      return "enabled";
    }
    setState(() {
      locationState = "disabled";
      locationMessage = AppLocalizations.of(context)!.unableToLocateDevice;
    });
    return "disabled";
  }

  @override
  void initState() {
    super.initState();

    //this is to fix the wierd hero textField interaction
    //https://github.com/flutter/flutter/issues/106789
    focusNode = FocusNode();
    if (!isTabletMode) {
      Future.delayed(const Duration(milliseconds: 400), () {
        focusNode.requestFocus();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      checkIflocationState().then((x) {
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
    focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: isTabletMode ? palette.surfaceContainer : palette.surface,
      appBar: AppBar(
        backgroundColor: isTabletMode ? palette.surfaceContainer : palette.surface,
        foregroundColor: palette.primary,
        surfaceTintColor: palette.outlineVariant,
        elevation: 0,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: (text == "") ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(right: 13),
                child: IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.edit_outlined,
                    color: palette.primary, size: 25,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onIsEditingChanged();
                  },
                ),
              ),
            )
            : Container(),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(103),
          child: Hero(
            tag: 'searchBarHero',
            child: Container(
              height: 67,
              margin: const EdgeInsets.only(left: 27, right: 27, bottom: 20),
              decoration: BoxDecoration(
                  color: isTabletMode ? palette.surfaceContainerHighest : palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(33)
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Material(
                    color: isTabletMode ? palette.surfaceContainerHighest : palette.surfaceContainer,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: TextSelectionThemeData(
                          selectionHandleColor: palette.primary,
                        ),
                      ),
                      child: TextField(
                        focusNode: focusNode,
                        autofocus: false,
                        onChanged: (String to) async{
                          setState(() {
                            text = to;
                          });
                          _onSearchChanged(to);
                        },
                        onSubmitted: (String submission) {
                          HapticFeedback.lightImpact();
                          updateLocation('query', submission);
                          if (!isTabletMode) {
                            Navigator.pop(context);
                          }
                        },
                        cursorColor: palette.primary,
                        cursorWidth: 2,
                        style: GoogleFonts.outfit(
                          color: palette.onSurface,
                          fontSize: 23 * getFontSize(settings["Font size"]!),
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle:  GoogleFonts.outfit(
                            color: palette.outline,
                            fontSize: 20 * getFontSize(settings["Font size"]!),
                            fontWeight: FontWeight.w400,
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
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Align(
                key: ValueKey<bool>(text == ""),
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: buildRecommend(text, palette, settings, favorites, recommend,
                  updateLocation, onFavChanged, isEditing, locationState, locationMessage, askGrantLocationPermission,
                  placeName, country, region, isTabletMode),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget buildRecommend(String text, ColorScheme palette, settings, ValueListenable<List<String>> favoritesListen,
    ValueListenable<List<String>> recommend, updateLocation, onFavChanged, isEditing, locationState, locationMessage,
    askGrantLocationPermission, placeName, country, region, isTabletMode) {

  return ValueListenableBuilder(
    valueListenable: favoritesListen,
    builder: (context, value, child) {
      List<String> favorites = value;
      if (text == "") {
        return Padding(
          padding: const EdgeInsets.only(left: 30, top: 10, right: 30, bottom: 40),
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
                          Icons.gps_fixed, color: palette.outline, size: 17,),
                      ),
                      comfortatext(
                          AppLocalizations.of(context)!.currentLocation, 18, settings, color: palette.outline),
                    ],
                  ),
                  CurrentLocationWidget(settings, locationState, locationMessage, palette,
                      askGrantLocationPermission, placeName, country, region, updateLocation, context, isTabletMode),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 0),
                          child: Icon(
                            Icons.star_outline, color: palette.outline, size: 18,),
                        ),
                        comfortatext(AppLocalizations.of(context)!.favoritesLowercase, 18, settings, color: palette.outline),
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
                      child: favoritesOrReorder(isEditing, favorites, settings, onFavChanged, palette, updateLocation, context, isTabletMode),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
      else {
        return buildSearchResults(favorites, recommend, palette, updateLocation, onFavChanged, settings, isTabletMode);
      }
    }
  );
}

Widget buildSearchResults(List<String> favorites, ValueListenable<List<String>> recommend, ColorScheme palette, updateLocation,
    onFavChanged, settings, isTabletMode) {
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
              top: 0, bottom: 30, left: 30, right: 30),
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
                      color: isTabletMode ? palette.surfaceContainerHighest : palette.surfaceContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: rec.isEmpty
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.all(14),
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
                              if (!isTabletMode) {
                                Navigator.pop(context);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 7, top: 5, bottom: 5),
                              child:
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                        crossAxisAlignment : CrossAxisAlignment.start,
                                        children: [
                                          comfortatext(name, 19, settings, color: palette.onSurface),
                                          comfortatext("$region, $country", 15, settings, color: palette.outline)
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
                                      color: palette.primary, size: 24,
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

Widget CurrentLocationWidget(settings, locationState, locationMessage, ColorScheme palette, askGrantLocationPermission,
    String placeName, String country, String region, updateLocation, context, isTabletMode) {
  if (locationState == "denied") {
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
          color: palette.primaryFixedDim,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_fixed,
              color: palette.onPrimaryFixedVariant, size: 19,),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 2),
                child: comfortatext(
                    AppLocalizations.of(context)!.grantLocationPermission, 19, settings,
                      color: palette.onPrimaryFixedVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
  if (locationState == "enabled") {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        updateLocation('40.7128, -74.0060', 'CurrentLocation'); // this is new york for backup
        if (!isTabletMode) {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 14, bottom: 30),
        padding: const EdgeInsets.only(
            left: 25, right: 25, top: 20, bottom: 20),
        decoration: BoxDecoration(
          color: palette.primaryFixedDim,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Expanded(
                child: Column(
                  crossAxisAlignment : CrossAxisAlignment.start,
                  children: [
                    comfortatext(placeName, 20, settings, color: palette.onPrimaryFixed),
                    comfortatext("$region, $country", 15, settings, color: palette.onPrimaryFixed)
                  ],
                )
            ),
            Icon(Icons.keyboard_arrow_right_rounded,
              color: palette.onPrimaryFixed,)
          ],
        ),
      ),
    );
  }
  return Container(
    margin: const EdgeInsets.only(top: 20, bottom: 30),
    padding: const EdgeInsets.only(
        left: 25, right: 25, top: 20, bottom: 20),
    decoration: BoxDecoration(
      color: palette.primaryFixedDim,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      children: [
        Icon(Icons.gps_off,
          color: palette.onPrimaryFixedVariant, size: 19,),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: comfortatext(
                locationMessage, 19, settings,
                color: palette.onPrimaryFixedVariant),
          ),
        ),

      ],
    ),
  );
}

Widget favoritesOrReorder(isEditing, favorites, settings, onFavChanged,
    ColorScheme palette, updateLocation, context, isTabletMode) {
  if (isEditing) {
    return reorderFavorites(favorites, settings, onFavChanged, palette, isTabletMode);
  }
  else {
    return buildFavorites(palette, favorites, updateLocation, settings, context, isTabletMode);
  }
}

Widget buildFavorites(ColorScheme palette, List<String> favorites, updateLocation, settings, context, isTabletMode) {
  return SingleChildScrollView(
    child: Container(
        key: const ValueKey<String>("normal"),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isTabletMode ? palette.surfaceContainerHighest : palette.surfaceContainer,
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
                  if (!isTabletMode) {
                    Navigator.pop(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 7, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                            crossAxisAlignment : CrossAxisAlignment.start,
                            children: [
                              comfortatext(name, 19, settings, color: palette.onSurface),
                              comfortatext("$region, $country", 15, settings, color: palette.outline)
                            ],
                          )
                      ),
                      Icon(Icons.keyboard_arrow_right_rounded, color: palette.primary,)
                    ],
                  ),
                ),
              );
            })
        )
    ),
  );
}

Widget reorderFavorites(_items, settings, onFavChanged, ColorScheme palette, isTabletMode) {
  return Container(
    key: const ValueKey<String>("editing"),
    decoration: BoxDecoration(
      color: isTabletMode ? palette.surfaceContainerHighest : palette.surfaceContainer,
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
          reorderableItem(_items, index, settings, palette, onFavChanged, isTabletMode)
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

Widget reorderableItem(List<dynamic> items, index, settings, ColorScheme palette, onFavChanged, isTabletMode) {
  var split = json.decode(items[index]);
  String name = split["name"];
  String country = generateAbbreviation(split["country"]);
  String region = split["region"];
  return Container(
    key: Key("$name, $country, $region"),
    color: isTabletMode ? palette.surfaceContainerHighest : palette.surfaceContainer,
    child: Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 4, bottom: 4),
      child:
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.drag_indicator, color: palette.outline,),
          ),
          Expanded(
              child: Column(
                crossAxisAlignment : CrossAxisAlignment.start,
                children: [
                  comfortatext(name, 19, settings, color: palette.onSurface),
                  comfortatext("$region, $country", 15, settings, color: palette.outline)
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
              color: palette.primary, size: 23,
            ),
          )
        ],
      ),
    ),
  );
}