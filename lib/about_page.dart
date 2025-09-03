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
import 'package:flutter_svg/svg.dart';
import 'package:home_widget/home_widget.dart';
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

  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() =>
      _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String widgetBackgroundState = "--";

  String version = "--";
  String buildNumber = "--";

  //this is all for debugging the background worker
  Future<void> getWidgetBackgroundState() async {
    widgetBackgroundState = (await HomeWidget.getWidgetData<String>("widget.backgroundUpdateState", defaultValue: "unknown")) ?? "unknown";
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        version = info.version;
        buildNumber = info.buildNumber;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_){
      getWidgetBackgroundState();
    });
  }

  void goBack() {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  goBack();
                }),
            title: Text(AppLocalizations.of(context)!.about,
                  style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                          margin: const EdgeInsets.only(top: 30, bottom: 10),
                          padding: const EdgeInsets.only(top: 3, right: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: SvgPicture.asset(
                              "assets/weather_icons/partly_cloudy.svg",
                              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                      Center(child: Text("Overmorrow", style: TextStyle(color: Theme.of(context).colorScheme.primary,
                          fontSize: 28, fontWeight: FontWeight.w600))),
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
                                color: Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.code, color: Theme.of(context).colorScheme.onTertiary, size: 21),
                                  const SizedBox(width: 6,),
                                  Text(AppLocalizations.of(context)!.sourceCodeLowercase,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onTertiary, fontSize: 18))
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
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2)
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.email_outlined, size: 20),
                                  const SizedBox(width: 6,),
                                  Text(AppLocalizations.of(context)!.emailLowercase,
                                      style: const TextStyle(fontSize: 18))
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
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2)
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bug_report_outlined, size: 21,),
                                  const SizedBox(width: 6,),
                                  Text(AppLocalizations.of(context)!.reportAnIssueLowercase,
                                      style: const TextStyle(fontSize: 18))
                                  ]
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
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2)
                              ),
                              padding: const EdgeInsets.only(left: 13, right: 13, top: 11, bottom: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.volunteer_activism_outlined, size: 21,),
                                  const SizedBox(width: 6,),
                                  Text(AppLocalizations.of(context)!.donateLowercase,
                                      style: const TextStyle(fontSize: 18))
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),


                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(33), topRight: Radius.circular(33),
                          bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                        ),
                        margin: const EdgeInsets.only(top: 30),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_outlined, ),
                            const SizedBox(width: 10,),
                            Text(AppLocalizations.of(context)!.versionUppercase,
                                style: const TextStyle(fontSize: 18)),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(version,
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18)),
                                Text("+$buildNumber",
                                    style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ServicesPage())
                          );
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              const Icon(Icons.handyman_outlined, ),
                              const SizedBox(width: 10,),
                              Text(AppLocalizations.of(context)!.apiAndServices,
                                  style: const TextStyle(fontSize: 18)),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_right_rounded, ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(33), bottomRight: Radius.circular(33)),
                        ),
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.balance),
                            const SizedBox(width: 10,),
                            Text(AppLocalizations.of(context)!.licenseUppercase,
                                style: const TextStyle(fontSize: 18)),
                            const Spacer(),
                            Text("GPL-3.0 license",
                                style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 18)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {

                                return AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  content: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return Column(
                                        children: [
                                          Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.tertiary),
                                          const SizedBox(height: 40,),
                                          Text(widgetBackgroundState,
                                              style: const TextStyle(fontSize: 18)),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              }
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(50)
                          ),
                          margin: const EdgeInsets.only(top: 40, bottom: 100),
                          padding: const EdgeInsets.all(14),
                          child: const Row(
                            children: [
                              Text("worker logs",
                                  style: TextStyle(fontSize: 18)),
                              Spacer(),
                              Icon(Icons.open_in_new, size: 18,),
                            ],
                          ),
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


class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                }),
            title: Text(AppLocalizations.of(context)!.apiAndServices,
              style: const TextStyle(fontSize: 30),),
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                     color: Theme.of(context).colorScheme.surfaceContainer
                   ),
                   padding: const EdgeInsets.all(30),
                   margin: const EdgeInsets.only(top: 20),
                   width: double.infinity,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(AppLocalizations.of(context)!.weatherDataLowercase,
                         style: const TextStyle(fontSize: 20),),
                       const SizedBox(height: 20,),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           _launchUrl("https://open-meteo.com");
                         },
                         child: Text("open-meteo",
                           style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 17,
                             decoration: TextDecoration.underline,),),
                       ),
                       const SizedBox(height: 10,),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           _launchUrl("https://www.weatherapi.com/");
                         },
                         child: Text("weatherapi",
                           style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 17,
                             decoration: TextDecoration.underline,),),
                       ),
                       const SizedBox(height: 10,),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           _launchUrl("https://api.met.no/");
                         },
                         child: Text("met-norway",
                           style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 17,
                             decoration: TextDecoration.underline,),),
                        ),
                      ],
                     ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(33),
                          color: Theme.of(context).colorScheme.surfaceContainer
                      ),
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.only(top: 6),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.radar,
                            style: const TextStyle(fontSize: 20,),),
                          const SizedBox(height: 20,),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://www.rainviewer.com/api.html");
                            },
                            child: Text("rainviewer",
                              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 17,
                                decoration: TextDecoration.underline,),),
                          ),
                          const SizedBox(height: 10,),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _launchUrl("https://carto.com/");
                            },
                            child: Text("carto",
                              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 17,
                                decoration: TextDecoration.underline,),),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(33),
                        color: Theme.of(context).colorScheme.surfaceContainer
                    ),
                    padding: const EdgeInsets.all(30),
                    margin: const EdgeInsets.only(top: 6),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.imagesLowercase,
                          style: const TextStyle(fontSize: 20),),
                        const SizedBox(height: 20,),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _launchUrl("https://unsplash.com/");
                          },
                          child: Text("unsplash",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 17,
                              decoration: TextDecoration.underline,),),
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


