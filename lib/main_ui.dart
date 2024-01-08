/*
Copyright (C) <2023>  <Balint Maroti>

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
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/decoders/decode_wapi.dart';
import 'package:hihi_haha/radar.dart';
import 'package:hihi_haha/settings_page.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'ui_helper.dart';

class WeatherPage extends StatelessWidget {
  final data;
  final updateLocation;

  WeatherPage({super.key, required this.data,
        required this.updateLocation});

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  final FloatingSearchBarController controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext context) {
    // First get the FlutterView.
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;
    double safeHeight = size.height;
    final availableHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      drawer: MyDrawer(color: data.current.backcolor, settings: data.settings),
      body: RefreshIndicator(
        onRefresh: () async {
          await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
        },
        backgroundColor: WHITE,
        color: data.current.backcolor,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: data.current.backcolor,
                  border: const Border.symmetric(vertical: BorderSide(
                      width: 1.2,
                      color: WHITE
                  ))
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                  automaticallyImplyLeading: false, // remove the hamburger-menu
                  backgroundColor: Colors.transparent, // Set background to transparent
                  bottom: PreferredSize(
                    preferredSize: const Size(0, 380),
                    child: Container(),
                  ),
                  pinned: false,

                  expandedHeight: availableHeight + 40,
                  flexibleSpace: Stack(
                    children: [
                      ParallaxBackground(data: data,),
                      Positioned(
                        bottom: 25,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SingleChildScrollView(
                            child: buildCurrent(data, safeHeight - 100),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -3,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.2, color: WHITE),
                            color: data.current.backcolor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(27),
                            ),
                          ),
                        ),
                      ),
                      MySearchParent(updateLocation: updateLocation,
                      color: data.current.backcolor, place: data.place,
                      controller: controller, settings: data.settings, real_loc: data.real_loc,),
                    ],
                  ),
                ),
                NewTimes(data),
                buildHihiDays(data),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top:30, right: 20),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WHITE, width: 1.2)
                      ),
                      child: Column(
                        children: [
                          comfortatext(translation('Weather provider', data.settings[0]), 18),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: DropdownButton(
                              underline: Container(),
                              borderRadius: BorderRadius.circular(20),
                              icon: const Padding(
                                padding: EdgeInsets.only(left:5),
                                child: Icon(Icons.arrow_drop_down_circle, color: WHITE,),
                              ),
                              style: GoogleFonts.comfortaa(
                                color: WHITE,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                              //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
                              value: 'weatherapi.com',
                              items: ['weatherapi.com'].map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (String? value) async {
                                SetData('weather_provider', value!);
                                await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
                              },
                              isExpanded: true,
                              dropdownColor: darken(data.current.backcolor, 0.1),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 30))
              ],
            ),
          ],
        ),
      ),
    );
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

Widget buildCurrent(var data, double height) => SizedBox(
  height: height,
  child:   Column(
    children: [
      const Spacer(),
      Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            comfortatext("${data.current.temp}°", 85),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Align(
            alignment: Alignment.topLeft,
            child: comfortatext(data.current.text, 45),
        ),
      ),

    Center(
      child: Container(
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if(constraints.maxWidth > 400.0) {
                return Circles(400, data);
              } else {
                return Circles(constraints.maxWidth, data);
              }
            }
        ),
      ),
    ),
    ],
  ),
);

Widget Circles(double width, var data) {
  return SizedBox(
    width: width,
      child: Container(
          padding: const EdgeInsets.only(top:30),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DescriptionCircle(
                  color: data.current.contentColor[1],
                  text: '${data.current.humidity}',
                  undercaption: translation('humidity', data.settings[0]),
                  extra: '%',
                  size: width,
                ),
                DescriptionCircle(
                  color: data.current.contentColor[1],
                  text: '${data.current.uv}',
                  undercaption: translation('UV', data.settings[0]),
                  extra: '',
                  size: width,
                ),
                DescriptionCircle(
                  color: data.current.contentColor[1],
                  text: '${data.current.precip}',
                  undercaption: translation('precip.', data.settings[0]),
                  extra: data.settings[2],
                  size: width,
                ),
                DescriptionCircle(
                  color: data.current.contentColor[1],
                  text: '${data.current.wind}',
                  undercaption: translation('Wind', data.settings[0]),
                  extra: data.settings[3],
                  size: width,
                ),
              ]
          )
      )
  );
}

Widget NewTimes(var data) => SliverList(
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
                child: comfortatext(translation('sunrise/sunset', data.settings[0]), 20, color: WHITE),
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
                            child: comfortatext(data.sunstatus.sunrise, 18, color: WHITE)
                        )
                    )
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 90,
                          child: Align(
                            alignment: Alignment.center,
                              child: comfortatext(data.sunstatus.sunset, 18, color: WHITE)
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
                child: comfortatext(translation('air quality', data.settings[0]), 20, color: WHITE),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(width: 1.2, color: WHITE)
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
                          color: darken(data.current.backcolor, 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: comfortatext(data.aqi.aqi_index.toString(), 40,
                                color: WHITE),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 120,
                              child: comfortatext(
                            translation(['good', 'moderate', 'slightly unhealthy',
                              'unhealthy', 'very unhealthy',
                              'hazardous'][data.aqi.aqi_index - 1], data.settings[0]), 17, color: WHITE,
                              align: TextAlign.center)
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        aqiDataPoints("pm2.5", data.aqi.pm2_5, data.current.backcolor),
                        aqiDataPoints("pm10", data.aqi.pm10, data.current.backcolor),
                        aqiDataPoints("O3", data.aqi.o3, data.current.backcolor),
                        aqiDataPoints("NO2", data.aqi.no2, data.current.backcolor),
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
      Padding(
          padding: const EdgeInsets.only(top: 6, right: 30, left: 30, bottom: 10),
          child: Container(
            height: 1.2,
            color: WHITE,
          ),
      ),
    ],
  ),
);

Widget buildHihiDays(var data) => SliverList(
    delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
        if (index < data.days.length) {
          final day = data.days[index];
            return Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30, bottom: 10),
                    child: comfortatext(day.name, 20)
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: day.mm_precip > 0.1 ? darken(data.current.backcolor, 0.05) : data.current.backcolor,
                      ),
                      padding: const EdgeInsets.only(top: 8, left: 3, right: 5, bottom: 3),
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
                            Flexible(
                              fit: FlexFit.loose,
                                child: Row(
                                  children: [
                                    comfortatext(day.text, 22, color: WHITE),
                                    Spacer(),
                                    Container(
                                          padding: const EdgeInsets.only(top:3,bottom: 3, left: 3, right: 3),
                                          decoration: BoxDecoration(
                                            //border: Border.all(color: Colors.blueAccent)
                                              color: WHITE,
                                              borderRadius: BorderRadius.circular(10)
                                          ),
                                        child: Text(
                                            day.minmaxtemp,
                                            style: TextStyle(
                                                color: data.current.backcolor
                                            ),
                                            textScaleFactor: 1.4
                                        ),
                                    ),
                                  ],
                                )
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
                                      comfortatext('${day.precip_prob}%', 20),
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
                                          data.settings[2], 20),
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
                                          .settings[3]}', 20),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      const Icon(CupertinoIcons.thermometer,
                                        color: WHITE,),
                                      const Padding(
                                          padding: EdgeInsets.only(right: 10)),
                                      comfortatext(
                                          '${day.avg_temp} ${data.settings[1]}',
                                          20),
                                    ],
                                  ),
                                ),
                              ]
                          );
                        }
                      ),
                    ),
                  ),
                  buildHours(day.hourly, data.settings, data.current.accentcolor),
                ],
              ),
            );
          }
        return null;

    },
)
);

Widget buildHours(List<dynamic> data, List<String> units, Color accentcolor) => SizedBox(
  height: 244,
  child: ListView(
    physics: const BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    children: data.map<Widget>((hour) {
      return SizedBox(
        height: 224,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: comfortatext('${hour.temp}°', 22),
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
              padding: const EdgeInsets.only(top: 20),
              child: Image.asset(
                'assets/icons/' + hour.icon,
                fit: BoxFit.scaleDown,
                height: 38,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top:20, left: 9, right: 9),
              child: comfortatext(hour.time, 17)
            )
          ],
        ),
      );
    }).toList(),
  ),
);


