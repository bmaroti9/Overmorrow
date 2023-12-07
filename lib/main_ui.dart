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
import 'package:hihi_haha/settings_page.dart';
import 'package:hihi_haha/weather_refact.dart';
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
                            child: buildCurrent(data, safeHeight - 100), // Place your buildCurrent widget here
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
                //buildHihiDays(data),
                NewTimes(data)
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
                child: comfortatext('sunrise/sunset', 20, color: WHITE),
              ),
            ),
            Center(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(width: 1.2, color: WHITE)
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: Container(
                        color: WHITE,
                        height: 52,
                        width: 200,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Icon(CupertinoIcons.sunrise, color: data.current.backcolor,),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(CupertinoIcons.sunset, color: WHITE,),
                      ),
                    ),
                  ],
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
                            child: comfortatext('10:22', 18, color: WHITE)
                        )
                    )
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 67,
                          child: Align(
                            alignment: Alignment.center,
                              child: comfortatext('10:22', 18, color: WHITE)
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
                child: comfortatext('air quality', 20, color: WHITE),
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
                          color: aqi_colors[1],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: comfortatext('1', 40, color: WHITE),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 120,
                              child: comfortatext('good', 17, color: WHITE,
                              align: TextAlign.center)
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        aqiDataPoints("pm2.5", 55.4),
                        aqiDataPoints("pm10", 55.4),
                        aqiDataPoints("o3", 55.4),
                        aqiDataPoints("No2", 55.4),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      )
    ],
  ),
);

Widget buildHihiDays(var data) => SliverFixedExtentList(
    itemExtent: 452.0,
    delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
        if (index < data.days.length) {
          final day = data.days[index];
            return Container(
                decoration: BoxDecoration(
                    color: darken(data.current.backcolor, (index % 2) * 0.05),
                    border: const Border.symmetric(vertical: BorderSide(
                        width: 1.2,
                        color: WHITE
                    ))
                ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      day.name,
                      style: GoogleFonts.comfortaa(
                        color: WHITE,
                        fontSize: 30,
                        height: 0.7,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50, bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Image.asset(
                            'assets/icons/' + day.icon,
                            fit: BoxFit.contain,
                            height: 45,
                          ),
                        ),
                      Flexible(
                        fit: FlexFit.loose,
                          child: comfortatext(day.text + ' ' + day.minmaxtemp, 25, color: WHITE)
                        )
                      ],
                    ),
                  ),
                  buildHours(day.hourly, data.settings, data.current.accentcolor),
                ],
              )
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
        height: 240,
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
                height: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top:20, left: 9, right: 9),
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


