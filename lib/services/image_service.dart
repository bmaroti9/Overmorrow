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
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/color_service.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/weather_refact.dart';
import 'package:provider/provider.dart';

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
    final Color color =  Color(getColorFromHex(unsplashBody[0]["color"]));

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
    final Color color = Colors.amber;

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

class ParrallaxBackground extends StatelessWidget {
  final Image image;
  final Color color;

  const ParrallaxBackground({Key? key, required this.image, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0, end: 1.0),
      curve: Curves.decelerate,
      builder: (context, value, child) {
        return Container(
          color: color,
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 1.0 + (0.1 * value),
              child: image,
            ),
          ),
        );
      },
    );
  }
}

class FadingImageWidget extends StatefulWidget {
  final Function updateColorPalette;
  final String imageSource;
  final String condition;
  final String loc;

  const FadingImageWidget({
    super.key,
    required this.updateColorPalette,
    required this.imageSource,
    required this.condition,
    required this.loc,
  });

  @override
  State<FadingImageWidget> createState() => FadingImageWidgetState();
}

class FadingImageWidgetState extends State<FadingImageWidget> {
  Image? _currentImage;

  //i tried multiple times to move out this logic from here,
  //but every time i tried it became a lot more laggy and buggy i don't know why
  //so in the end i just kept it here
  Future<ImageService> updateImage() async {

    ImageService imageService = await ImageService.getImageService(widget.condition, widget.loc, widget.imageSource);

    print("image fetched");

    ImageProvider imageProvider = imageService.image.image;

    ColorScheme colorSchemeLight = await ColorScheme.fromImageProvider(
      provider: imageProvider,
      brightness: Brightness.light,
    );
    ColorScheme colorSchemeDark = await ColorScheme.fromImageProvider(
      provider: imageProvider,
      brightness: Brightness.dark,
    );

    setState(() {
      _currentImage = imageService.image;
    });

    await widget.updateColorPalette(colorSchemeLight, colorSchemeDark);

    return imageService;
  }

  @override
  void didUpdateWidget(covariant FadingImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageSource != oldWidget.imageSource) {
      updateImage();
    }
  }

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
            key: ValueKey(_currentImage.hashCode),
            child: (_currentImage == null)
                ? Container(color: Theme.of(context).colorScheme.inverseSurface,)
                : _currentImage,
          ),
        ),
        //Add a slight tint to make the text more legible
        Container(color: const Color.fromARGB(30, 0, 0, 0),)
      ]
    );
  }
}