import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/dayforcast.dart';
import 'package:hihi_haha/ui_helper.dart';

import 'package:flutter_donation_buttons/flutter_donation_buttons.dart';
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
  'Cloudy Night'];

final imageLink = [
  'https://unsplash.com/photos/time-lapse-photography-of-stars-at-nighttime-YvOT1lJ0NPQ',
  'https://unsplash.com/photos/ocean-under-clouds-Plkff-dVfNM',
  'https://unsplash.com/photos/white-clouds--qGKIX1Vxtk',
  'https://unsplash.com/photos/selective-focus-photography-of-gray-clouds-4C6Rp23RjnE',
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

  const DonationPage({Key? key, required this.color,
  required this.settings}) : super(key: key);

  @override
  _DonationPageState createState() => _DonationPageState(color: color,
  settings: settings);
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: darken(color, 0.3),
          title: comfortatext(translation('Donate', settings[0]), 25),
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body:Container(
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
                        child: Text(
                          translation('Overmorrow is a free app. :)', settings[0]),
                        style: GoogleFonts.comfortaa(
                          color: WHITE,
                          fontSize: 21,
                          fontWeight: FontWeight.w300,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 10,
                        textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          translation('Support me on Patreon, to help me keep it that way!',
                              settings[0]),
                          style: GoogleFonts.comfortaa(
                            color: WHITE,
                            fontSize: 21,
                            fontWeight: FontWeight.w300,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          maxLines: 10,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 40),
                          child: Text(
                            translation('Thank You! -Balint', settings[0]),
                            style: GoogleFonts.comfortaa(
                              color: WHITE,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                PatreonButton(
                  patreonName: "buttonshy",
                  text: translation('Support me on Patreon', settings[0]),
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all<double>(0),
                    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
                    backgroundColor: MaterialStateProperty.all(const Color(0xffF96854)),
                    // <-- Button color
                    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return darken(const Color(0xffF96854), 0.2);
                      }
                      return null; // <-- Splash color
                    }),
                  ),
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

  const InfoPage({Key? key, required this.color,
    required this.settings}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState(color: color,
      settings: settings);
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: darken(color, 0.3),
          title: comfortatext('About', 25),
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
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
                      image: AssetImage(
                          'assets/backdrops/very_clear.jpg'),
                      fit: BoxFit.cover,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              comfortatext(
                  //'Welcome\nto\nMyWorld\nHello\nWorld\n',
                '"Overmorrow is a beautiful minimalist weather app."',
                  26),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: darken(color),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top:10, bottom: 10),
                          child: comfortatext('Feautures:', 20),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            comfortatext('\u2022 accurate weather forecast',22),
                            comfortatext('\u2022 open source',22),
                            comfortatext('\u2022 no ads',22),
                            comfortatext('\u2022 no data collected',22),
                            comfortatext('\u2022 minimalist design',22),
                            comfortatext('\u2022 dynamically adapting color scheme',22),
                            comfortatext('\u2022 languages support',22),
                            comfortatext('\u2022 place search',22),
                            comfortatext('\u2022 weather for current location',22),
                            comfortatext('\u2022 unit swapping',22),
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
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Column(
                    children: [
                    Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top:20, bottom: 10),
                      child: comfortatext('Developed by:', 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: comfortatext('Balint',22),
                        ),
                        ElevatedButton(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.all<double>(0),
                            padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
                            backgroundColor: MaterialStateProperty.all(Colors.orange),
                            // <-- Button color
                            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(MaterialState.pressed)) {
                                return darken(Colors.orange, 0.2);
                              }
                              return null; // <-- Splash color
                            }),
                          ),
                          onPressed: () async { await launchEmail(); },
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 3),
                                child: Icon(Icons.mail_outline,color: WHITE,),
                              ),
                              comfortatext('contact me', 20, color: WHITE)],
                          )
                        )
                      ],
                    ),
                  ),
                  ]
                )
              ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: darken(color),
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top:20, bottom: 10),
                            child: comfortatext('Weather data from:', 20),
                          ),
                      ),
                      TextButton(
                          onPressed: () async { await _launchUrl('https://www.weatherapi.com/'); },
                          child: comfortatext('www.weatherapi.com', 20, color: Colors.orange)
                      )
                  ]
                ),
              ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: darken(color),
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top:20, bottom: 10),
                            child: comfortatext('Images used:', 20),
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
                                  onPressed: () { _launchUrl(imageLink[index]); },
                                  child: comfortatext(imageText[index], 20,
                                      color: Colors.orange),
                                ),
                              ),
                            );
                          },
                        )
                      ]
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}

Future<void> launchEmail() async {
  final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'bmaroti9@gmail.com', // Replace with your email address
      queryParameters: {'subject': 'Feedback or Support Request'} // Optional subject
  );

  if (await canLaunchUrl(_emailLaunchUri)) {
    await launchUrl(_emailLaunchUri);
  } else {
    throw 'Could not launch email';
  }
}
Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}