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

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RadarMap extends StatefulWidget {

  final data;

  const RadarMap({Key? key, required this.data}) : super(key: key);

  @override
  _RadarMapState createState() => _RadarMapState(data);
}

class _RadarMapState extends State<RadarMap> {
  int currentFrameIndex = 0;
  late Timer timer;

  final data;
  _RadarMapState(this.data);
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(milliseconds: 1500), (Timer t) {
      if (isPlaying) {
        setState(() {
          currentFrameIndex =
              ((currentFrameIndex + 1) % data.radar.images.length).toInt();
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, bottom: 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(translation('radar', data.settings["Language"]), 19, data.settings,
            color: data.current.textcolor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                  color: WHITE,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(width: 1.2, color: data.current.secondary)
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      options: MapOptions(
                        onTap: (tapPosition, point) => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RadarPage(data: data,)),
                          )
                        },
                        initialCenter: LatLng(data.lat, data.lng),
                        initialZoom: 6,
                        backgroundColor: WHITE,
                        keepAlive: true,
                        maxZoom: 6,
                        minZoom: 6,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation),
                        cameraConstraint: CameraConstraint.containCenter(
                          bounds: LatLngBounds(
                            LatLng(data.lat - 3, data.lng - 3),
                            LatLng(data.lat + 3, data.lng + 3),
                          ),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: data.settings["Color theme"] == "dark"
                              ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
                        ),
                        TileLayer(
                          urlTemplate: data.radar.images[currentFrameIndex] + "/256/{z}/{x}/{y}/8/1_1.png",
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Hero(
                        tag: 'switch',
                        child: SizedBox(
                          height: 48,
                          width: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 10,
                              padding: const EdgeInsets.all(10),
                              backgroundColor: data.current.backcolor,
                              //side: BorderSide(width: 3, color: main),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RadarPage(data: data,)),
                              );
                            },
                            child: Icon(Icons.open_in_full, color: data.current.primary, size: 25,),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child,);
                },
                child: Hero(
                  tag: 'playpause',
                  key: ValueKey<bool> (isPlaying),
                  child: SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(10),
                          backgroundColor: data.current.secondary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)
                          )
                      ),
                      onPressed: () async {
                        togglePlayPause();
                      },
                      child: Icon(isPlaying? Icons.pause : Icons.play_arrow, color: data.current.backcolor, size: 18,),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Hero(
                    tag: 'progress',
                    child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Container(
                            height: 50,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(width: 1.2, color: data.current.secondary)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                children: [
                                  Container(
                                    color: data.current.secondary,
                                    width: constraints.maxWidth *
                                        (max(currentFrameIndex - 1, 0) / data.radar.images.length),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) =>
                                        SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                                    child: Container(
                                      key: ValueKey<int>(currentFrameIndex),
                                      color: data.current.secondary,
                                      width: constraints.maxWidth *
                                          (currentFrameIndex / data.radar.images.length),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

Future<List<Uint8List>> preloadImages(List<String> urls) async {
  List<Uint8List> images = [];
  for (String url in urls) {
    try {
      final response = await http.get(Uri.parse(url + "/256/8/1.png"));
      if (response.statusCode == 200) {
        images.add(response.bodyBytes);
      } else {
        print('Failed to load image: $url');
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }
  return images;
}

class RadarPage extends StatefulWidget {
  final data;

  const RadarPage({Key? key, this.data}) : super(key: key);

  @override
  _RadarPageState createState() => _RadarPageState(data: data);
}

class _RadarPageState extends State<RadarPage> {
  final data;

  _RadarPageState({this.data});

  int currentFrameIndex = 0;
  late Timer timer;
  bool isPlaying = false;
  List<Uint8List> preloadedFrames = []; // Store image data

  @override
  void initState() {
    super.initState();

    // Preload images asynchronously
    preloadImages(data.radar.images).then((images) {
      setState(() {
        preloadedFrames = images;
      });
    });

    timer = Timer.periodic(const Duration(milliseconds: 500), (Timer t) {
      if (isPlaying) {
        setState(() {
          if (preloadedFrames.isNotEmpty) {
            currentFrameIndex = (currentFrameIndex + 1) % preloadedFrames.length;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double x = MediaQuery.of(context).padding.top;
    Color main = data.current.textcolor;
    Color top = lighten(data.current.highlight, 0.1);

    // Check if preloadedFrames is initialized
    if (preloadedFrames.isEmpty) {
      return Center(child: CircularProgressIndicator()); // or any loading indicator
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(data.lat, data.lng),
            initialZoom: 5,
            minZoom: 2,
            maxZoom: 8,
            backgroundColor: WHITE,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: data.settings["Color theme"] == "dark"
                  ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
            ),
            TileLayer(
              urlTemplate: data.settings["Color theme"] == "dark"
                  ? 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
            ),
            // Handle radar image layer manually if needed
            if (preloadedFrames.isNotEmpty) ...[
              // For custom tile handling, you might need to implement a custom TileLayer
            ],
          ],
        ),
      ],
    );
  }
}
