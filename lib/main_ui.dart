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
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/decoders/decode_wapi.dart';
import 'package:overmorrow/main_screens.dart';
import 'package:overmorrow/radar.dart';
import 'package:overmorrow/settings_page.dart';
import 'ui_helper.dart';

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

    return NewMain(data: data, updateLocation: updateLocation, context: context,
        key: Key("${data.place}, ${data.current.surface} ${data.current.image}"),);

  }
}


class ParrallaxBackground extends StatelessWidget {
  final Image image;
  final Color color;

  const ParrallaxBackground({Key? key, required this.image, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Container(
          color: color,
          child: Opacity(
            opacity: value,
            child: image,
          ),
        );
      },
    );
  }
}


Widget Circles(double width, var data, double bottom, color, {align = Alignment.center}) {
  return Align(
    alignment: align,
    child: SizedBox(
      width: width,
        child: Container(
            padding: const EdgeInsets.only(top: 25, left: 4, right: 4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.feels_like}°',
                    undercaption: translation('Feels like', data.settings["Language"]),
                    extra: '',
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: -1,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.humidity}',
                    undercaption: translation('Humidity', data.settings["Language"]),
                    extra: '%',
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: -1,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.precip}',
                    undercaption: translation('precip.', data.settings["Language"]),
                    extra: data.settings["Precipitation"],
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: -1,
                  ),
                  DescriptionCircle(
                    color: color,
                    text: '${data.current.wind}',
                    undercaption: translation('Wind', data.settings["Language"]),
                    extra: data.settings["Wind"],
                    size: width,
                    settings: data.settings,
                    bottom: bottom,
                    dir: data.current.wind_dir + 180,
                  ),
                ]
            )
        )
    ),
  );
}

Widget NewTimes(var data, bool divider) => Column(
  children:
    [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(translation('sunrise/sunset', data.settings["Language"]), 19, data.settings,
                    color: data.current.outline),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 2, color: data.current.secondary)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Icon(CupertinoIcons.sunrise, color: data.current.secondary,),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(CupertinoIcons.sunset, color: data.current.secondary,),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            return Container(
                              color: data.current.secondary,
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
                            child: comfortatext(data.sunstatus.sunrise, 18, data.settings,
                                color: data.current.outline)
                        )
                    )
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 90,
                          child: Align(
                            alignment: Alignment.center,
                              child: comfortatext(data.sunstatus.sunset, 18, data.settings,
                                  color: data.current.outline)
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
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 19, top: 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: comfortatext(translation('air quality', data.settings["Language"]), 20, data.settings,
                    color: data.current.outline),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                //border: Border.all(width: 1.2, color: data.current.outline)
                color: data.current.container
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
                          color: data.current.surface,
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
                              'hazardous'][data.aqi.aqi_index - 1], data.settings["Language"]), 16, data.settings,
                                  color: data.current.outline, align: TextAlign.center)
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        aqiDataPoints("PM2.5", data.aqi.pm2_5, data),
                        aqiDataPoints("PM10", data.aqi.pm10, data),
                        aqiDataPoints("O3", data.aqi.o3, data),
                        aqiDataPoints("NO2", data.aqi.no2, data),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      RadarMap(data: data, key: Key(data.place),),
      Visibility(
        visible: divider,
        child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 30, left: 30),
            child: Container(
              height: 2,
              color: data.current.container,
            ),
        ),
      ),
    ],
);

Widget buildHihiDays(var data) => ListView.builder(
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
    itemBuilder: (BuildContext context, int index) {
        if (index < 3) {
          final day = data.days[index];
            return Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 10),
                    child: comfortatext(day.name, 19, data.settings, color: data.current.outline)
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: day.mm_precip > 0.1 ? data.current.container : data.current.backcolor,
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
                              comfortatext(day.text, 22, data.settings, color: data.current.outline),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                      padding: const EdgeInsets.only(top:7,bottom: 7, left: 7, right: 5),
                                      decoration: BoxDecoration(
                                        //border: Border.all(color: Colors.blueAccent)
                                          color: data.current.surface,
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                    child: comfortatext(day.minmaxtemp, 18, data.settings, color: data.current.backcolor)
                                ),
                              )
                              ],
                            ),
                            Visibility(
                              visible: day.mm_precip > 0.1,
                              child: RainWidget(data, day)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 6, top: 15, bottom: 30),
                    child: Container(
                      height: 85,
                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.2, color: data.current.secondary),
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
                                      Icon(Icons.water_drop_outlined,
                                        color: data.current.secondary, size: 21),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10, top: 2),
                                        child: comfortatext('${day.precip_prob}%', 19, data.settings,
                                        color: data.current.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.water_drop, color: data.current.secondary, size: 21),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2, left: 10),
                                        child: comfortatext(day.total_precip.toString() +
                                            data.settings["Precipitation"], 19, data.settings,
                                        color: data.current.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.wind, color: data.current.secondary, size: 21,),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2, left: 10),
                                        child: comfortatext('${day.windspeed} ${data
                                            .settings["Wind"]}', 19, data.settings,
                                        color: data.current.secondary),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5, right: 3),
                                        child: RotationTransition(
                                          turns: AlwaysStoppedAnimation(day.wind_dir / 360),
                                          child: Icon(CupertinoIcons.arrow_up_circle_fill, color: data.current.secondary, size: 18,)
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.sun_min,
                                        color: data.current.secondary, size: 21),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2, left: 10),
                                        child: comfortatext('${day.uv} UV', 19, data.settings,
                                        color: data.current.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                          );
                        }
                      ),
                    ),
                  ),
                  buildHours(day.hourly, data),
                ],
              ),
            );
          }
        return null;
    },
);

