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

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/weather_refact.dart';

import '../api_key.dart';
import '../caching.dart';

String backdropCorrection(String text) {
  return textBackground[text] ?? 'clear_sky3.jpg';
}

List<String> assetImageCredit(String name){
  return assetPhotoCredits[name] ?? ["", "", ""];
}

class ImageService {
  final Image image;
  final String username;
  final String userlink;
  final String photolink;

  const ImageService({
    required this.image,
    required this.username,
    required this.userlink,
    required this.photolink,
  });

  static Future<ImageService> getUnsplashCollectionImage(String condition, String loc) async {

    String collectionId = conditionToCollection[condition] ?? 'XMGA2-GGjyw';

    final params = {
      'client_id': access_key,
      'collections': collectionId,
      'content_filter' : 'high',
      'count': '1',
    };

    final url = Uri.https('api.unsplash.com', 'photos/random', params);

    var file = await XCustomCacheManager.fetchData(url.toString(), "$condition $loc unsplash");
    var response2 = await file[0].readAsString();
    var unsplashBody = jsonDecode(response2);

    final String image_path = unsplashBody[0]["urls"]["raw"] + "&w=1500";
    Image image = Image(image: CachedNetworkImageProvider(image_path), fit: BoxFit.cover,
      width: double.infinity, height: double.infinity);

    final String _userLink = (unsplashBody[0]["user"]["links"]["html"]) ?? "";
    final String _userName = unsplashBody[0]["user"]["name"] ?? "";

    final String _photoLink = unsplashBody[0]["links"]["html"] ?? "";

    return ImageService(
        image: image,
        username: _userName,
        userlink: _userLink,
        photolink: _photoLink,
    );
  }

  static ImageService getAssetImage(String condition) {

    final String imagePath = backdropCorrection(condition);
    final Image image = Image.asset("assets/backdrops/$imagePath", fit: BoxFit.cover,
      width: double.infinity, height: double.infinity,);
    final List<String> credits = assetImageCredit(condition);

    final String _photoLink = credits[0];
    final String _userName = credits[1];
    final String _userLink = credits[2];

    return ImageService(
      image: image,
      username: _userName,
      userlink: _userLink,
      photolink: _photoLink,
    );

  }

  static Future<ImageService> getImageService(String condition, String loc, String imageSource) async {

    if (imageSource == "network") {
      try {
        //ImageService i = await getUnsplashImage(condition, loc);
        ImageService i = await getUnsplashCollectionImage(condition, loc);
        return i;
      }
      catch (e) {
        String error = e.toString().replaceAll(access_key, "<key>");
        if (kDebugMode) {
          print(error);
        }
        return getAssetImage(condition);
      }
    }
    else {
      return getAssetImage(condition);
    }
  }

}

class FadingImageWidget extends StatelessWidget {
  final Image? image;

  const FadingImageWidget({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey(image.hashCode),
              child: (image == null)
                  ? Container(color: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,)
                  : image,
            ),
          ),
          //Add a slight tint to make the text more legible
          Container(color: const Color.fromARGB(30, 0, 0, 0),)
        ]
    );
  }
}