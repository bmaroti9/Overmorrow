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
import 'package:hihi_haha/dayforcast.dart';
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
          await updateLocation(LOCATION);
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
                      controller: controller, settings: data.settings,),
                    ],
                  ),
                ),
                NewTimes(data),
                buildHihiDays(data),
                const SliverPadding(padding: EdgeInsets.only(bottom: 20))
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
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backdrops/${data!.current.backdrop}'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

Widget buildCurrent(var data, double height) => SizedBox(
  height: height,
  child:   Column(
    children: [
      const Spacer(),
      Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 30),
        child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              '${data.current.temp}°',
              style: GoogleFonts.comfortaa(
                color: data.current.contentColor[1],
                fontSize: 85,
                fontWeight: FontWeight.w100,
              ),
            )
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              data.current.text,
              style: GoogleFonts.comfortaa(
                color: data.current.contentColor[1],
                fontSize: 45,
                height: 0.7,
                fontWeight: FontWeight.w300,
              ),
            )
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(translation('sunrise/sunset', data.settings[0]), 20, color: WHITE),
              ),
            ),
            Center(
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
                            width: constraints.maxWidth * data.current.sunstatus,
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
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 67,
                        child: Align(
                          alignment: Alignment.center,
                            child: comfortatext(data.current.sunrise, 18, color: WHITE)
                        )
                    )
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 67,
                          child: Align(
                            alignment: Alignment.center,
                              child: comfortatext(data.current.sunset, 18, color: WHITE)
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
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: darken(data.current.backcolor, 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: comfortatext(data.current.aqi_index.toString(), 40,
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
                              'hazardous'][data.current.aqi_index - 1], data.settings[0]), 17, color: WHITE,
                              align: TextAlign.center)
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        aqiDataPoints("pm2.5", data.current.pm2_5, data.current.backcolor),
                        aqiDataPoints("pm10", data.current.pm10, data.current.backcolor),
                        aqiDataPoints("o3", data.current.o3, data.current.backcolor),
                        aqiDataPoints("No2", data.current.no2, data.current.backcolor),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: comfortatext(translation('precipitation', data.settings[0]), 20, color: WHITE),
            ),
          ),
          Flex(
            direction: Axis.horizontal,
            children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 0, bottom: 5, top: 5),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(width: 1.2, color: WHITE)
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: MyChart(data.days[0].hourly_for_precip),
                        )
                      ),
                    ),
                ),
              ),
              SizedBox(
                height: 165,
                width: 65,
                child: ListView.builder(
                  reverse: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    if (data.settings[2] == 'in') {
                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            comfortatext((index * 2).toString(), 17),
                            comfortatext('in', 14),
                          ],
                        ),
                      );
                    }
                    else {
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            comfortatext((index * 5).toString(), 17),
                            comfortatext('mm', 14),
                          ],
                        ),
                      );
                    }
                  }
                ),
              )
            ]
          ),
          Padding(
            padding: const EdgeInsets.only(left: 33, top: 0, right: 70, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                comfortatext("0", 18),
                comfortatext("6", 18),
                comfortatext("12", 18),
                comfortatext("18", 18),
                comfortatext("24", 18),
              ]
            )
          )
        ],
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

Widget buildHihiDays(var data) => SliverFixedExtentList(
    itemExtent: 500.0,
    delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
        if (index < data.days.length) {
          final day = data.days[index];
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 30),
                    child: Text(
                      day.name,
                      style: GoogleFonts.comfortaa(
                        color: WHITE,
                        fontSize: 20,
                        height: 0.7,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 0, top: 20, bottom: 10, right: 5),
                          child: Row(
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
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 30),
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
  height: 240, // Adjust the height as needed
  child: ListView(
    physics: const BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    children: data.map<Widget>((hour) {
      return SizedBox(
        height: 220,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                '${hour.temp}°',
                style: GoogleFonts.comfortaa(
                  color: WHITE,
                  fontSize: 22,
                  height: 0.7,
                  fontWeight: FontWeight.w300,
                ),
              ),
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
              padding: const EdgeInsets.only(top:20, left: 7, right: 7),
              child: Text(
                hour.time,
                style: GoogleFonts.comfortaa(
                  color: WHITE,
                  fontSize: 20,
                  height: 0.7,
                  fontWeight: FontWeight.w300,
                ),
              ),
            )
          ],
        ),
      );
    }).toList(),
  ),
);


