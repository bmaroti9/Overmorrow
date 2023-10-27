import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/settings_page.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

import 'dayforcast.dart';

Widget searchBar(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Function updateRec, String place, var context,
    bool prog, Function updateProg) {

  return FloatingSearchBar(
      hint: 'Search...',
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

      borderRadius: BorderRadius.circular(102),
      backgroundColor: color,
      border: const BorderSide(width: 1.2, color: WHITE),
      progress: prog,
      accentColor: WHITE,

      elevation: 0,
      height: 60,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      debounceDelay: const Duration(milliseconds: 500),

      controller: controller,

      onQueryChanged: (query) async {
        isEditing = false;
        var result = await getRecommend(query, favorites);
        updateRec(result);
      },
      onSubmitted: (submission) {
        isEditing = false;
        updateLocation(submission); // Call the callback to update the location
        controller.close();
      },

      insets: EdgeInsets.zero,
      padding: const EdgeInsets.only(left: 13),
      iconColor: WHITE,
      backdropColor: darken(color, 0.5),
      closeOnBackdropTap: true,
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 3),
            child: LocationButton(updateProg, updateLocation, color),
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
                favorites, controller.query)
        );
      }
  );
}

Widget decideSearch(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, String entered) {

  if (entered == '') {
    return defaultSearchScreen(color, updateLocation,
        controller, updateIsEditing, isEditing, updateFav, favorites);
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
    List<String> favorites) {

  List<Icon> Myicon = [
    const Icon(null),
    const Icon(Icons.close, color: WHITE,),
  ];

  Icon editIcon = const Icon(Icons.icecream, color: WHITE,);
  Color rectColor = WHITE;
  List<int> icons = [];
  if (isEditing) {
    for (String _ in favorites) {
      icons.add(1);
    }
    editIcon = const Icon(Icons.check, color: WHITE,);
    rectColor = Color(0xffce5a67);
  }
  else{
    for (String _ in favorites) {
      icons.add(0);
    }
    editIcon = const Icon(Icons.edit, color: WHITE,);
    rectColor = color;
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top:5, bottom: 10, right: 20, left: 20),
        child: Row(
          children: [
            comfortatext('Favorites', 30, color: WHITE),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(turns: animation,
                      child: child);
                },
              child: Container(
                key: ValueKey<Icon>(editIcon),
                decoration: BoxDecoration(
                  color: rectColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(onPressed: () {
                  updateIsEditing(!isEditing);
                },
                  icon: editIcon,
                ),
              ),
            ),
          ],
        ),
      ),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation,
            alignment: Alignment.topCenter, child: child,);
          },
          child: Container(
            key: ValueKey<Color>(rectColor),
            padding: const EdgeInsets.only(top:10, bottom: 10),
            decoration: BoxDecoration(
              color: rectColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 0),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    updateLocation(favorites[index]);
                    controller.close();
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, bottom: 0, right: 10),
                    child: Row(
                      children: [
                        comfortatext(favorites[index], 27, color: WHITE),
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
                                favorites.remove(favorites[index]);
                                updateFav(favorites);
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
        return GestureDetector(
          onTap: () {
            updateLocation(recommend[index]);
            controller.close();
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20, bottom: 3,
                  right: 10, top: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recommend[index],
                    style: GoogleFonts.comfortaa(
                      color: WHITE,
                      fontSize: 25,
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    maxLines: 3,
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

Widget LocationButton(Function updateProg, Function updateLocation, Color color) {
  if (LOCATION == 'CurrentLocation') {
    return ElevatedButton(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all<double>(0),
        shape: MaterialStateProperty.all(const CircleBorder()),
        padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
        backgroundColor: MaterialStateProperty.all(WHITE),
        // <-- Button color
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) {
            return const Color(0xffce5a67);
          }
          return null; // <-- Splash color
        }),
      ),
      onPressed: null,
      child: Icon(Icons.place_rounded, color: color,),
    );
  }
  else{
    return ElevatedButton(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all<double>(0),
        shape: MaterialStateProperty.all(const CircleBorder()),
        padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
        backgroundColor: MaterialStateProperty.all(color),
        side: MaterialStateProperty.resolveWith<BorderSide>(
          (states) => const BorderSide(width: 1.2, color: WHITE)),
      ),
      onPressed: () async {
        print('pressed');
        if (await isLocationSafe()) {
          updateLocation('CurrentLocation');
        }
      },
      child: const Icon(Icons.place_outlined, color: WHITE,),
    );
  }
}

class dumbySearch extends StatelessWidget {
  final errorMessage;
  final updateLocation;
  final place;
  final icon;

  const dumbySearch({super.key, required this.errorMessage,
    required this.updateLocation, required this.icon, required this.place});

  @override
  Widget build(BuildContext context) {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;
    double safeHeight = size.height;
    return Scaffold(
      backgroundColor: darken(const Color(0xffB1D2E1), 0.4),
      body: RefreshIndicator(
        onRefresh: () async {
          await updateLocation(LOCATION);
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
                              errorMessage,
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
                    color: BLACK, place: place,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}