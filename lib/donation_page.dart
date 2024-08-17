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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:overmorrow/ui_helper.dart';

import 'package:url_launcher/url_launcher.dart';

final imageText = [
  'Clear Night',
  'Partly Cloudy',
  'Clear Sky',
  'Overcast',
  'Haze',
  'Rain',
  'Sleet',
  'Drizzle',
  'Thunderstorm',
  'Heavy Snow',
  'Fog',
  'Snow',
  'Heavy Rain',
  'Cloudy Night',
  'Error Screen'
];

final imageLink = [
  'https://unsplash.com/photos/time-lapse-photography-of-stars-at-nighttime-YvOT1lJ0NPQ',
  'https://unsplash.com/photos/ocean-under-clouds-Plkff-dVfNM',
  'https://unsplash.com/photos/blue-and-white-sky-d12K_FkCUN8',
  'https://unsplash.com/photos/view-of-calm-sea-nQM2oClouhY',
  'https://unsplash.com/photos/silhouette-of-trees-and-sea-L-HxY2XlaaY',
  'https://unsplash.com/photos/water-droplets-on-clear-glass-1YHXFeOYpN0',
  'https://unsplash.com/photos/snow-covered-trees-and-road-during-daytime-wyM1KmMUSbA',
  'https://unsplash.com/photos/a-view-of-a-plane-through-a-rain-covered-window-UsYOap7yIMg',
  'https://unsplash.com/photos/lightning-strike-on-the-sky-ley4Kf2iG7Y',
  'https://unsplash.com/photos/snowy-forest-on-mountainside-during-daytime-t4hA-zCALUQ',
  'https://unsplash.com/photos/green-trees-on-mountain-under-white-clouds-during-daytime-obQacWYxB1I',
  'https://unsplash.com/photos/bokeh-photography-of-snows-SH4GNXNj1RA',
  'https://unsplash.com/photos/dew-drops-on-glass-panel-bWtd1ZyEy6w',
  'https://unsplash.com/photos/blue-and-white-starry-night-sky-NpF9JLGYfeQ',
  'https://unsplash.com/photos/snow-covered-grass-at-daytime-KQWEuSh_VR0',
];

class DonationPage extends StatefulWidget {
  final Color primary;
  final Color back;
  final settings;

  const DonationPage({Key? key, required this.primary, required this.settings,
  required this.back}) : super(key: key);

  @override
  _DonationPageState createState() =>
      _DonationPageState(primary: primary, settings: settings, back: back);
}

class _DonationPageState extends State<DonationPage> {
  final primary;
  final settings;
  final back;

  _DonationPageState({required this.back, required this.settings, required this.primary});

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    List<Color> colors = getColors(primary, back, settings, 0);

    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: colors[0],
          title: comfortatext(translation('Donate', settings["Language"]), 25, settings,
          color: colors[2]),
          leading: IconButton(
            onPressed: () {
              goBack();
            },
            icon: Icon(
              Icons.arrow_back,
              color: colors[2],
            ),
          )),
      body: Container(
        color: colors[0],
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/icons/Overmorrow_white_classic.png',
                    fit: BoxFit.contain,
                    height: 100,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: comfortatext(translation(
                            'Overmorrow is a free app. :)', settings["Language"]), 21, settings,
                            color: colors[2])
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: comfortatext(translation(
                            'Support me on Patreon, to help me keep it that way!',
                            settings["Language"]), 21, settings,
                            color: colors[2])
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 40),
                          child: comfortatext(translation('Thank You! -Balint',
                              settings["Language"]), 18, settings,
                              color: colors[2])
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      padding: const EdgeInsets.all(15),
                      backgroundColor: Color(0xfff96854),
                      //side: BorderSide(width: 3, color: main),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await _launchUrl('https://www.patreon.com/MarotiDevel');
                    },
                    child: comfortatext(translation('Support me on Patreon', settings["Language"]),
                        20, settings, color: WHITE),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoPage extends StatefulWidget {
  final Color primary;
  final Color surface;
  final settings;
  final onSurface;
  final hihglight;

  const InfoPage({Key? key, required this.primary, required this.settings, required this.surface, required this.onSurface,
  required this.hihglight})
      : super(key: key);

  @override
  _InfoPageState createState() =>
      _InfoPageState(primary: primary, settings: settings, surface: surface, highlight: hihglight, onSurface: onSurface);
}

class _InfoPageState extends State<InfoPage> {
  final primary;
  final settings;
  final surface;
  final onSurface;
  final highlight;

  _InfoPageState({required this.primary, required this.settings, required this.surface, required this.onSurface,
  required this.highlight});

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: surface,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                translation('About', settings!["Language"]!), 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
          // Just some content big enough to have something to scroll.
          SliverToBoxAdapter(
            child: Container(
              color: surface,
              child: Padding(
                padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    comfortatext('OVRMRW', 40, settings, color: primary, weight: FontWeight.w400),

                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 10),
                      child: comfortatext(
                          "developed by:", 16,
                          settings,
                          color: onSurface),
                    ),
                    Row(
                      children: [
                        comfortatext("Balint", 23, settings, color: primary),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: comfortatext("(maroti.devel@gmail.com)", 16, settings, color: onSurface),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _launchUrl("https://github.com/bmaroti9/Overmorrow");
                            },
                            child: comfortatext("source code", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              _launchUrl("https://github.com/bmaroti9/Overmorrow/issues");
                            },
                            child: comfortatext("report an issue", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 10),
                      child: comfortatext(
                          "weather data:", 16,
                          settings,
                          color: onSurface),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _launchUrl("https://open-meteo.com");
                            },
                            child: comfortatext("open-meteo", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              _launchUrl("https://www.weatherapi.com/");
                            },
                            child: comfortatext("weatherapi", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              _launchUrl("https://www.rainviewer.com/api.html");
                            },
                            child: comfortatext("rainviewer", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Wrap(
                        spacing: 10,
                        children: [
                          comfortatext("all images used are from:", 16, settings, color: onSurface),
                          GestureDetector(
                            onTap: () {
                              _launchUrl("https://unsplash.com/");
                            },
                            child: comfortatext("unsplash", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ),
          ),
        ],
      ),
    );
  }
}


Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}
