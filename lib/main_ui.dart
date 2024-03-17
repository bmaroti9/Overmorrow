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

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/decoders/decode_wapi.dart';
import 'package:overmorrow/main_screens.dart';
import 'package:overmorrow/radar.dart';
import 'package:overmorrow/settings_page.dart';
import 'ui_helper.dart';

Color instantBackColor = Colors.white;

class WeatherPage extends StatelessWidget {
  final data;
  final updateLocation;

  WeatherPage({super.key, required this.data,
        required this.updateLocation});

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {

    instantBackColor = data.current.backcolor;

    // Build the ui for phones

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize / view.devicePixelRatio;

    if (size.width > 950) {
      return TabletLayout(data, updateLocation, context);
    }

    //IMPORTANT: i have been testing a new look for Overmorrow
    // If you wish to test the old one, uncomment first return
    // note: some things might be broken in the old one

    //return PhoneLayout(data, updateLocation, context);
    return NewMain(data: data, updateLocation: updateLocation,);

  }
}

class ParallaxBackground extends StatelessWidget {
  final data;
  const ParallaxBackground({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.settings[5] == 'normal') {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backdrops/${data!.current.backdrop}'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    else {
      return Container(
        color: darken(data.current.backcolor, 0.05),
      );
    }
  }
}

Widget buildCurrent(var data, double height, double bottom) => Column(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    Padding(
      padding: const EdgeInsets.only(top: 0.0, left: 30),
      child: Align(
        alignment: Alignment.topLeft,
        child: comfortatext("${data.current.temp}°", 70, data.settings)
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Align(
          alignment: Alignment.topLeft,
          child: comfortatext(data.current.text, 40, data.settings),
      ),
    ),

  Align(
    alignment: Alignment.bottomLeft,
    child: Container(
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if(constraints.maxWidth > 400.0) {
              return Circles(400, data, bottom, WHITE);
            } else {
              return Circles(constraints.maxWidth * 0.93, data, bottom, WHITE);
            }
          }
      ),
    ),
  ),
  ],
);

Widget Circles(double width, var data, double bottom, color) {
  return Center(
    child: SizedBox(
      width: width,
        child: Container(
            padding: const EdgeInsets.only(top:30, left: 5, right: 5),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.feels_like}°',
                    undercaption: translation('Feels like', data.settings[0]),
                    extra: '',
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.humidity}',
                    undercaption: translation('Humidity', data.settings[0]),
                    extra: '%',
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.precip}',
                    undercaption: translation('precip.', data.settings[0]),
                    extra: data.settings[2],
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.wind}',
                    undercaption: translation('Wind', data.settings[0]),
                    extra: data.settings[3],
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                  ),
                ]
            )
        )
    ),
  );
}

Widget NewTimes(var data, bool divider) => SliverList(
  delegate: SliverChildListDelegate(
    [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(translation('sunrise/sunset', data.settings[0]), 20, data.settings, color: WHITE),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 1.2, color: WHITE)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Icon(CupertinoIcons.sunrise, color: WHITE,),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(CupertinoIcons.sunset, color: WHITE,),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            return Container(
                              color: WHITE,
                              height: constraints.maxHeight,
                              width: constraints.maxWidth * data.sunstatus.sunstatus,
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Positioned(
                                    height: constraints.maxHeight,
                                    left: 20,
                                    child: Icon(CupertinoIcons.sunrise, color: data.current.backcolor),
                                  ),
                                  Positioned(
                                    left: constraints.maxWidth - 46,
                                    height: constraints.maxHeight,
                                    child: Icon(CupertinoIcons.sunset, color: data.current.backcolor),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 90,
                        child: Align(
                          alignment: Alignment.center,
                            child: comfortatext(data.sunstatus.sunrise, 18, data.settings,  color: WHITE)
                        )
                    )
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 90,
                          child: Align(
                            alignment: Alignment.center,
                              child: comfortatext(data.sunstatus.sunset, 18, data.settings, color: WHITE)
                          )
                      )
                  )
                ],
              ),
            )
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(translation('air quality', data.settings[0]), 20, data.settings, color: WHITE),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                //border: Border.all(width: 1.2, color: WHITE)
                color: darken(data.current.backcolor)
              ),
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        height: 85,
                        width: 85,
                        decoration: BoxDecoration(
                          color: WHITE,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: comfortatext(data.aqi.aqi_index.toString(), 40, data.settings,
                                color: data.current.backcolor),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 120,
                              child: comfortatext(
                            translation(['good', 'moderate', 'slightly unhealthy',
                              'unhealthy', 'very unhealthy',
                              'hazardous'][data.aqi.aqi_index - 1], data.settings[0]), 16, data.settings, color: WHITE,
                              align: TextAlign.center)
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        aqiDataPoints("PM2.5", data.aqi.pm2_5, data.current.backcolor, data.settings),
                        aqiDataPoints("PM10", data.aqi.pm10, data.current.backcolor, data.settings),
                        aqiDataPoints("O3", data.aqi.o3, data.current.backcolor, data.settings),
                        aqiDataPoints("NO2", data.aqi.no2, data.current.backcolor, data.settings),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      RadarMap(data),
      Visibility(
        visible: divider,
        child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 30, left: 30, bottom: 10),
            child: Container(
              height: 1.2,
              color: WHITE,
            ),
        ),
      ),
    ],
  ),
);

