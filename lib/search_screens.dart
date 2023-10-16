import 'package:flutter/material.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

Widget defaultSearchScreen(Color color, List<dynamic> recommend,
    Function updateLocation, FloatingSearchBarController _controller) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top:5, bottom: 10, right: 20, left: 20),
        child: Row(
          children: [
            comfortatext('Favorites', 30, color: WHITE),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(onPressed: () {},
                icon: const Icon(Icons.edit, color: WHITE,),
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.only(top:10, bottom: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 12),
          itemCount: recommend.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                updateLocation(recommend[index]);
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
    ],
  );
}

Widget recommendSearchScreen(Color color, List<dynamic> recommend,
    Function updateLocation, FloatingSearchBarController _controller) {
  return Container(
    padding: const EdgeInsets.only(top:10, bottom: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(25),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 12),
      itemCount: recommend.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            updateLocation(recommend[index]);
            _controller.close();
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20, bottom: 12),
            child: comfortatext(recommend[index], 27, color: WHITE),
          ),
        );
      },
    ),
  );
}