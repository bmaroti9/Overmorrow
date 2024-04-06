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

import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/main_ui.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

import 'api_key.dart';

Widget searchBar(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Function updateRec, String place, var context,
    bool prog, Function updateProg, Map<String, String> settings, String real_loc, Color secondColor, 
    Color textColor) {

  return FloatingSearchBar(
      hint: translation('Search...', settings["Language"]!),
      title: Container(
        padding: const EdgeInsets.only(left: 5, top: 3),
        child: comfortatext(place, 28 * getFontSize(settings["Font size"]!), settings, color: textColor)
      ),
      hintStyle: GoogleFonts.comfortaa(
        color: textColor,
        fontSize: 18 * getFontSize(settings["Font size"]!),
        fontWeight: FontWeight.w100,
      ),

      queryStyle: GoogleFonts.comfortaa(
        color: textColor,
        fontSize: 22 * getFontSize(settings["Font size"]!),
        fontWeight: FontWeight.w100,
      ),

      margins: EdgeInsets.only(left: 10, right: 10, top: MediaQuery.of(context).padding.top + 15),

      borderRadius: BorderRadius.circular(23),
      backgroundColor: color,
      //border: const BorderSide(width: 1.2, color: WHITE),
      accentColor: secondColor,

      elevation: 0,
      height: 60,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      debounceDelay: const Duration(milliseconds: 500),

      controller: controller,
      width: 800,

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
      iconColor: secondColor,
      backdropColor: darken(color, 0.2),
      closeOnBackdropTap: true,
      transition: SlideFadeFloatingSearchBarTransition(),
      automaticallyImplyBackButton: false,
      leadingActions: [
        FloatingSearchBarAction(
          showIfOpened: true,
          showIfClosed: false,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircularButton(
              icon: Icon(Icons.arrow_back_outlined, color: secondColor),
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
            icon: Icon(Icons.menu, color: secondColor, size: 26,),
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
            child: Visibility(
              visible: !Platform.isLinux,
              child: LocationButton(updateProg, updateLocation, color, real_loc, secondColor,
              textColor)
            ),
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
                icon: Icon(Icons.close, color: textColor,),
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
                favorites, controller.query, settings, textColor)
        );
      }
  );
}

Widget decideSearch(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, String entered, Map<String, String> settings, textColor) {

  if (entered == '') {
    return defaultSearchScreen(color, updateLocation,
        controller, updateIsEditing, isEditing, updateFav, favorites, settings, textColor);
  }
  else{
    if (recommend.isNotEmpty) {
      return recommendSearchScreen(
          color, recommend, updateLocation, controller,
          favorites, updateFav, settings, textColor);
    }
  }
  return Container();
}

Widget defaultSearchScreen(Color color,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Map<String, String> settings, textColor) {

  List<Icon> Myicon = [
    const Icon(null),
    Icon(Icons.close, color: color,),
  ];

  Icon editIcon = const Icon(Icons.icecream, color: WHITE,);
  Color rectColor = textColor;
  Color text = textColor;
  List<int> icons = [];
  if (isEditing) {
    for (String _ in favorites) {
      icons.add(1);
    }
    editIcon = Icon(Icons.check, color: color,);
    rectColor = textColor;
    text = color;
  }
  else{
    for (String _ in favorites) {
      icons.add(0);
    }
    editIcon = Icon(Icons.edit, color: textColor,);
    rectColor = color;
    text = textColor;
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top:5, bottom: 10, right: 20, left: 20),
        child: Row(
          children: [
            comfortatext(translation("Favorites", settings["Language"]!), 26 * getFontSize(settings["Font size"]!),
                settings, color: WHITE),
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
                      padding: const EdgeInsets.all(6),
                      backgroundColor: rectColor,
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
              borderRadius: BorderRadius.circular(20),
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
                    updateLocation('${split["lat"]}, ${split["lon"]}', split["name"]);
                    controller.close();
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, bottom: 3, right: 10, top: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              comfortatext(split["name"], 25 * getFontSize(settings["Font size"]!), settings,
                                  color: text),
                              comfortatext(split["region"] + ", " +  generateAbbreviation(split["country"]), 18
                                  * getFontSize(settings["Font size"]!), settings, color: text)
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Myicon[icons[index]],
                          onPressed: () {
                            if (isEditing) {
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
}

Widget recommendSearchScreen(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller, List<String> favorites,
    Function updateFav, var settings, textColor) {
  List<Icon> icons = [];

  for (String n in recommend) {
    if (favorites.contains(n)) {
      icons.add(Icon(Icons.favorite, color: textColor,),);
    }
    else{
      icons.add(Icon(Icons.favorite_border, color: textColor,),);
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
                      comfortatext(split["name"], 25 * getFontSize(settings["Font size"]),
                          settings, color: textColor),
                      comfortatext(split["region"] + ", " +  generateAbbreviation(split["country"]), 18 * getFontSize(settings["Font size"]),
                          settings, color: textColor)
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

Widget LocationButton(Function updateProg, Function updateLocation, Color color, String real_loc,
    Color secondColor, Color textColor) {
  if (real_loc == 'CurrentLocation') {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 3, bottom: 3),
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.all(10),
              backgroundColor: textColor,
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
              side: BorderSide(width: 1.5, color: textColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            )
          ),
          onPressed: () async {
            updateLocation('40.7128, 74.0060', 'CurrentLocation');
          },                   //^ this is new york for backup
          child: Icon(Icons.place_outlined, color: secondColor,),
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
  final provider;
  final latlng;

  dumbySearch({super.key, required this.errorMessage,
    required this.updateLocation, required this.icon, required this.place,
  required this.settings, required this.provider, required this.latlng});

  final Color color = instantBackColor == WHITE ? const Color(0xff201F2D) : instantBackColor;

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
      drawer: MyDrawer(primary: color, settings: settings,
      back: WHITE),
      backgroundColor: color,
      body: RefreshIndicator(
        onRefresh: () async {
          await updateLocation(latlng, place);
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
              expandedHeight: safeHeight - 100,
              backgroundColor: Colors.transparent,
              pinned: false,
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
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 800),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: WHITE, width: 1.2)
                              ),
                              child: Column(
                                children: [
                                  comfortatext(translation('Weather provider', settings["Language"]), 18, settings),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, right: 20),
                                    child: DropdownButton(
                                      underline: Container(),
                                      borderRadius: BorderRadius.circular(20),
                                      icon: const Padding(
                                        padding: EdgeInsets.only(left:5),
                                        child: Icon(Icons.arrow_drop_down_circle, color: WHITE,),
                                      ),
                                      style: GoogleFonts.comfortaa(
                                        color: WHITE,
                                        fontSize: 20 * getFontSize(settings["Font size"]),
                                        fontWeight: FontWeight.w300,
                                      ),
                                      //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
                                      value: provider.toString(),
                                      items: ['weatherapi.com', 'open-meteo'].map((item) {
                                        return DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        );
                                      }).toList(),
                                      onChanged: (String? value) async {
                                        SetData('weather_provider', value!);
                                        await updateLocation(latlng, place);
                                      },
                                      isExpanded: true,
                                      dropdownColor: darken(color, 0.1),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  MySearchParent(updateLocation: updateLocation,
                    color: color, place: place, controller: controller, settings: settings,
                  real_loc: place, secondColor: WHITE, textColor: WHITE,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}