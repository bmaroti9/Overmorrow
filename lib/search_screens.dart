import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

Widget searchBar(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController _controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, Function updateRec, var data) {

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

      onQueryChanged: (query) async {
        isEditing = false;
        var result = await getRecommend(query, favorites);
        updateRec(result);
      },
      onSubmitted: (submission) {
        isEditing = false;
        updateLocation(submission); // Call the callback to update the location
        _controller.close();
      },

      iconColor: WHITE,
      backdropColor: darken(color, 0.5),
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
              _controller.clear();
            },
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
                _controller, updateIsEditing, isEditing, updateFav,
                favorites, _controller.query)
        );
      }
  );
}

Widget decideSearch(Color color, List<String> recommend,
    Function updateLocation, FloatingSearchBarController _controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites, String entered) {

  if (entered == '') {
    return defaultSearchScreen(color, updateLocation,
        _controller, updateIsEditing, isEditing, updateFav, favorites);
  }
  else{
    if (recommend.isNotEmpty) {
      return recommendSearchScreen(
          color, recommend, updateLocation, _controller,
          favorites, updateFav);
    }
  }
  return Container();
}

Widget defaultSearchScreen(Color color,
    Function updateLocation, FloatingSearchBarController _controller,
    Function updateIsEditing, bool isEditing, Function updateFav,
    List<String> favorites) {

  List<Icon> Myicon = [
    const Icon(null),
    const Icon(Icons.close, color: WHITE,),
  ];

  Icon edit_icon = const Icon(Icons.icecream, color: WHITE,);
  Color rect_color = WHITE;
  List<int> icons = [];
  if (isEditing) {
    for (String _ in favorites) {
      icons.add(1);
    }
    edit_icon = const Icon(Icons.check, color: WHITE,);
    rect_color = Colors.orangeAccent;
  }
  else{
    for (String _ in favorites) {
      icons.add(0);
    }
    edit_icon = const Icon(Icons.edit, color: WHITE,);
    rect_color = color;
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top:5, bottom: 10, right: 20, left: 20),
        child: Row(
          children: [
            comfortatext('Favorites', 30, color: WHITE),
            Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(turns: animation,
                      child: child);
                },
              child: Container(
                key: ValueKey<Icon>(edit_icon),
                decoration: BoxDecoration(
                  color: rect_color,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(onPressed: () {
                  updateIsEditing(!isEditing);
                },
                  icon: edit_icon,
                ),
              ),
            ),
          ],
        ),
      ),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child,
            alignment: Alignment.topCenter,);
          },
          child: Container(
            key: ValueKey<Color>(rect_color),
            padding: const EdgeInsets.only(top:10, bottom: 10),
            decoration: BoxDecoration(
              color: rect_color,
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
                    _controller.close();
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
    Function updateLocation, FloatingSearchBarController _controller, List<String> favorites,
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
            _controller.close();
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