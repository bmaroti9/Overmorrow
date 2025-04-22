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
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
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
    required this.photolink
  });

  static Future<ImageService> getUnsplashImage(String condition, String loc) async {

    String combined = textToUnsplashText[condition]?.join(" ") ?? "Weather";

    print(combined);

    final params = {
      'client_id': access_key,
      'query' : combined,
      'content_filter' : 'high',
      'count': '6',
    };

    final url = Uri.https('api.unsplash.com', 'photos/random', params);

    var file = await XCustomCacheManager.fetchData(url.toString(), "$condition $loc unsplash");
    var response2 = await file[0].readAsString();
    var unsplashBody = jsonDecode(response2);

    int bestScore = -1000000;
    int bestIndex = 0;

    for (int i = 0; i < unsplashBody.length; i++) {

    }

    final String image_path = unsplashBody[bestIndex]["urls"]["regular"];
    Image image = Image(image: CachedNetworkImageProvider(image_path), fit: BoxFit.cover,
      width: double.infinity, height: double.infinity,);


    final String _userLink = (unsplashBody[bestIndex]["user"]["links"]["html"]) ?? "";
    final String _userName = unsplashBody[bestIndex]["user"]["name"] ?? "";

    final String _photoLink = unsplashBody[bestIndex]["links"]["html"] ?? "";

    return ImageService(
      image: image,
      username: _userName,
      userlink: _userLink,
      photolink: _photoLink
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
      photolink: _photoLink
    );

  }

  static Future<ImageService> getImageService(String condition, String loc, settings) async {

    if (settings["Image source"] == "network") {
      try {
        ImageService i = await getUnsplashImage(condition, loc);
        return i;
      }
      catch (e) {
        String error = e.toString().replaceAll(access_key, "<key>");
        print(error);
        return getAssetImage(condition);
      }

    }
    else {
      return getAssetImage(condition);
    }
  }

}