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
  'Cloudy Night'
];

final imageLink = [
  'https://unsplash.com/photos/time-lapse-photography-of-stars-at-nighttime-YvOT1lJ0NPQ',
  'https://unsplash.com/photos/ocean-under-clouds-Plkff-dVfNM',
  'https://unsplash.com/photos/blue-sea-under-blue-sky-during-daytime-XNZRf6rrKm4',
  'https://unsplash.com/photos/a-cloudy-sky-with-some-clouds-UT5FSjTrhEQ',
  'https://unsplash.com/photos/silhouette-of-trees-and-sea-L-HxY2XlaaY',
  'https://unsplash.com/photos/water-droplets-on-clear-glass-1YHXFeOYpN0',
  'https://unsplash.com/photos/snow-covered-trees-and-road-during-daytime-wyM1KmMUSbA',
  'https://unsplash.com/photos/a-view-of-a-plane-through-a-rain-covered-window-UsYOap7yIMg',
  'https://unsplash.com/photos/selective-photography-of-white-thunder-nbqlWhOVu6k',
  'https://unsplash.com/photos/snowy-forest-on-mountainside-during-daytime-t4hA-zCALUQ',
  'https://unsplash.com/photos/green-trees-on-mountain-under-white-clouds-during-daytime-obQacWYxB1I',
  'https://unsplash.com/photos/bokeh-photography-of-snows-SH4GNXNj1RA',
  'https://unsplash.com/photos/dew-drops-on-glass-panel-bWtd1ZyEy6w',
  'https://unsplash.com/photos/blue-and-white-starry-night-sky-NpF9JLGYfeQ'
];

class DonationPage extends StatefulWidget {
  final Color color;
  final settings;

  const DonationPage({Key? key, required this.color, required this.settings})
      : super(key: key);

  @override
  _DonationPageState createState() =>
      _DonationPageState(color: color, settings: settings);
}

class _DonationPageState extends State<DonationPage> {
  final color;
  final settings;

  _DonationPageState({required this.color, required this.settings});

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: darken(color, 0.3),
          title: comfortatext(translation('Donate', settings["Language"]), 25, settings),
          leading: IconButton(
            onPressed: () {
              goBack();
            },
            icon: const Icon(
              Icons.arrow_back,
              color: WHITE,
            ),
          )),
      body: Container(
        color: darken(color),
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
                            'Overmorrow is a free app. :)', settings["Language"]), 21, settings)
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: comfortatext(translation(
                            'Support me on Patreon, to help me keep it that way!',
                            settings["Language"]), 21, settings)
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 40),
                          child: comfortatext(translation('Thank You! -Balint',
                              settings["Language"]), 18, settings)
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      padding: const EdgeInsets.all(10),
                      backgroundColor: Color(0xfff96854),
                      //side: BorderSide(width: 3, color: main),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await _launchUrl('https://www.patreon.com/MarotiDevel');
                    },
                    child: comfortatext(translation('Support me on Patreon', settings["Language"]),
                        20, settings),
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
  final Color color;
  final settings;

  const InfoPage({Key? key, required this.color, required this.settings})
      : super(key: key);

  @override
  _InfoPageState createState() =>
      _InfoPageState(color: color, settings: settings);
}

class _InfoPageState extends State<InfoPage> {
  final color;
  final settings;

  _InfoPageState({required this.color, required this.settings});

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color,
        appBar: AppBar(
            toolbarHeight: 65,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            elevation: 0,
            leadingWidth: 50,
            backgroundColor: darken(color, 0.3),
            title: comfortatext(translation('About', settings["Language"]), 25, settings),
            leading: IconButton(
              onPressed: () {
                goBack();
              },
              icon: const Icon(
                Icons.arrow_back,
                color: WHITE,
              ),
            )),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 40),
                  child: Container(
                    height: 200.0,
                    width: 200.0,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/backdrops/very_clear_a.jpg'),
                        fit: BoxFit.cover,
                      ),
                      shape: BoxShape.circle
                    ),
                  ),
                ),
                comfortatext(
                    translation(
                        'Overmorrow is a beautiful minimalist weather app.',
                        settings["Language"]),
                    26, settings),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: darken(color),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                            child: comfortatext(
                                translation('Features:', settings["Language"]), 20, settings),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              comfortatext(
                                  '\u2022${translation('accurate weather forecast', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('open source', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('no ads', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('no data collected', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('minimalist design', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('dynamically adapting color scheme', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('languages support', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('place search', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('weather for current location', settings["Language"])}',
                                  22, settings),
                              comfortatext(
                                  '\u2022${translation('unit swapping', settings["Language"])}',
                                  22, settings),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: darken(color),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: comfortatext(
                                translation('Developed by:', settings["Language"]), 20, settings),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: comfortatext('Balint', 22, settings),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: comfortatext(
                                    '(maroti.devel@gmail.com)', 18, settings),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                      onPressed: () async {
                                        await _launchUrl(
                                            'https://github.com/bmaroti9/Overmorrow');
                                      },
                                      child: comfortatext('source code', 20, settings,
                                          color: Colors.orange)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ])),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: darken(color),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: comfortatext(
                              translation('Weather data from:', settings["Language"]),
                              20, settings),
                        ),
                      ),
                      TextButton(
                          onPressed: () async {
                            await _launchUrl(
                                'https://open-meteo.com');
                          },
                          child: comfortatext('open-meteo.com', 20, settings,
                              color: Colors.orange)),
                      TextButton(
                          onPressed: () async {
                            await _launchUrl(
                                'https://www.rainviewer.com/api.html');
                          },
                          child: comfortatext('www.rainviewer.com', 20, settings,
                              color: Colors.orange)),
                      TextButton(
                          onPressed: () async {
                            await _launchUrl('https://www.weatherapi.com/');
                          },
                          child: comfortatext('www.weatherapi.com', 20, settings,
                              color: Colors.orange))
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: darken(color),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 20, bottom: 10),
                              child: comfortatext(
                                  translation('Images used:', settings["Language"]), 20, settings),
                            ),
                          ),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: imageText.length,
                            itemExtent: 40,
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () {
                                      _launchUrl(imageLink[index]);
                                    },
                                    child: comfortatext(
                                        translation(
                                            imageText[index], settings["Language"]),
                                        20, settings,
                                        color: Colors.orange),
                                  ),
                                ),
                              );
                            },
                          )
                        ]),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}
