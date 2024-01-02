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
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/settings_page.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

import 'api_key.dart';

Widget searchBar(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Function updateRec, String place, var context,
    bool prog, Function updateProg, List<String> settings, String real_loc) {

  return FloatingSearchBar(
      hint: translation('Search...', settings[0]),
      title: Container(
        padding: const EdgeInsets.only(left: 10, top: 3),
        child: Text(
          place,
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

      borderRadius: BorderRadius.circular(27),
      backgroundColor: color,
      border: const BorderSide(width: 1.2, color: WHITE),
      accentColor: WHITE,

      elevation: 0,
      height: 62,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      debounceDelay: const Duration(milliseconds: 500),

      controller: controller,

      onQueryChanged: (query) async {
        isEditing = false;
        var result = await getRecommend(query);
        updateRec(result);
      },
      onSubmitted: (submission) {
        isEditing = false;
        updateLocation('search', submission); // Call the callback to update the location
        controller.close();
      },

      insets: EdgeInsets.zero,
      automaticallyImplyDrawerHamburger: false,
      padding: const EdgeInsets.only(left: 13),
      iconColor: WHITE,
      backdropColor: darken(color, 0.2),
      closeOnBackdropTap: true,
      transition: CircularFloatingSearchBarTransition(),
      automaticallyImplyBackButton: false,
      leadingActions: [
        FloatingSearchBarAction(
          showIfOpened: true,
          showIfClosed: false,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircularButton(
              icon: const Icon(Icons.arrow_back_outlined, color: WHITE,),
              onPressed: () {
                controller.close();
              },
            ),
          ),
        ),
        FloatingSearchBarAction(
          showIfOpened: false,
          showIfClosed: true,
          child: IconButton(
            icon: const Icon(Icons.menu, color: WHITE, size: 28,),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ],
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 3),
            child: LocationButton(updateProg, updateLocation, color, real_loc),
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
                icon: const Icon(Icons.close, color: WHITE,),
                onPressed: () {
                  controller.clear();
                },
              ),
            ),
          ),
        ),
      ],
      builder: (context, transition) {
        return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(sizeFactor: animation, child: child);
            },
            child: decideSearch(color, recommend, updateLocation,
                controller, updateIsEditing, isEditing, updateFav,
                favorites, controller.query, settings)
        );
      }
  );
}

Widget decideSearch(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, String entered, List<String> settings) {

  if (entered == '') {
    return defaultSearchScreen(color, updateLocation,
        controller, updateIsEditing, isEditing, updateFav, favorites, settings);
  }
  else{
    if (recommend.isNotEmpty) {
      return recommendSearchScreen(
          color, recommend, updateLocation, controller,
          favorites, updateFav);
    }
  }
  return Container();
}

Widget defaultSearchScreen(Color color,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, List<String> settings) {

  List<Icon> Myicon = [
    const Icon(null),
    Icon(Icons.close, color: color,),
  ];

  Icon editIcon = const Icon(Icons.icecream, color: WHITE,);
  Color rectColor = WHITE;
  Color textColor;
  List<int> icons = [];
  if (isEditing) {
    for (String _ in favorites) {
      icons.add(1);
    }
    editIcon = Icon(Icons.check, color: color,);
    rectColor = WHITE;
    textColor = color;
  }
  else{
    for (String _ in favorites) {
      icons.add(0);
    }
    editIcon = Icon(Icons.edit, color: color,);
    rectColor = color;
    textColor = WHITE;
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top:5, bottom: 10, right: 20, left: 20),
        child: Row(
          children: [
            comfortatext(translation("Favorites", settings[0]), 30, color: WHITE),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child,);
              },
              child: SizedBox(
                key: ValueKey<bool> (isEditing),
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.all(10),
                      backgroundColor: WHITE,
                      side: const BorderSide(width: 1.2, color: WHITE),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                      )
                  ),
                  onPressed: () async {
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
              borderRadius: BorderRadius.circular(25),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                var split = json.decode(favorites[index]);
                //var split = favorites[index].split("/");
                return GestureDetector(
                  onTap: () {
                    updateLocation('${split["lat"]}, ${split["lon"]}', split["name"]);
                    controller.close();
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, bottom: 2, right: 10, top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              comfortatext(split["name"], 26, color: textColor),
                              comfortatext(split["region"] + ", " +  generateAbbreviation(split["country"]), 17, color: textColor)
                              //comfortatext(split[0], 23)
                            ],
                          ),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: IconButton(
                              key: ValueKey<int>(icons[index]),
                              icon: Myicon[icons[index]],
                              onPressed: () {
                                if (isEditing) {
                                  favorites.remove(favorites[index]);
                                  updateFav(favorites);
                                }
                              },
                            )
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
}

