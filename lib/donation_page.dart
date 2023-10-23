import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/ui_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dayforcast.dart';
import 'package:flutter_donation_buttons/flutter_donation_buttons.dart';

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
          title: comfortatext('Donate', 25),
          leading:
          IconButton(
            onPressed: (){
              goBack();
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body:Container(
        color: color,
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'If you enjoy using Overmorrow,'
                              ' then please consider showing your support '
                              'by donating.',
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
                          'It really helps me out and keeps the app free and amazing.',
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
                          padding: const EdgeInsets.only(top: 30, bottom: 40, left: 10),
                          child: Text(
                            'Thank You! -Balint',
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
                KofiButton(kofiName: "flajt",kofiColor: KofiColor.Red,onDonation: (){
                  print("On Donation!");
                }),
                PayPalButton(paypalButtonId: "T6NT2YYTVX6VS"),
                PatreonButton(patreonName: "buttonshy"),
                // Just someone I stumbled accross on Patreon as an example, not affiliaited with him
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchUrl() async {
  final url = Uri.parse(
      'https://pub.dev/packages/home_widget');
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}