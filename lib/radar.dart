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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'decoders/decode_OM.dart';

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
        setState(() {
          HapticFeedback.lightImpact();
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

    String mode = data.settings["Color mode"];

    if (mode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      mode = brightness == Brightness.dark ? "dark" : "light";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(
                AppLocalizations.of(context)!.radar, 16,
                data.settings,
                color: data.current.onSurface),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 25, right: 25, top: 12, bottom: 10,),
          child: AspectRatio(
            aspectRatio: 1.57,
            child: Container(
              decoration: BoxDecoration(
                  color: data.current.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      width: 2.5, color: data.current.containerHigh)
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                              .toInt()] + "/256/{z}/{x}/{y}/8/0_1.png",
                        ),
                      ],
                    )
                    : Center(
                        child: comfortatext("not available offline", 15, data.settings, color: data.current.outline)
                    )
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
                              HapticFeedback.selectionClick();
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
          padding: const EdgeInsets.only(left: 38, right: 25, bottom: 50, top: 10),
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
                        HapticFeedback.selectionClick();
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

                          tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
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
                              HapticFeedback.lightImpact();
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
                          comfortatext('-2${AppLocalizations.of(context)!.hr}', 13, data.settings, color: data.current.onSurface),
                          Expanded(
                            flex: 6,
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: comfortatext('-1${AppLocalizations.of(context)!.hr}', 13, data.settings, color: data.current.onSurface)
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: comfortatext(AppLocalizations.of(context)!.now, 13, data.settings, color: data.current.onSurface)
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: comfortatext(AppLocalizations.of(context)!.thirtyMinutes, 13, data.settings, color: data.current.onSurface)
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
        HapticFeedback.lightImpact();
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

    String mode = data.settings["Color mode"];

    if (mode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      mode = brightness == Brightness.dark ? "dark" : "light";
    }


    return Scaffold(
      backgroundColor: data.current.containerLow,
      body: Stack(
        children: [
          (data.isonline) ? FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(data.lat, data.lng),
              initialZoom: 5,
              minZoom: 2,
              maxZoom: 8,

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
                urlTemplate: data.radar.images[currentFrameIndex.toInt()] + "/256/{z}/{x}/{y}/8/1_1.png",
              ),
              TileLayer(
                urlTemplate: mode == "dark"
                    ? 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
              ),
            ],
          )
          : Center(
            child: comfortatext("not available offline", 15, data.settings, color: data.current.outline)
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
                                HapticFeedback.selectionClick();
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

                                    tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
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
                                      HapticFeedback.lightImpact();
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
                                  comfortatext('-2${AppLocalizations.of(context)!.hr}', 13, data.settings, color: data.current.onSurface),
                                  Expanded(
                                    flex: 6,
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: comfortatext('-1${AppLocalizations.of(context)!.hr}', 13, data.settings, color: data.current.onSurface)
                                    ),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: comfortatext(AppLocalizations.of(context)!.now, 13, data.settings, color: data.current.onSurface)
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: comfortatext(AppLocalizations.of(context)!.thirtyMinutes, 13, data.settings, color: data.current.onSurface)
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
                      HapticFeedback.selectionClick();
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