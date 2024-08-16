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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:latlong2/latlong.dart';

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
          padding: const EdgeInsets.only(left: 20, bottom: 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(translation('radar', data.settings["Language"]), 19, data.settings,
                color: data.current.onSurface),
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
                          urlTemplate: data.settings["Color mode"] == "dark"
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
                            child: Icon(Icons.open_in_full, color: data.current.surface, size: 25,),
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

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double x = MediaQuery.of(context).padding.top;
    Color main = data.current.onSurface;
    Color top = lighten(data.current.container, 0.1);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(data.lat, data.lng),
            initialZoom: 5,
            minZoom: 2,
            maxZoom: 8,

            backgroundColor: WHITE,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate,),
          ),
          children: [
            Container(
              color: data.settings["Color mode"] == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
            ),
            TileLayer(
              urlTemplate: data.settings["Color mode"] == "dark"
                  ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
            ),
            TileLayer(
              urlTemplate: data.radar.images[currentFrameIndex] + "/256/{z}/{x}/{y}/8/1_1.png",
            ),
            TileLayer(
              urlTemplate: data.settings["Color mode"] == "dark"
                  ? 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20, right: 20),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                elevation: 10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: top,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child,);
                        },
                        child: Hero(
                          key: ValueKey<bool> (isPlaying),
                          tag: 'playpause',
                          child: SizedBox(
                            height: 48,
                            width: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 8,
                                padding: const EdgeInsets.all(10),
                                backgroundColor: top,
                                //side: const BorderSide(width: 5, color: WHITE),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)
                                ),
                              ),
                              onPressed: () async {
                                togglePlayPause();
                              },
                              child: Icon(isPlaying? Icons.pause : Icons.play_arrow, color: main, size: 18,),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Hero(
                            tag: 'progress',
                            child: LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints constraints) {
                                  return Material(
                                    borderRadius: BorderRadius.circular(13),
                                    elevation: 8,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        height: 48,
                                        color: top,
                                        child: Stack(
                                          children: [
                                            Container(
                                              color: main,
                                              width: constraints.maxWidth *
                                                  (max(currentFrameIndex - 1, 0) / data.radar.images.length),
                                            ),
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 300),
                                              transitionBuilder: (Widget child, Animation<double> animation) =>
                                                  SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                                              child: Container(
                                                key: ValueKey<int>(currentFrameIndex),
                                                color: main,
                                                width: constraints.maxWidth *
                                                    (currentFrameIndex / data.radar.images.length),
                                              ),
                                            ),
                                          ],
                                        ),
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
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 20, top: x + 20),
          child: Align(
            alignment: Alignment.topRight,
            child:  Hero(
              tag: 'switch',
              child: SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    padding: const EdgeInsets.all(10),
                    backgroundColor: top,
                    //side: BorderSide(width: 3, color: main),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(Icons.close_fullscreen, color: main, size: 26,),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}


class RadarSmall extends StatefulWidget {

  final data;

  const RadarSmall({Key? key, required this.data}) : super(key: key);

  @override
  _RadarSmallState createState() => _RadarSmallState(data);
}

class _RadarSmallState extends State<RadarSmall> {
  double currentFrameIndex = 12;
  late Timer timer;

  bool hasBeenPlayed = false;

  final data;

  List<String> times = [];

  _RadarSmallState(this.data);

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    int precived_hour = int.parse(data.localtime.split(":")[0]);
    int real = int.parse(data.radar.times[11].split("h")[0]);

    int offset = precived_hour - real;

    for (int i = 0; i < data.radar.times.length; i++) {
      List<String> split = data.radar.times[i].split("h");
      String minute = split[1].replaceAll(RegExp(r"\D"), "");
      times.add("${int.parse(split[0]) + offset}:${minute == "0" ? "00" : minute}");
    }

    timer = Timer.periodic(const Duration(milliseconds: 1000), (Timer t) {
      if (isPlaying) {
        setState(() {
          currentFrameIndex =
          ((currentFrameIndex + 1) % (data.radar.images.length - 1));
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
    if (hasBeenPlayed) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
    else {
      setState(() {
        hasBeenPlayed = true;
        currentFrameIndex = 0;
        isPlaying = !isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 40),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(
                translation('radar', data.settings["Language"]), 16,
                data.settings,
                color: data.current.onSurface),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 25, right: 25, top: 12, bottom: 10),
          child: AspectRatio(
            aspectRatio: 1.57,
            child: Container(
              decoration: BoxDecoration(
                  color: data.current.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      width: 2.2, color: data.current.containerHigh)
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: FlutterMap(
                      options: MapOptions(
                        onTap: (tapPosition, point) =>
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RadarPage(data: data,)),
                          )
                        },
                        initialCenter: LatLng(data.lat, data.lng),
                        initialZoom: 6,
                        backgroundColor: data.settings["Color mode"] == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
                        keepAlive: true,
                        maxZoom: 6,
                        minZoom: 6,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.drag | InteractiveFlag
                                .flingAnimation),
                        cameraConstraint: CameraConstraint.containCenter(
                          bounds: LatLngBounds(
                            LatLng(data.lat - 3, data.lng - 3),
                            LatLng(data.lat + 3, data.lng + 3),
                          ),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: data.settings["Color mode"] == "dark"
                              ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
                        ),
                        TileLayer(
                          urlTemplate: data.radar.images[currentFrameIndex
                              .toInt()] + "/256/{z}/{x}/{y}/8/0_1.png",
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Hero(
                        tag: 'switch',
                        child: SizedBox(
                          height: 48,
                          width: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                              elevation: 0.0,
                              backgroundColor: data.current.container,
                              //side: BorderSide(width: 3, color: main),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) =>
                                    RadarBig(data: data,)),
                              );
                            },
                            child: Icon(CupertinoIcons.fullscreen,
                              color: data.current.primaryLight, size: 20,),
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
          padding: const EdgeInsets.only(left: 38, right: 25, bottom: 0, top: 10),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child,);
                },
                child: Hero(
                  tag: 'playpause',
                  key: ValueKey<bool>(isPlaying),
                  child: SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          padding: const EdgeInsets.all(10),
                          backgroundColor: data.current.container,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            //side: BorderSide(width: 2, color: data.current.primaryLighter)
                          )
                      ),
                      onPressed: () async {
                        togglePlayPause();
                      },
                      child: Icon(isPlaying ? Icons.pause_outlined : Icons.play_arrow,
                        color: data.current.primaryLight, size: 18,),

                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 18,
                          valueIndicatorTextStyle: GoogleFonts.comfortaa(
                            color: data.current.onPrimaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),

                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10, elevation: 0.0,
                              pressedElevation: 0),

                          tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 2),
                          overlayShape: SliderComponentShape.noOverlay

                        ),
                        child: Slider(
                          value: currentFrameIndex,
                          min: 0,
                          max: data.radar.times.length - 1.0,
                          divisions: data.radar.times.length,
                          label: times[currentFrameIndex.toInt()]
                              .toString(),

                          activeColor: data.current.primaryLighter,
                          inactiveColor: data.current.surface,
                          //thumbColor: data.current.primary,

                          onChanged: (double value) {
                            setState(() {
                              hasBeenPlayed = true;
                              currentFrameIndex = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 9),
                      child: Row(
                        children: <Widget>[
                          comfortatext('-2hr', 13, data.settings, color: data.current.onSurface),
                          Expanded(
                            flex: 6,
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: comfortatext('-1hr', 13, data.settings, color: data.current.onSurface)
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: comfortatext('now', 13, data.settings, color: data.current.onSurface)
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: comfortatext('30m', 13, data.settings, color: data.current.onSurface)
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class RadarBig extends StatefulWidget {
  final data;

  const RadarBig({Key? key, this.data}) : super(key: key);

  @override
  _RadarBigState createState() => _RadarBigState(data: data);
}

class _RadarBigState extends State<RadarBig> {
  double currentFrameIndex = 12;
  late Timer timer;

  List<String> times = [];

  bool hasBeenPlayed = false;

  final data;

  _RadarBigState({this.data});

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    int precived_hour = int.parse(data.localtime.split(":")[0]);
    int real = int.parse(data.radar.times[11].split("h")[0]);

    int offset = precived_hour - real;

    for (int i = 0; i < data.radar.times.length; i++) {
      List<String> split = data.radar.times[i].split("h");
      String minute = split[1].replaceAll(RegExp(r"\D"), "");
      times.add("${int.parse(split[0]) + offset}:${minute == "0" ? "00" : minute}");
    }


    timer = Timer.periodic(const Duration(milliseconds: 1600), (Timer t) {
      if (isPlaying) {
        setState(() {
          currentFrameIndex =
          ((currentFrameIndex + 1) % (data.radar.images.length - 1));
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
    if (hasBeenPlayed) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
    else {
      setState(() {
        hasBeenPlayed = true;
        currentFrameIndex = 0;
        isPlaying = !isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double x = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(data.lat, data.lng),
              initialZoom: 5,
              minZoom: 2,
              maxZoom: 8,

              backgroundColor: data.settings["Color mode"] == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate,),
            ),
            children: [
              Container(
                color: data.settings["Color mode"] == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
              ),
              TileLayer(
                urlTemplate: data.settings["Color mode"] == "dark"
                    ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              ),
              TileLayer(
                urlTemplate: data.radar.images[currentFrameIndex.toInt()] + "/256/{z}/{x}/{y}/8/1_1.png",
              ),
              TileLayer(
                urlTemplate: data.settings["Color mode"] == "dark"
                    ? 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: data.current.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child,);
                        },
                        child: Hero(
                          tag: 'playpause',
                          key: ValueKey<bool>(isPlaying),
                          child: SizedBox(
                            height: 48,
                            width: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  elevation: 0.0,
                                  padding: const EdgeInsets.all(10),
                                  backgroundColor: data.current.container,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    //side: BorderSide(width: 2, color: data.current.primaryLighter)
                                  )
                              ),
                              onPressed: () async {
                                togglePlayPause();
                              },
                              child: Icon(isPlaying ? Icons.pause_outlined : Icons.play_arrow,
                                color: data.current.primaryLight, size: 18,),

                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                    trackHeight: 18,
                                    valueIndicatorTextStyle: GoogleFonts.comfortaa(
                                      color: data.current.onPrimaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),

                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 10, elevation: 0.0,
                                        pressedElevation: 0),

                                    tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 2),
                                    overlayShape: SliderComponentShape.noOverlay,

                                ),
                                child: Slider(
                                  value: currentFrameIndex,
                                  min: 0,
                                  max: data.radar.times.length - 1.0,
                                  divisions: data.radar.times.length,
                                  label: times[currentFrameIndex.toInt()]
                                      .toString(),

                                  activeColor: data.current.primaryLighter,
                                  inactiveColor: data.current.surface,
                                  //thumbColor: data.current.primary,

                                  onChanged: (double value) {
                                    setState(() {
                                      hasBeenPlayed = true;
                                      currentFrameIndex = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 9),
                              child: Row(
                                children: <Widget>[
                                  comfortatext('-2hr', 13, data.settings, color: data.current.onSurface),
                                  Expanded(
                                    flex: 6,
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: comfortatext('-1hr', 13, data.settings, color: data.current.onSurface)
                                    ),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: comfortatext('now', 13, data.settings, color: data.current.onSurface)
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: comfortatext('30m', 13, data.settings, color: data.current.onSurface)
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 15, top: x + 15),
            child: Align(
              alignment: Alignment.topRight,
              child: Hero(
                tag: 'switch',
                child: SizedBox(
                  height: 52, //the big space looks ugly with a small button
                  width: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      elevation: 0.0,
                      backgroundColor: data.current.surface,
                      //side: BorderSide(width: 3, color: main),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(CupertinoIcons.fullscreen_exit,
                      color: data.current.primaryLight, size: 21,),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}