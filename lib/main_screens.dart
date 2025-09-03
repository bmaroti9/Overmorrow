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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:overmorrow/daily.dart';
import 'package:overmorrow/radar.dart';
import 'package:overmorrow/search_screens.dart';
import 'package:overmorrow/services/image_service.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:stretchy_header/stretchy_header.dart';
import 'decoders/weather_data.dart';
import 'hourly.dart';
import 'l10n/app_localizations.dart';
import 'main_ui.dart';
import 'new_displays.dart';

class NewMain extends StatelessWidget {
  final WeatherData data;
  final updateLocation;
  final ImageService? imageService;

  NewMain({required this.data, required this.updateLocation, required this.imageService});

  /*
  @override
  void initState() {
    super.initState();

    i'm keeping this in case i need another pop-up sometime
    if (data.settings['networkImageDialogShown'] == "false") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFeatureDialog(context, data.settings);
      });
    }

  }


  void _showFeatureDialog(BuildContext context, settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: data.current.surface,
          title: comfortatext(translation("Overmorrow 2.4.0 introduces Network images!", settings["Language"]), 20, data.settings, color: data.current.primary),
          content: SizedBox(
            height: 100,
            child: Column(
              children: [
                comfortatext(translation("Would you like to enable network images?", settings["Language"]), 16, data.settings,
                    color: data.current.onSurface),
                const SizedBox(height: 20,),
                comfortatext(translation("note: you can always change later by going into settings > appearance > image source",
                settings["Language"]), 13, data.settings,
                    color: data.current.onSurface),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await SetData('settingnetworkImageDialogShown', "true");
                await SetData('settingImage source', "asset");
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return const MyApp();
                    },
                  ),
                );
              },
              child: comfortatext(translation("Disable", settings["Language"]), 17, data.settings, color: data.current.outline, weight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () async {
                await SetData('settingnetworkImageDialogShown', "true");
                await SetData('settingImage source', "network");
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return const MyApp();
                    },
                  ),
                );
              },
              child: comfortatext(translation("Enable", settings["Language"]), 17, data.settings, color: data.current.primary, weight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
   */

  @override
  Widget build(BuildContext context) {

    final FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    final Size size = (view.physicalSize) / view.devicePixelRatio;

    /*

    final Map<String, Widget> widgetsMap = {
      'sunstatus': NewSunriseSunset(data: data, key: Key(data.place), width: size.width,),
      'rain indicator': rain15MinuteChart(data, data.current.palette, context),
      'hourly': NewHourly(data: data, hours: data.hourly72, elevated: false,),
      'alerts' : alertWidget(data, context, data.current.palette),
      'radar': RadarSmall(data: data),
      'daily': buildDays(data: data),
      'air quality': aqiWidget(data, data.current.palette, context, false)
    };

    final List<String> order = data.settings["Layout"] == "" ? [] : data.settings["Layout"].split(",");
    List<Widget> orderedWidgets = [];
    if (order.isNotEmpty && order[0] != "") {
      orderedWidgets = order.map((name) => widgetsMap[name]!).toList();
    }

    String colorMode = data.settings["Color mode"];
    if (colorMode == "auto") {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      colorMode = brightness == Brightness.dark ? "dark" : "light";
    }

     */

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StretchyHeader.listView(
        displacement: 130,
        onRefresh: () async {
          await updateLocation("${data.lat}, ${data.lng}", data.place);
        },
        headerData: HeaderData(
          //backgroundColor: WHITE,
          blurContent: false,
          headerHeight: (size.height ) * 0.495,
          header:  FadingImageWidget(
            image: imageService?.image,
          ),
          //header: ParrallaxBackground(image: data.current.imageService.image, key: Key(data.place),color: BLACK),
          overlay: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 26, right: 26, bottom: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    SmoothTempTransition(target: unitConversion(data.current.tempC,
                        context.select((SettingsProvider p) => p.getTempUnit), decimals: 1) * 1.0,
                      color: Theme.of(context).colorScheme.tertiaryFixedDim, fontSize: 75,),
                    Text(
                      translateCondition(data.current.condition, AppLocalizations.of(context)!),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 33, height: 1.05
                      ),
                    )
                    /*
                    comfortatext(
                        "${data.current.temp}°", 75, data.settings,
                        color: data.current.colorPop, weight: FontWeight.w200,
                    ),
                    comfortatext(
                        data.current.text, 33, data.settings,
                        weight: FontWeight.w400,
                        color: data.current.descColor)

                     */
                  ],
                ),
              ),

              MySearchWidget(place: data.place, updateLocation: updateLocation, isTabletMode: false,)
            ],
          )
        ),
        children: [

          FadingWidget(data: data, time: data.updatedTime, imageService: imageService, key: Key(data.updatedTime.toString())),

          Circles(data: data),

          NewSunriseSunset(data: data, width: size.width),

          NewHourly(hours: data.hourly72, elevated: false,),

          RadarSmall(data: data, radarHapticsOn: context.select((SettingsProvider p) => p.getRadarHapticsOn),),

          BuildDays(data: data),

          AqiWidget(data: data, isTabletMode: false),

          /*
          Column(
            children: orderedWidgets.map((widget) {
              return widget;
            }).toList(),
          ),
           */

          ProviderSelector(updateLocation: updateLocation, loc: data.place, latLon: "${data.lat}, ${data.lng}",),
        ],
      ),
    );
  }
}


