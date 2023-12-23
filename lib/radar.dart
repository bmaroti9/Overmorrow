import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:latlong2/latlong.dart';

import 'dayforcast.dart';


class RadarMap extends StatefulWidget {

  final data;
  RadarMap(this.data);

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

    // Set up a timer to update the radar frame every 5 seconds
    timer = Timer.periodic(const Duration(milliseconds: 1300), (Timer t) {
      if (isPlaying) {
        setState(() {
          // Increment the frame index (you may want to add logic to handle the end of the frames)
          currentFrameIndex =
              ((currentFrameIndex + 1) % data.current.radar.length).toInt();
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the timer when the widget is disposed
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
            child: comfortatext(translation('radar', data.settings[0]), 20, color: WHITE),
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
                  border: Border.all(width: 1, color: WHITE)
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                //child: data.current.radar[0]
                child: FlutterMap(
                  options: MapOptions(
                    onTap: (tapPosition, point) => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RadarPage(data: data,)),
                      )
                    },
                    initialCenter: LatLng(data.current.lat, data.current.lng),
                    initialZoom: 6,
                    backgroundColor: WHITE,
                    keepAlive: true,
                    maxZoom: 6,
                    minZoom: 6,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LatLngBounds(
                        LatLng(data.current.lat - 3, data.current.lng - 3),
                        LatLng(data.current.lat + 3, data.current.lng + 3),
                      ),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: data.current.contentColor[0] == WHITE
                          ? 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png'
                          : 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
                    ),
                    TileLayer(
                      urlTemplate: data.current.radar[currentFrameIndex] + "/512/{z}/{x}/{y}/8/1_1.png",
                    ),
                  ],
                ),
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
                child: SizedBox(
                  key: ValueKey<bool> (isPlaying),
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        backgroundColor: WHITE,
                        side: const BorderSide(width: 1.2, color: WHITE),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return Container(
                          height: 50,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(width: 1.2, color: WHITE)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                Container(
                                  color: WHITE,
                                  width: constraints.maxWidth *
                                      (max(currentFrameIndex - 1, 0) / data.current.radar.length),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) =>
                                      SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                                  child: Container(
                                    key: ValueKey<int>(currentFrameIndex),
                                    color: WHITE,
                                    width: constraints.maxWidth *
                                        (currentFrameIndex / data.current.radar.length),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
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

  @override
  void initState() {
    super.initState();

    // Set up a timer to update the radar frame every 5 seconds
    timer = Timer.periodic(const Duration(milliseconds: 1300), (Timer t) {
      if (isPlaying) {
        setState(() {
          // Increment the frame index (you may want to add logic to handle the end of the frames)
          currentFrameIndex =
              ((currentFrameIndex + 1) % data.current.radar.length).toInt();
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the timer when the widget is disposed
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
    Color main = data.current.contentColor[0] == WHITE? darken(data.current.backcolor, 0.2) : WHITE;
    Color top = data.current.contentColor[0] == WHITE? WHITE : BLACK;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(data.current.lat, data.current.lng),
            initialZoom: 5,
            backgroundColor: WHITE,
          ),
          children: [
            TileLayer(
              urlTemplate: data.current.contentColor[0] == WHITE
                  ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
            ),
            TileLayer(
              urlTemplate: data.current.radar[currentFrameIndex] + "/512/{z}/{x}/{y}/8/1_1.png",
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child,);
                  },
                  child: SizedBox(
                    key: ValueKey<bool> (isPlaying),
                    height: 53,
                    width: 53,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.all(10),
                          backgroundColor: main,
                          //side: const BorderSide(width: 5, color: WHITE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)
                          ),
                      ),
                      onPressed: () async {
                        togglePlayPause();
                      },
                      child: Icon(isPlaying? Icons.pause : Icons.play_arrow, color: top, size: 18,),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Container(
                            padding: EdgeInsets.all(3),
                            height: 53,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                                color: main,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(width: 3, color: main)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                children: [
                                  Container(
                                    color: top,
                                    width: constraints.maxWidth *
                                        (max(currentFrameIndex - 1, 0) / data.current.radar.length),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) =>
                                        SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                                    child: Container(
                                      key: ValueKey<int>(currentFrameIndex),
                                      color: top,
                                      width: constraints.maxWidth *
                                          (currentFrameIndex / data.current.radar.length),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 15, top: x + 15),
          child: Align(
            alignment: Alignment.topLeft,
            child:  SizedBox(
              height: 53,
              width: 53,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.all(10),
                  backgroundColor: main,
                  //side: const BorderSide(width: 5, color: WHITE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.arrow_back, color: top, size: 18,),
              ),
            ),
          ),
        )
      ],
    );
  }
}
