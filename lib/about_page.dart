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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:overmorrow/Icons/overmorrow_weather_icons3_icons.dart';
import 'package:overmorrow/ui_helper.dart';
import '../l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:url_launcher/url_launcher.dart';

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

class AboutPage extends StatefulWidget {
  final settings;
  final ColorScheme palette;

  const AboutPage({Key? key, required this.settings, required this.palette}) : super(key: key);

  @override
  _AboutPageState createState() =>
      _AboutPageState(settings: settings, palette: palette);
}

class _AboutPageState extends State<AboutPage> {
  final settings;
  final ColorScheme palette;

  String version = "--";
  String buildNumber = "--";

  _AboutPageState({required this.settings, required this.palette});

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        version = info.version;
        buildNumber = info.buildNumber;
      });
    });
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                AppLocalizations.of(context)!.about, 30, settings,
                color: palette.primary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 80.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          margin: const EdgeInsets.only(top: 30, bottom: 20),
                          padding: const EdgeInsets.only(top: 3, right: 3),
                          decoration: BoxDecoration(
                            color: palette.secondaryContainer,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Icon(OvermorrowWeatherIcons3.partly_cloudy, size: 100, color: palette.primary,),
                        ),
                      ),
                      Center(child: comfortatext("Overmorrow", 30, settings, color: palette.primary, weight: FontWeight.w500)),
                      const SizedBox(height: 45,),

                      Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _launchUrl("https://github.com/bmaroti9/Overmorrow");
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: palette.primary,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.code, color: palette.onPrimary, size: 21),
                                  const SizedBox(width: 6,),
                                  comfortatext(AppLocalizations.of(context)!.sourceCodeLowercase, 18, settings, color: palette.onPrimary)
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'maroti.devel@gmail.com',
                              );
                              launchUrl(emailLaunchUri);
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: palette.outlineVariant, width: 2)
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.email_outlined, color: palette.onSurface, size: 20),
                                  const SizedBox(width: 6,),
                                  comfortatext(AppLocalizations.of(context)!.emailLowercase, 18, settings, color: palette.onSurface)
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _launchUrl("https://github.com/bmaroti9/Overmorrow/issues");
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: palette.outlineVariant, width: 2)
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bug_report_outlined, color: palette.onSurface, size: 21,),
                                  const SizedBox(width: 6,),
                                  comfortatext(AppLocalizations.of(context)!.reportAnIssueLowercase, 18, settings, color: palette.onSurface)
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _launchUrl("https://paypal.me/miklosmaroti");
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: palette.outlineVariant, width: 2)
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.volunteer_activism_outlined, color: palette.onSurface, size: 21,),
                                  const SizedBox(width: 6,),
                                  comfortatext(AppLocalizations.of(context)!.donateLowercase, 18, settings, color: palette.onSurface)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),


                      Container(
                        decoration: BoxDecoration(
                          color: palette.surfaceContainer,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(33), topRight: Radius.circular(33),
                          bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                        ),
                        margin: const EdgeInsets.only(top: 30),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Icon(Icons.verified_outlined, color: palette.onSurface),
                            const SizedBox(width: 10,),
                            comfortatext(AppLocalizations.of(context)!.versionUppercase, 18, settings, color: palette.onSurface),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                comfortatext(version, 18, settings, color: palette.primary),
                                comfortatext("+$buildNumber", 15, settings, color: palette.outline),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>
                                  ApiAndServicesPage(settings: settings, palette: palette))
                          );
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(Icons.handyman_outlined, color: palette.onSurface),
                              const SizedBox(width: 10,),
                              comfortatext(AppLocalizations.of(context)!.apiAndServices, 18, settings, color: palette.onSurface),
                              const Spacer(),
                              Icon(Icons.keyboard_arrow_right_rounded, color: palette.onSurface),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: palette.surfaceContainer,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(33), bottomRight: Radius.circular(33)),
                        ),
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Icon(Icons.balance, color: palette.onSurface),
                            const SizedBox(width: 10,),
                            comfortatext(AppLocalizations.of(context)!.licenseUppercase, 18, settings, color: palette.onSurface),
                            const Spacer(),
                            comfortatext("GPL-3.0 license", 18, settings, color: palette.outline),
                          ],
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ApiAndServicesPage extends StatefulWidget {
  final settings;
  final ColorScheme palette;

  const ApiAndServicesPage({Key? key, required this.settings, required this.palette}) : super(key: key);

  @override
  _ApiAndServicesPageState createState() =>
      _ApiAndServicesPageState(settings: settings, palette: palette);
}

class _ApiAndServicesPageState extends State<ApiAndServicesPage> {
  final settings;
  final ColorScheme palette;
  _ApiAndServicesPageState({required this.settings, required this.palette});

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      color: palette.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: palette.primary,),
                onPressed: () {
                  goBack();
                }),
            title: comfortatext(
                AppLocalizations.of(context)!.apiAndServices, 30, settings,
                color: palette.primary),
            backgroundColor: palette.surface,
            pinned: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(33),
                     color: palette.surfaceContainer
                   ),
                   padding: const EdgeInsets.all(30),
                   margin: const EdgeInsets.only(top: 20),
                   width: double.infinity,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       comfortatext(AppLocalizations.of(context)!.weatherDataLowercase, 20, settings, color: palette.onSurface),
                       const SizedBox(height: 20,),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           _launchUrl("https://open-meteo.com");
                         },
                         child: comfortatext("open-meteo", 17, settings, color: palette.secondary,
                             decoration: TextDecoration.underline),
                       ),
                       const SizedBox(height: 10,),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           _launchUrl("https://www.weatherapi.com/");
                         },
                         child: comfortatext("weatherapi", 17, settings, color: palette.secondary,
                             decoration: TextDecoration.underline),
                       ),
                       const SizedBox(height: 10,),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           _launchUrl("https://api.met.no/");
                         },
                         child: comfortatext("met-norway", 17, settings, color: palette.secondary,
                             decoration: TextDecoration.underline),
                        ),
                      ],
                     ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(33),
                          color: palette.surfaceContainer
                      ),
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.only(top: 6),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          comfortatext(AppLocalizations.of(context)!.radar, 20, settings, color: palette.onSurface),
                          const SizedBox(height: 20,),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://www.rainviewer.com/api.html");
                            },
                            child: comfortatext("rainviewer", 17, settings, color: palette.secondary,
                                decoration: TextDecoration.underline),
                          ),
                          const SizedBox(height: 10,),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://carto.com/");
                            },
                            child: comfortatext("carto", 17, settings, color: palette.secondary,
                                decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(33),
                        color: palette.surfaceContainer
                    ),
                    padding: const EdgeInsets.all(30),
                    margin: const EdgeInsets.only(top: 6),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        comfortatext(AppLocalizations.of(context)!.imagesLowercase, 20, settings, color: palette.onSurface),
                        const SizedBox(height: 20,),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _launchUrl("https://unsplash.com/");
                          },
                          child: comfortatext("unsplash", 17, settings, color: palette.secondary,
                              decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