Widget recommendSearchScreen(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller, List<String> favorites,
    Function updateFav) {
  List<Icon> icons = [];

  for (String n in recommend) {
    if (favorites.contains(n)) {
      icons.add(const Icon(Icons.favorite, color: WHITE,),);
    }
    else{
      icons.add(const Icon(Icons.favorite_border, color: WHITE,),);
    }
  }

  return Container(
    key: ValueKey<int>(recommend.length),
    padding: const EdgeInsets.only(top:10, bottom: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(25),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 0),
      itemCount: recommend.length,
      itemBuilder: (context, index) {
        var split = json.decode(recommend[index]);
        //var split = recommend[index].split("/");
        return GestureDetector(
          onTap: () {
            updateLocation('${split["lat"]}, ${split["lon"]}', split["name"]);
            controller.close();
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20, bottom: 3,
                  right: 10, top: 3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      comfortatext(split["name"], 26),
                      comfortatext(split["region"] + ", " +  generateAbbreviation(split["country"]), 17)
                      //comfortatext(split[0], 23)
                    ],
                  ),
                ),

                IconButton(onPressed: () {
                  if (favorites.contains(recommend[index])) {
                    favorites.remove(recommend[index]);
                    updateFav(favorites);
                  }
                  else{
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

Widget LocationButton(Function updateProg, Function updateLocation, Color color, String real_loc) {
  if (real_loc == 'CurrentLocation') {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 3, bottom: 3),
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.all(10),
              backgroundColor: WHITE,
              side: const BorderSide(width: 1.2, color: WHITE),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)
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
              side: const BorderSide(width: 1.2, color: WHITE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            )
          ),
          onPressed: () async {
            updateLocation('40.7128, 74.0060', 'CurrentLocation');
          },                   //^ this is new york for backup
          child: const Icon(Icons.place_outlined, color: WHITE,),
        ),
      ),
    );
  }
}

class dumbySearch extends StatelessWidget {
  final errorMessage;
  final updateLocation;
  final place;
  final icon;
  final settings;

  dumbySearch({super.key, required this.errorMessage,
    required this.updateLocation, required this.icon, required this.place,
  required this.settings});

  final Color color = const Color(0xffB1D2E1);

  final FloatingSearchBarController controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext context) {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;
    double safeHeight = size.height;

    const replacement = "<api_key>";
    String newStr = errorMessage.toString().replaceAll(wapi_Key, replacement);
    //String newStr = newStr2.replaceAll(owm_Key, replacement);

    return Scaffold(
      drawer: MyDrawer(color: color, settings: settings),
      backgroundColor: darken(color, 0.4),
      body: RefreshIndicator(
        onRefresh: () async {
          await updateLocation(place);
        },
        backgroundColor: WHITE,
        color: BLACK,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              automaticallyImplyLeading: false, // remove the hamburger-menu
              bottom: PreferredSize(
                preferredSize: Size(0, 70),
                child: Container(),
              ),
              backgroundColor: Colors.transparent,
              pinned: false,
              expandedHeight: safeHeight,
              flexibleSpace: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 200),
                    child: Center(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: icon,
                          ),
                          SizedBox(
                            width: 250,
                            child: Center(child: Text(
                              newStr,
                              style: const TextStyle(
                                color: WHITE,
                                fontSize: 21,
                              ),
                              textAlign: TextAlign.center,
                            ))
                          )
                        ],
                      ),
                    ),
                  ),
                  MySearchParent(updateLocation: updateLocation,
                    color: darken(color, 0.5), place: place, controller: controller, settings: settings,
                  real_loc: place,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}