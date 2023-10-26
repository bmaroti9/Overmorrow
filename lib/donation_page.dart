import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/dayforcast.dart';
import 'package:hihi_haha/ui_helper.dart';

import 'package:flutter_donation_buttons/flutter_donation_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

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
                          'Overmorrow is a free app. :)',
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
                          'Support me on Patreon, to help me keep it that way!',
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
                
                PatreonButton(
                  patreonName: "buttonshy",
                  text: 'Support me on Patron',
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