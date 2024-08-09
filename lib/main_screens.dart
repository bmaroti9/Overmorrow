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

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:overmorrow/new_forecast.dart';
import 'package:overmorrow/radar.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:stretchy_header/stretchy_header.dart';
import 'main_ui.dart';
import 'new_displays.dart';
import 'ui_helper.dart';


class NewMain extends StatefulWidget {
  final data;
  final updateLocation;
  final context;

  NewMain({Key? key, required this.data, required this.updateLocation, required this.context}) : super(key: key);

  @override
  _NewMainState createState() => _NewMainState(data, updateLocation, context);
}

class _NewMainState extends State<NewMain> {
  final data;
  final updateLocation;
  final context;

  _NewMainState(this.data, this.updateLocation, this.context);

  @override
  Widget build(BuildContext context) {
    final FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    final Size size = view.physicalSize / view.devicePixelRatio;

    final FloatingSearchBarController controller = FloatingSearchBarController();

    return Scaffold(
      backgroundColor: data.current.surface,
      drawer: MyDrawer(primary: data.current.backup_primary,
        back: data.current.backup_backcolor,
        settings: data.settings,
        image: data.current.backdrop,),
      body: StretchyHeader.listView(
        displacement: 130,
        onRefresh: () async {
          await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
        },
        headerData: HeaderData(
            //backgroundColor: WHITE,
            blurContent: false,
            headerHeight: max(size.height * 0.53, 400),
            //we don't want it to be smaller than 400
            header: ParrallaxBackground(image: data.image, key: Key(data.place),
                color: data.current.surface == BLACK ? BLACK
                    : lightAccent(data.current.surface, 5000)),
            overlay: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 25,
                      top: MediaQuery
                          .of(context)
                          .padding
                          .top + 20, right: 25, bottom: 25
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(left: 0, bottom: 2),
                        child: comfortatext(
                            "${data.current.temp}°", 69, data.settings,
                            color: data.current.colorPop, weight: FontWeight.w300),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: comfortatext(
                            data.current.text, 32, data.settings,
                            weight: data.settings["Color mode"] == "light"
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: data.current.descColor),
                      )
                    ],
                  ),
                ),
                MySearchParent(updateLocation: updateLocation,
                  color: data.current.surface,
                  place: data.place,
                  controller: controller,
                  settings: data.settings,
                  real_loc: data.real_loc,
                  secondColor: data.settings["Color mode"] == "light" ? data.current.primary : data.current.primaryLight,
                  textColor: data.settings["Color mode"] == "light" ? data.current.primaryLight : data.current.primary,
                  highlightColor: data.current.container,
                  key: Key("${data.place}, ${data.current.surface}"),
                  extraTextColor: data.current.onSurface,),
              ],
            )
        ),
        children: [
          Stack(
            children: [
              UpdatedNotifier(data: data,
                  time: data.updatedTime,
                  key: Key(data.updatedTime.toString())),
              LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    if (constraints.maxWidth > 500.0) {
                      return Circles(500, data, 0.5, data.current.primary);
                    } else {
                      return Circles(constraints.maxWidth * 0.97, data, 0.5,
                          data.current.primary);
                    }
                  }
              ),
            ],
          ),

          NewSunriseSunset(data: data, key: Key(data.place), size: size,),
          NewRain15MinuteIndicator(data),
          NewAirQuality(data),
          RadarSmall(
              data: data, key: Key("${data.place}, ${data.current.surface}")),
          buildNewDays(data),
          buildNewGlanceDay(data: data),

          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 30),
            child: providerSelector(
                data.settings,
                updateLocation,
                data.current.onSurface,
                data.current.container,
                data.current.primary,
                data.provider,
                "${data.lat}, ${data.lng}",
                data.real_loc),
          ),


          /*
          NewTimes(data, true),
          buildHihiDays(data),
          buildGlanceDay(data),
          providerSelector(data.settings, updateLocation, data.current.outline, data.current.container,
          data.current.surface, data.provider, "${data.lat}, ${data.lng}", data.real_loc),

           */
          const Padding(padding: EdgeInsets.only(bottom: 20))


        ],
      ),
    );
  }
}

Widget TabletLayout(data, updateLocation, context) {

  final FloatingSearchBarController controller = FloatingSearchBarController();

  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

  Size size = view.physicalSize / view.devicePixelRatio;

  double toppad = MediaQuery.of(context).viewPadding.top;

  double width = size.width - min(max(size.width * 0.4, 400), 450);
  double heigth = min(max(width / 1.5, 450), 510);

  return Scaffold(
    backgroundColor: data.current.surface,
    drawer: MyDrawer(primary: data.current.backup_primary, back: data.current.backup_backcolor,
        settings: data.settings, image: data.current.backdrop),
    body: RefreshIndicator(
      onRefresh: () async {
        await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
      },
      backgroundColor: WHITE,
      color: data.current.surface,
      displacement: 100,
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 10, bottom: 10, top: toppad + 10),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width,
                child: Column(
                  children: [
                    SizedBox(
                      height: heigth * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 15),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ParrallaxBackground(image: data.current.backdrop, key: Key(data.place),
                                    color: darken(data.current.surface, 0.1),),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 100, left: 30, bottom: 31),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 0, bottom: 0),
                                        child: comfortatext("${data.current.temp}°", 65, data.settings,
                                            color: data.current.colorpop, weight: FontWeight.w200),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 0),
                                        child: comfortatext(data.current.text, 25, data.settings, color: data.current.colorpop),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
                                    if(constraints.maxWidth > 400.0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 20),
                                        child: Circles(400, data, 0.6, data.current.colorpop, align: Alignment.centerRight),
                                      );
                                    } else {
                                      return Circles(constraints.maxWidth * 0.90, data, 1, data.current.surface);
                                    }
                                  }
                              ),
                              MySearchParent(updateLocation: updateLocation,
                                color: data.current.container, place: data.place,
                                controller: controller, settings: data.settings, real_loc: data.real_loc,
                                secondColor: data.current.surface, textColor: data.current.outline,
                                highlightColor: data.current.surface, key: Key("${data.place}, ${data.current.surface}"),
                                extraTextColor: data.current.onSurface,),
                            ],
                          ),
                        ),
                      ),
                    ),
                    buildHihiDays(data),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 50),
                  child: Column(
                    children: [
                      NewTimes(data, false),
                      buildGlanceDay(data),
                      providerSelector(data.settings, updateLocation, data.current.outline, data.current.container, data.current.surface,
                          data.provider, "${data.lat}, ${data.lng}", data.real_loc),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    )
  );
}