//I'm using this as a reference for everything i want animated between places
class SmoothTransitionDemo extends StatelessWidget {
  final double targetScale;

  const SmoothTransitionDemo({super.key, required this.targetScale});

  @override
  Widget build(BuildContext context) {

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 1.0,
        end: targetScale,
      ),

      duration: const Duration(milliseconds: 3000),

      builder: (context, currentScale, child) {
        return Transform.scale(
          scale: currentScale,
          child: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
            alignment: Alignment.center,
            child: Text(
              targetScale.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}

class TabletLayout extends StatelessWidget {
  final WeatherData data;
  final updateLocation;
  final ImageService? imageService;

  TabletLayout({super.key, required this.data, required this.updateLocation, required this.imageService});

  @override
  Widget build(BuildContext context) {

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;

    double panelWidth = size.width * 0.29;

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: panelWidth,
              child: MySearchWidget(place: data.place, updateLocation: updateLocation, isTabletMode: true)
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return StretchyHeader.listView(
                    displacement: 130,
                    onRefresh: () async {
                      await updateLocation(
                          "${data.lat}, ${data.lng}", data.place);
                    },
                    headerData: HeaderData(
                        blurContent: false,
                        headerHeight: (size.height) * 0.43,
                        header: FadingImageWidget(
                          image: imageService?.image,
                        ),
                        overlay: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.inverseSurface,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.onInverseSurface, size: 22,),
                                  const SizedBox(width: 4,),
                                  Text(data.place, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 22),)
                                ],
                              ),
                            ),
                          ),
                        )
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: FadingWidget(data: data, time: data.updatedTime, imageService: null,)
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 7, left: 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SmoothTempTransition(target: unitConversion(data.current.tempC,
                                      context.select((SettingsProvider p) => p.getTempUnit), decimals: 1) * 1.0,
                                      color: Theme.of(context).colorScheme.primary, fontSize: 68,),
                                  Text(
                                    translateCondition(data.current.condition, AppLocalizations.of(context)!),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 30, height: 1.05
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 397,
                              child: Circles(data : data)
                            ),
                          ],
                        ),
                      ),

                      NewSunriseSunset(data: data, width: constraints.maxWidth,),
                      NewHourly(hours: data.hourly72, elevated: false,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const SizedBox(height: 15,),
                                //rain15MinuteChart(
                                //    data, data.current.palette, context),
                                RadarSmall(data: data, radarHapticsOn: context.select((SettingsProvider p) => p.getRadarHapticsOn),),
                                AqiWidget(data: data, isTabletMode: true),
                                ProviderSelector(updateLocation: updateLocation, loc: data.place, latLon: "${data.lat}, ${data.lng}",),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                //since it's only available with weatherapi, and in that case there are only 3 days
                                //this makes the two sides more even
                                //alertWidget(data, context, data.current.palette),
                                BuildDays(data: data),
                              ],
                            ),
                          )
                        ],
                      ),

                    ],
                  );
                }
              ),
            ),
          ],
        )
    );
  }
}
