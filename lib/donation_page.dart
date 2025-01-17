/*
Copyright (C) <2025>  <Balint Maroti>

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
import 'package:flutter/services.dart';
import 'package:overmorrow/ui_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatefulWidget {
  final primary;
  final settings;
  final surface;
  final onSurface;
  final highlight;


  const DonationPage({Key? key, required this.primary, required this.settings,
  required this.surface, required this.highlight, required this.onSurface}) : super(key: key);

  @override
  _DonationPageState createState() =>
      _DonationPageState(primary: primary, settings: settings, surface: surface,
          onSurface: onSurface, highlight: highlight);
}

class _DonationPageState extends State<DonationPage> {
  final primary;
  final settings;
  final surface;
  final onSurface;
  final highlight;


  _DonationPageState({required this.surface, required this.settings,
    required this.primary, required this.onSurface, required this.highlight});

  void goBack() {
    HapticFeedback.selectionClick();
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
                AppLocalizations.of(context)!.donate, 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Container(
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      comfortatext(AppLocalizations.of(context)!.donationPageText,
                         18, settings, color: onSurface),

                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.all(14),
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await _launchUrl('https://www.patreon.com/MarotiDevel');
                          },
                          child: comfortatext(AppLocalizations.of(context)!.supportOnPatreon,
                              18, settings, color: surface, weight: FontWeight.w600),
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
    HapticFeedback.selectionClick();
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
                AppLocalizations.of(context)!.about, 30, settings,
                color: surface),
            backgroundColor: primary,
            pinned: false,
          ),
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
                          AppLocalizations.of(context)!.developedBy, 16,
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
                              HapticFeedback.selectionClick();
                              _launchUrl("https://github.com/bmaroti9/Overmorrow");
                            },
                            child: comfortatext(AppLocalizations.of(context)!.sourceCode, 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://github.com/bmaroti9/Overmorrow/issues");
                            },
                            child: comfortatext(AppLocalizations.of(context)!.reportAnIssue, 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50, bottom: 10),
                      child: comfortatext(
                          AppLocalizations.of(context)!.weatherData, 16,
                          settings,
                          color: onSurface),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://open-meteo.com");
                            },
                            child: comfortatext("open-meteo", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://www.weatherapi.com/");
                            },
                            child: comfortatext("weatherapi", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://api.met.no/");
                            },
                            child: comfortatext("met-norway", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 10),
                      child: comfortatext(
                          "${AppLocalizations.of(context)!.radar}:", 16,
                          settings,
                          color: onSurface),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://www.rainviewer.com/api.html");
                            },
                            child: comfortatext("rainviewer", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://carto.com/");
                            },
                            child: comfortatext("carto", 16, settings, color: primary,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Wrap(
                        spacing: 10,
                        children: [
                          comfortatext(AppLocalizations.of(context)!.allImagesUsedAreFrom, 16, settings, color: onSurface),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
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
