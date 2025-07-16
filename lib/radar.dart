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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';

import 'decoders/decode_OM.dart';

class RadarSmall extends StatefulWidget {

  final data;

  const RadarSmall({Key? key, required this.data}) : super(key: key);

  @override
  _RadarSmallState createState() => _RadarSmallState(data);
}

class _RadarSmallState extends State<RadarSmall> {
  double currentFrameIndex = 0;
  late Timer timer;

  bool hasBeenPlayed = false;

  final data;

  List<String> times = [];

  _RadarSmallState(this.data);

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    currentFrameIndex = data.radar.starting_index * 1.0;

    int precived_hour = int.parse(data.localtime.split(":")[0]);
    int real = data.radar.real_hour;

    int offset = precived_hour - real;

    for (int i = 0; i < data.radar.times.length; i++) {
      List<String> split = data.radar.times[i].split("h");
      String minute = split[1].replaceAll(RegExp(r"\D"), "");
      int hour = (int.parse(split[0]) + offset) % 24;
      if (data.settings["Time mode"] == "12 hour") {
        times.add(OMamPmTime("jT$hour:${minute == "0" ? "00" : minute}"));
      }
      else {
        times.add("${hour.toString().padLeft(2, "0")}:${minute == "0" ? "00" : minute}");
      }
    }