Widget buildGlanceDay(var data) => Padding(
  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
  child: Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Align(
          alignment: Alignment.centerLeft,
          child: comfortatext(translation('Daily', data.settings["Language"]), 19, data.settings, color: data.current.outline),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(width: 1.2, color: data.current.secondary),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.days.length - 3,
          itemBuilder: (context, index) {
            final day = data.days[index + 3];
            const int rain_limit = 2;
            return Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  color: day.mm_precip > rain_limit ? data.current.container : data.current.backcolor,
                ),
                padding: EdgeInsets.all(day.mm_precip > rain_limit ? 8 : 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 75,
                          width: 75,
                          decoration: BoxDecoration(
                              color: day.mm_precip > rain_limit ? data.current.backcolor : data.current.container,
                              borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              comfortatext(day.name, 18, data.settings, color: data.current.outline),
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
                            width: 52,
                            decoration: BoxDecoration(
                                color: data.current.surface,
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
                                  border: Border.all(color: data.current.secondary, width: 1.2)
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.water_drop_outlined,
                                          color: data.current.secondary, size: 18,),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, right: 5),
                                          child: comfortatext('${day.precip_prob}%', 17, data.settings,
                                          color: data.current.secondary),
                                        ),
                                        Icon(
                                          Icons.water_drop, color: data.current.secondary, size: 18,),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, right: 2),
                                          child: comfortatext(day.total_precip.toString() +
                                              data.settings["Precipitation"], 17, data.settings, color: data.current.secondary),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.wind, color: data.current.secondary, size: 18,),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 2, right: 2),
                                          child: comfortatext('${day.windspeed} ${data
                                              .settings["Wind"]}', 17, data.settings, color: data.current.secondary),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(left: 3, right: 3, bottom: 1),
                                            child: RotationTransition(
                                                turns: AlwaysStoppedAnimation(day.wind_dir / 360),
                                                child: Icon(CupertinoIcons.arrow_up_circle_fill,
                                                  color: data.current.secondary, size: 16,)
                                            )
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
                    Visibility(
                        visible: day.mm_precip > rain_limit,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: RainWidget(data, day),
                        )
                    ),
                  ],
                ),
              ),
            );
          }
        )
      ),
    ],
  ),
);

Widget buildHours(List<dynamic> hours, data) => SizedBox(
  height: 285,
  child: ListView(
    physics: const BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    shrinkWrap: true,
    children: hours.map<Widget>((hour) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: comfortatext('${hour.temp}°', 22, data.settings, color: data.current.surface),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 15,
                height: 100,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: data.current.secondary,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
              ),
              Container(
                width: 15,
                height: temp_multiply_for_scale(hour.temp, data.settings['Temperature']!),
                decoration: BoxDecoration(
                    color: data.current.secondary,
                    borderRadius: const BorderRadius.all(Radius.circular(20))
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
            child: comfortatext(hour.time, 17, data.settings, color: data.current.surface)
          )
        ],
      );
    }).toList(),
  ),
);

Widget providerSelector(settings, updateLocation, textcolor, highlight, primary,
    provider, latlng, real_loc) {
  return Padding(
    padding: const EdgeInsets.only(left: 23, right: 23, top: 15, bottom: 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(
                translation('Weather provider', settings["Language"]), 16,
                settings,
                color: textcolor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
            child: DropdownButton(
              underline: Container(),
              borderRadius: BorderRadius.circular(20),
              icon: Padding(
                padding: const EdgeInsets.only(left:5),
                child: Icon(Icons.arrow_drop_down_circle_outlined, color: primary, size: 22,),
              ),
              style: GoogleFonts.comfortaa(
                color: primary,
                fontSize: 18 * getFontSize(settings["Font size"]),
                fontWeight: FontWeight.w500,
              ),
              //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
              value: provider.toString(),
              items: ['weatherapi.com', 'open-meteo'].map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? value) async {
                SetData('weather_provider', value!);
                await updateLocation(latlng, real_loc);
              },
              isExpanded: true,
              dropdownColor: highlight,
              elevation: 0,
            ),
          ),
        ),
      ],
    ),
  );
}
