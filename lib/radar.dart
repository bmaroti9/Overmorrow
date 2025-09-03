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
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';

import 'decoders/weather_data.dart';

class RadarSmall extends StatefulWidget {

  final WeatherData data;
  final bool radarHapticsOn;

  const RadarSmall({Key? key, required this.data, required this.radarHapticsOn}) : super(key: key);

  @override
  _RadarSmallState createState() => _RadarSmallState();
}

class _RadarSmallState extends State<RadarSmall> {

  double currentFrameIndex = 0;
  late Timer timer;

  bool hasBeenPlayed = false;

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    currentFrameIndex = widget.data.radar.startingIndex * 1.0;

    timer = Timer.periodic(const Duration(milliseconds: 1000), (Timer t) {
      if (isPlaying) {
        if (widget.radarHapticsOn) {
          HapticFeedback.lightImpact();
        }
        setState(() {
          currentFrameIndex =
          ((currentFrameIndex + 1) % (widget.data.radar.images.length - 1));
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

    String mode = context.watch<ThemeProvider>().getBrightness;

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
            child: Text(AppLocalizations.of(context)!.radar,
              style: const TextStyle(fontSize: 17),)
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 23, right: 23, top: 14, bottom: 10,),
          child: AspectRatio(
            aspectRatio: 1.70,
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(33),
                  border: Border.all(
                      width: 2, color: Theme.of(context).colorScheme.outlineVariant)
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(31),
                    child: (widget.data.isOnline) ? FlutterMap(
                      key: ValueKey(widget.data.place),
                      options: MapOptions(
                        onTap: (tapPosition, point) =>
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RadarBig(data: widget.data, radarHapticsOn: widget.radarHapticsOn,)),
                          )
                        },
                        //i added the .13 to make the marker be more in the center
                        initialCenter: LatLng(widget.data.lat + 0.13, widget.data.lng),
                        initialZoom: 6,
                        backgroundColor: mode == "dark" ? const Color(0xff262626) : const Color(0xffD4DADC),
                        keepAlive: true,
                        maxZoom: 6,
                        minZoom: 6,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.drag | InteractiveFlag
                                .flingAnimation),
                        cameraConstraint: CameraConstraint.containCenter(
                          bounds: LatLngBounds(
                            LatLng(widget.data.lat - 3, widget.data.lng - 3),
                            LatLng(widget.data.lat + 3, widget.data.lng + 3),
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
                          urlTemplate: "${widget.data.radar.images[currentFrameIndex
                              .toInt()]}/256/{z}/{x}/{y}/2/1_1.png",
                          //whoah i didn't know that the radar stuttering was because of a fading animation
                          //this makes it so much more fluid, because there is no fade between frames
                          tileDisplay: const TileDisplay.instantaneous(),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(widget.data.lat, widget.data.lng),
                              width: 36,
                              height: 36,
                              alignment: Alignment.topCenter,
                              child: Icon(Icons.place_sharp, color: Theme.of(context).colorScheme.inverseSurface, size: 36,),
                            ),
                          ],
                        )
                      ],
                    )
                    : Center(
                      child: Text("not available offline", style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 15),)
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Hero(
                        tag: 'switch',
                        child: SizedBox(
                          height: 56,
                          width: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                              elevation: 0.0,
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
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
                                    RadarBig(data: widget.data, radarHapticsOn: widget.radarHapticsOn,)),
                              );
                            },
                            child: Icon(Icons.open_in_full,
                              color: Theme.of(context).colorScheme.onTertiaryContainer, size: 20,),
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
                    height: 59,
                    width: 59,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          padding: const EdgeInsets.all(10),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                          )
                      ),
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        togglePlayPause();
                      },
                      child: Icon(isPlaying ? Icons.pause_outlined : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onSecondaryContainer, size: 18,),

                    ),
                  ),
                ),
              ),

              Expanded(
                child: Hero(
                  tag: "sliderTag",
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 19,
                        thumbColor: Theme.of(context).colorScheme.secondary,
                        activeTrackColor: Theme.of(context).colorScheme.secondary,

                        year2023: false,
                      ),
                      child: Slider(
                        value: currentFrameIndex,
                        min: 0,
                        max: widget.data.radar.times.length - 1.0,
                        divisions: widget.data.radar.times.length,
                        label: convertTime(widget.data.radar.times[currentFrameIndex.toInt()], context),
                    
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                    
                        onChanged: (double value) {
                          if (widget.radarHapticsOn) {
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
  final WeatherData data;
  final bool radarHapticsOn;

  const RadarBig({Key? key, required this.data, required this.radarHapticsOn}) : super(key: key);

  @override
  _RadarBigState createState() => _RadarBigState();
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

  bool hasBeenPlayed = false;

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    currentFrameIndex = widget.data.radar.startingIndex * 1.0;

    timer = Timer.periodic(const Duration(milliseconds: 1000), (Timer t) {
      if (isPlaying) {
        if (widget.radarHapticsOn) {
          HapticFeedback.lightImpact();
        }
        setState(() {
          currentFrameIndex =
          ((currentFrameIndex + 1) % (widget.data.radar.images.length - 1));
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

    double topPad = MediaQuery.of(context).padding.top;

    String mode = context.watch<ThemeProvider>().getBrightness;

    if (mode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      mode = brightness == Brightness.dark ? "dark" : "light";
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          (widget.data.isOnline) ? FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.data.lat, widget.data.lng),
              initialZoom: 6,
              minZoom: 2,
              maxZoom: 9,

              backgroundColor: mode == "dark" ? const Color(0xff262626) : const Color(0xffD4DADC),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate,),
            ),
            children: [
              Container(
                color: mode == "light" ? const Color(0xff262626) : const Color(0xffD4DADC),
              ),
              TileLayer(
                urlTemplate: mode == "dark"
                    ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              ),
              TileLayer(
                urlTemplate: "${widget.data.radar.images[currentFrameIndex.toInt()]}/256/{z}/{x}/{y}/2/1_1.png",
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
                    point: LatLng(widget.data.lat, widget.data.lng),
                    alignment: Alignment.topCenter,
                    width: 44,
                    height: 44,
                    child: Icon(Icons.place_sharp, color: Theme.of(context).colorScheme.inverseSurface, size: 44,),
                  ),
                ],
              )
            ],
          )
          : Center(
            child: Text("not available offline", style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 15),),
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
                    padding: const EdgeInsets.only(top: 12, bottom: 12, left: 15, right: 15),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(30)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.light, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 16),),
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
                        Text(AppLocalizations.of(context)!.heavy, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 16),),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).colorScheme.surface,
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
                                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        //side: BorderSide(width: 2, color: Theme.of(context).colorScheme.primaryLighter)
                                      )
                                  ),
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    togglePlayPause();
                                  },
                                  child: Icon(isPlaying ? Icons.pause_outlined : Icons.play_arrow,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer, size: 18,),

                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Hero(
                              tag: "sliderTag",
                              child: Material(
                                color: Theme.of(context).colorScheme.surface,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 19,
                                    thumbColor: Theme.of(context).colorScheme.secondary,
                                    activeTrackColor: Theme.of(context).colorScheme.secondary,

                                    year2023: false,
                                  ),
                                  child: Slider(
                                    value: currentFrameIndex,
                                    min: 0,
                                    max: widget.data.radar.times.length - 1.0,
                                    divisions: widget.data.radar.times.length,
                                    label: convertTime(widget.data.radar.times[currentFrameIndex.toInt()], context),

                                    padding: const EdgeInsets.symmetric(horizontal: 15),

                                    onChanged: (double value) {
                                      if (widget.radarHapticsOn) {
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
            padding: EdgeInsets.only(right: 15, top: topPad + 15),
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
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
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
                      color: Theme.of(context).colorScheme.onTertiaryContainer, size: 21,),
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