    timer = Timer.periodic(const Duration(milliseconds: 1000), (Timer t) {
      if (isPlaying) {
        if (data.settings["Radar haptics"] == "on") {
          HapticFeedback.lightImpact();
        }
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

    ColorScheme palette = data.current.palette;
    String mode = data.settings["Color mode"];

    if (mode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      mode = brightness == Brightness.dark ? "dark" : "light";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 15),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(
                AppLocalizations.of(context)!.radar, 17,
                data.settings,
                color: palette.onSurface),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 23, right: 23, top: 14, bottom: 10,),
          child: AspectRatio(
            aspectRatio: 1.65,
            child: Container(
              decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(33),
                  border: Border.all(
                      width: 2, color: palette.outlineVariant)
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(31),
                    child: (data.isonline) ? FlutterMap(
                      options: MapOptions(
                        onTap: (tapPosition, point) =>
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RadarBig(data: data,)),
                          )
                        },
                        initialCenter: LatLng(data.lat, data.lng),
                        initialZoom: 6,
                        backgroundColor: mode == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
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
                          urlTemplate: mode == "dark"
                              ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
                        ),
                        TileLayer(
                          urlTemplate: data.radar.images[currentFrameIndex
                              .toInt()] + "/256/{z}/{x}/{y}/2/1_1.png",
                          //whoah i didn't know that the radar stuttering was because of a fading animation
                          //this makes it so much more fluid, because there is no fade between frames
                          tileDisplay: const TileDisplay.instantaneous(),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(data.lat, data.lng),
                              width: 54,
                              height: 54,
                              child: Padding(
                                //try to make the bottom of the pointer where the place actually is
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Icon(Icons.place_sharp, color: palette.inverseSurface, size: 38,),
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                    : Center(
                        child: comfortatext("not available offline", 15, data.settings, color: palette.outline)
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Hero(
                        tag: 'switch',
                        child: SizedBox(
                          height: 55,
                          width: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                              elevation: 0.0,
                              backgroundColor: palette.secondaryContainer,
                              //side: BorderSide(width: 3, color: main),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(19)
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                isPlaying = false;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) =>
                                    RadarBig(data: data,)),
                              );
                            },
                            child: Icon(Icons.open_in_full,
                              color: palette.onSecondaryContainer, size: 20,),
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
          padding: const EdgeInsets.only(left: 36, right: 32, bottom: 25, top: 5),
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
                    height: 58,
                    width: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          padding: const EdgeInsets.all(10),
                          backgroundColor: palette.secondaryContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                          )
                      ),
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        togglePlayPause();
                      },
                      child: Icon(isPlaying ? Icons.pause_outlined : Icons.play_arrow,
                        color: palette.onSecondaryContainer, size: 18,),

                    ),
                  ),
                ),
              ),

              Expanded(
                child: Hero(
                  tag: "sliderTag",
                  child: Material(
                    color: palette.surface,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 19,
                        valueIndicatorColor: palette.inverseSurface,
                        thumbColor: palette.secondary,
                        activeTrackColor: palette.secondary,
                        inactiveTrackColor: palette.secondaryContainer,
                        inactiveTickMarkColor: palette.secondary,
                        activeTickMarkColor: palette.surface,
                        valueIndicatorTextStyle: GoogleFonts.outfit(
                          color: palette.onInverseSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        year2023: false,
                      ),
                      child: Slider(
                        value: currentFrameIndex,
                        min: 0,
                        max: data.radar.times.length - 1.0,
                        divisions: data.radar.times.length,
                        label: times[currentFrameIndex.toInt()].toString(),
                    
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                    
                        onChanged: (double value) {
                          if (data.settings["Radar haptics"] == "on") {
                            HapticFeedback.lightImpact();
                          }
                          setState(() {
                            hasBeenPlayed = true;
                            currentFrameIndex = value;
                          });
                        },
                      ),
                    ),
                  ),
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

  final List<Color> radarColors = [
    const Color(0xFF88ddee), const Color(0xFF0099cc), const Color(0xFF0077aa), const Color(0xFF005588),
    const Color(0xFFffee00), const Color(0xFFffaa00), const Color(0xFFff7700),
    const Color(0xFFff4400), const Color(0xFFee0000), const Color(0xFF990000),
    const Color(0xFFffaaff), const Color(0xFFff77ff), const Color(0xFFff00ff),
  ];

  double currentFrameIndex = 0;
  late Timer timer;

  List<String> times = [];

  bool hasBeenPlayed = false;

  final data;

  _RadarBigState({this.data});

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    currentFrameIndex = data.radar.starting_index * 1.0;

    int precived_hour = int.parse(data.localtime.split(":")[0]);
    int real = data.radar.real_hour;

    int offset = precived_hour - real;

    for (int i = 0; i < data.radar.times.length; i++) {
      List<String> split = data.radar.times[i].split("h");
      String minute = split[1].replaceAll(RegExp(r"\D"), "");
      int hour = (int.parse(split[0]) + offset) % 24;
      if (data.settings["Time mode"] == "12 hour") {
        times.add(OMamPmTime("jT$hour:${minute == "0" ? "00" : minute}"));
      }
      else {
        times.add("${hour.toString().padLeft(2, "0")}:${minute == "0" ? "00" : minute}");
      }
    }


    timer = Timer.periodic(const Duration(milliseconds: 1600), (Timer t) {
      if (isPlaying) {
        if (data.settings["Radar haptics"] == "on") {
          HapticFeedback.lightImpact();
        }
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

    ColorScheme palette = data.current.palette;
    double x = MediaQuery.of(context).padding.top;

    String mode = data.settings["Color mode"];

    if (mode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      mode = brightness == Brightness.dark ? "dark" : "light";
    }

    return Scaffold(
      backgroundColor: palette.surface,
      body: Stack(
        children: [
          (data.isonline) ? FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(data.lat, data.lng),
              initialZoom: 6,
              minZoom: 2,
              maxZoom: 9,

              backgroundColor: mode == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate,),
            ),
            children: [
              Container(
                color: mode == "dark"? const Color(0xff262626) : const Color(0xffD4DADC),
              ),
              TileLayer(
                urlTemplate: mode == "dark"
                    ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              ),
              TileLayer(
                urlTemplate: data.radar.images[currentFrameIndex.toInt()] + "/256/{z}/{x}/{y}/2/1_1.png",
                tileDisplay: const TileDisplay.instantaneous(),
              ),
              TileLayer(
                urlTemplate: mode == "dark"
                    ? 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(data.lat, data.lng),
                    width: 62,
                    height: 62,
                    child: Padding(
                      //try to make the bottom of the pointer where the place actually is
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Icon(Icons.place_sharp, color: palette.inverseSurface, size: 44,),
                    ),
                  ),
                ],
              )
            ],
          )
          : Center(
            child: comfortatext("not available offline", 15, data.settings, color: palette.outline)
          ),

          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 35),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: palette.inverseSurface,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        comfortatext(AppLocalizations.of(context)!.light, 16, data.settings, color: palette.onInverseSurface),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                              children: List<Widget>.generate(radarColors.length, (int index) {
                                return Container(
                                  width: 10,
                                  height: 15,
                                  decoration: BoxDecoration(
                                      color: radarColors[index],
                                      borderRadius: index == 0
                                          ? const BorderRadius.only(topLeft: Radius.circular(7), bottomLeft: Radius.circular(7))
                                          : index == (radarColors.length - 1)
                                          ? const BorderRadius.only(topRight: Radius.circular(7), bottomRight: Radius.circular(7))
                                          : BorderRadius.circular(0)

                                  ),
                                );
                              })
                          ),
                        ),
                        comfortatext(AppLocalizations.of(context)!.heavy, 16, data.settings, color: palette.onInverseSurface),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: palette.surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
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
                                height: 60,
                                width: 60,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      elevation: 0.0,
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor: palette.secondaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        //side: BorderSide(width: 2, color: palette.primaryLighter)
                                      )
                                  ),
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    togglePlayPause();
                                  },
                                  child: Icon(isPlaying ? Icons.pause_outlined : Icons.play_arrow,
                                    color: palette.onSecondaryContainer, size: 18,),

                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Hero(
                              tag: "sliderTag",
                              child: Material(
                                color: palette.surface,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 19,
                                    valueIndicatorColor: palette.inverseSurface,
                                    thumbColor: palette.secondary,
                                    activeTrackColor: palette.secondary,
                                    inactiveTrackColor: palette.secondaryContainer,
                                    inactiveTickMarkColor: palette.secondary,
                                    activeTickMarkColor: palette.surface,
                                    valueIndicatorTextStyle: GoogleFonts.outfit(
                                      color: palette.onInverseSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    year2023: false
                                  ),
                                  child: Slider(
                                    value: currentFrameIndex,
                                    min: 0,
                                    max: data.radar.times.length - 1.0,
                                    divisions: data.radar.times.length,
                                    label: times[currentFrameIndex.toInt()].toString(),

                                    padding: const EdgeInsets.only(left: 20, right: 5),

                                    onChanged: (double value) {
                                      if (data.settings["Radar haptics"] == "on") {
                                        HapticFeedback.lightImpact();
                                      }
                                      setState(() {
                                        hasBeenPlayed = true;
                                        currentFrameIndex = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
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
          Padding(
            padding: EdgeInsets.only(right: 15, top: x + 15),
            child: Align(
              alignment: Alignment.topRight,
              child: Hero(
                tag: 'switch',
                child: SizedBox(
                  height: 57,
                  width: 57,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      elevation: 0.0,
                      backgroundColor: palette.secondaryContainer,
                      //side: BorderSide(width: 3, color: main),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19)
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        isPlaying = false;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Icon(Icons.close_fullscreen,
                      color: palette.onSecondaryContainer, size: 21,),
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