Widget buildHihiDays(var data) => SliverList(
    delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
        if (index < 3) {
          final day = data.days[index];
            return Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30, bottom: 10),
                    child: comfortatext(day.name, 20, data.settings)
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: day.mm_precip > 0.1 ? darken(data.current.backcolor, 0.1) : data.current.backcolor,
                      ),
                      padding: const EdgeInsets.only(top: 8, left: 3, right: 5, bottom: 3),
                      child: SizedBox(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(left: 10, right: 20),
                                  child: Image.asset(
                                    'assets/icons/' + day.icon,
                                    fit: BoxFit.contain,
                                    height: 40,
                                  ),
                                ),
                              comfortatext(day.text, 22, data.settings, color: WHITE),
                              Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                      padding: const EdgeInsets.only(top:7,bottom: 7, left: 5, right: 5),
                                      decoration: BoxDecoration(
                                        //border: Border.all(color: Colors.blueAccent)
                                          color: WHITE,
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                    child: comfortatext(day.minmaxtemp, 17, data.settings, color: data.current.backcolor)
                                ),
                              )
                              ],
                            ),
                            Visibility(
                              visible: day.mm_precip > 0.1,
                              child: RainWidget(data.settings, day)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, right: 5, top: 15, bottom: 30),
                    child: Container(
                      height: 85,
                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.2, color: WHITE),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child:  LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return GridView.count(
                              padding: const EdgeInsets.all(0),
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                              crossAxisCount: 2,
                              childAspectRatio: constraints.maxWidth / constraints.maxHeight,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.water_drop_outlined,
                                        color: WHITE,),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      comfortatext('${day.precip_prob}%', 20, data.settings),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.water_drop, color: WHITE,),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      comfortatext(day.total_precip.toString() +
                                          data.settings[2], 20, data.settings),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.wind, color: WHITE,),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      comfortatext('${day.windspeed} ${data
                                          .settings[3]}', 20, data.settings),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      const Icon(CupertinoIcons.sun_min,
                                        color: WHITE,),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      comfortatext('${day.uv} UV', 20, data.settings),
                                    ],
                                  ),
                                ),
                              ]
                          );
                        }
                      ),
                    ),
                  ),
                  buildHours(day.hourly, data.settings, data.current.accentcolor, data.settings),
                ],
              ),
            );
          }
        return null;
    },
)
);

Widget buildGlanceDay(var data) => SliverPadding(
  padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 10),
  sliver: SliverToBoxAdapter(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext('Daily', 20, data.settings, color: WHITE),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(width: 1.2, color: WHITE),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 8, bottom: 8),
            physics: NeverScrollableScrollPhysics(),
            itemCount: data.days.length - 3,
            itemBuilder: (context, index) {
              final day = data.days[index + 3];
              return Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
                child: Row(
                  children: [
                    Container(
                      height: 75,
                      width: 75,
                      decoration: BoxDecoration(
                          color: darken(data.current.backcolor),
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          comfortatext(day.name, 18, data.settings),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/icons/' + day.icon,
                              fit: BoxFit.contain,
                              height: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        height: 75,
                        width: 50,
                        decoration: BoxDecoration(
                            color: WHITE,
                            borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_drop_up, color: data.current.backcolor, size: 20,),
                                Icon(Icons.arrow_drop_down, color: data.current.backcolor, size: 20,),
                              ],
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  comfortatext(day.minmaxtemp.split("/")[1], 16, data.settings, color: data.current.backcolor),
                                  comfortatext(day.minmaxtemp.split("/")[0], 16, data.settings,color: data.current.backcolor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Container(
                            height: 75,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: WHITE, width: 1.2)
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.water_drop_outlined,
                                      color: WHITE, size: 18,),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2, right: 5),
                                      child: comfortatext('${day.precip_prob}%', 17, data.settings),
                                    ),
                                    const Icon(
                                      Icons.water_drop, color: WHITE, size: 18,),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2, right: 2),
                                      child: comfortatext(day.total_precip.toString() +
                                          data.settings[2], 17, data.settings),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.wind, color: WHITE, size: 18,),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2, right: 2),
                                      child: comfortatext('${day.windspeed} ${data
                                          .settings[3]}', 17, data.settings),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                    )
                  ],
                ),
              );
            }
          )
        ),
      ],
    ),
  ),
);

Widget buildHours(List<dynamic> data, List<String> units, Color accentcolor, settings) => SizedBox(
  height: 255,
  child: ListView(
    physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
    scrollDirection: Axis.horizontal,
    children: data.map<Widget>((hour) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: comfortatext('${hour.temp}°', 22, settings),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 15,
                height: 100,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: WHITE,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
              ),
              Container(
                width: 15,
                height: temp_multiply_for_scale(hour.temp, units[1]),
                decoration: const BoxDecoration(
                    color: WHITE,
                    borderRadius: BorderRadius.all(Radius.circular(20))
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 3, right: 3),
            child: Image.asset(
              'assets/icons/' + hour.icon,
              fit: BoxFit.scaleDown,
              height: 38,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top:20, left: 9, right: 9),
            child: comfortatext(hour.time, 17, settings)
          )
        ],
      );
    }).toList(),
  ),
);


