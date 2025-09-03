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

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overmorrow/decoders/weather_data.dart';
import 'package:overmorrow/services/image_service.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_key.dart';
import '../l10n/app_localizations.dart';


String sanitizeErrorMessage(String e) {
  String newStr = e.toString().replaceAll(wapi_Key, "WAPIKEY");
  newStr = newStr.replaceAll(access_key, "UNSPLASHKEY");
  newStr = newStr.replaceAll(timezonedbKey, "TIMEZONEDBKEY");
  return newStr;
}

Future<void> _launchUrl(String url) async {
  final Uri _url = Uri.parse(url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
}

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

    //FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    //Size size = view.physicalSize / view.devicePixelRatio;

    /*
    if (size.width > 950) {
      return TabletLayout(
        data: data, updateLocation: updateLocation,
        key: Key("${data.place}, ${data.provider} ${data.updatedTime}"),);
    }

     */

    //return SearchHeroDemo();

    return Container();
    //return NewMain(data: data, updateLocation: updateLocation, context: context,
    //    key: Key("${data.place}, ${data.provider} ${data.updatedTime}"),);
  }
}


class SmoothTempTransition extends StatefulWidget {
  final double target;
  final Color color;
  final double fontSize;

  const SmoothTempTransition({super.key, required this.target, required this.color, required this.fontSize});

  @override
  State<SmoothTempTransition> createState() => _SmoothTempTransitionState();
}

class _SmoothTempTransitionState extends State<SmoothTempTransition> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: widget.target,
      ),

      curve: Curves.easeOut,

      duration: const Duration(milliseconds: 1000),

      builder: (context, current, child) {
        return Text(
          "${current.round()}°",
          style: GoogleFonts.outfit(
            color: widget.color,
            fontSize: widget.fontSize,
            height: 1.05,
            fontWeight: FontWeight.w300,
          ),);
      },
    );
  }
}


class Circles extends StatelessWidget {

  final WeatherData data;

  const Circles({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 19, right: 19, bottom: 13, top: 0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DescriptionCircle(
                text: '${unitConversion(data.current.feelsLikeC,
                    context.select((SettingsProvider p) => p.getTempUnit), decimals: 0)}°',
                undercaption: AppLocalizations.of(context)!.feelsLike,
                extra: '',
                dir: -1,
              ),
              DescriptionCircle(
                text: '${data.current.humidity}',
                undercaption: AppLocalizations.of(context)!.humidity,
                extra: '%',
                dir: -1,
              ),
              DescriptionCircle(
                text: '${data.current.precipMm}',
                undercaption: AppLocalizations.of(context)!.precipCapital,
                extra: context.select((SettingsProvider p) => p.getPrecipUnit),
                dir: -1,
              ),
              DescriptionCircle(
                text: '${unitConversion(data.current.windKph,
                    context.select((SettingsProvider p) => p.getWindUnit), decimals: 0)}',
                undercaption: AppLocalizations.of(context)!.windCapital,
                extra: context.select((SettingsProvider p) => p.getWindUnit),
                dir: data.current.windDirA + 180,
              ),
            ]
        )
    );
  }

}


class DescriptionCircle extends StatelessWidget {

  final String text;
  final String undercaption;
  final String extra;
  final dir;

  const DescriptionCircle({super.key, required this.text,
    required this.undercaption,  required this.extra, required this.dir});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 3, right: 3),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 2, color: Theme.of(context).colorScheme.primary),
                          //color: Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20, height: 1.1),),
                              Flexible(
                                child: Text(extra, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, height: 1.3),)
                              ),
                            ],
                          ),
                        )
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Visibility(
                              visible: dir != -1,
                              child:   Center(
                                child: RotationTransition(
                                    turns: AlwaysStoppedAnimation(dir / 360),
                                    child: Padding(
                                        padding: EdgeInsets.only(bottom: constraints.maxWidth * 0.70),
                                        child: const Icon(Icons.keyboard_arrow_up_outlined, size: 18,)
                                    )
                                ),
                              )
                          );
                        }
                    ),
                  ),
                ],
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top:6),
                  child: Text(undercaption, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),)
                )
              )
            ]
        ),
      ),
    );
  }
}


class FadingWidget extends StatefulWidget  {
  final WeatherData data;
  final ImageService? imageService;
  final time;

  const FadingWidget({super.key, required this.data, required this.time, required this.imageService});

  @override
  _FadingWidgetState createState() => _FadingWidgetState();
}

class _FadingWidgetState extends State<FadingWidget> with AutomaticKeepAliveClientMixin {
  bool _isVisible = true;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer in the dispose method
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.imageService != null) {
      final dif = widget.time.difference(widget.data.fetchDatetime).inMinutes;

      String text = AppLocalizations.of(context)!.updatedJustNow;

      if (dif > 0 && dif < 45) {
        text = AppLocalizations.of(context)!.updatedXMinutesAgo(dif);
      }
      else if (dif >= 45 && dif < 1440) {
        int hour = (dif + 30) ~/ 60;
        text = AppLocalizations.of(context)!.updatedXHoursAgo(hour);
      }
      else if (dif >= 1440) { //number of minutes in a day
        int day = (dif + 720) ~/ 1440;
        text = AppLocalizations.of(context)!.updatedXDaysAgo(day);
      }

      List<String> split = text.split(',');

      return Container(
        height: 25,
        color: widget.data.isOnline ? Colors.transparent : Theme.of(context).colorScheme.primaryContainer,
        margin: widget.data.isOnline ? const EdgeInsets.only(bottom: 1) : const EdgeInsets.only(bottom: 5),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final inAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            );
            final outAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(1.0, 0.5, curve: Curves.easeOut),
            );
            return FadeTransition(
              opacity: _isVisible ? outAnimation : inAnimation,
              child: child,
            );
          },
          child: SinceLastUpdate(
            key: ValueKey<bool>(_isVisible),
            split: split,
            data: widget.data,
            isVisible: _isVisible,
            imageService: widget.imageService!,
          ),
        ),
      );
    }
    return const SizedBox(height: 25,);
  }
}

class SinceLastUpdate extends StatelessWidget {

  final List<String> split;
  final WeatherData data;
  final bool isVisible;
  final ImageService imageService;

  const SinceLastUpdate({Key? key, required this.data, required this.split, required this.isVisible,
    required this.imageService}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Color text = data.isOnline ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.onPrimaryContainer;
    Color highlight = data.isOnline ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onPrimaryContainer;

    if (isVisible) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 31),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!data.isOnline) Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13),
            ),
            if (!data.isOnline) Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Text(AppLocalizations.of(context)!.offline, style: TextStyle(color: highlight, fontSize: 13),)
            ),
            if (data.isOnline) Padding(
              padding: const EdgeInsets.only(right: 3, top: 1),
              child: Icon(Icons.access_time, color: highlight, size: 13,),
            ),
            Text('${split[0]},', style: TextStyle(color: highlight, fontSize: 13),),

            Text(split.length > 1 ? split[1] : "", style: TextStyle(color: text, fontSize: 13),),

          ],
        ),
      );
    } else{
      List<String> split = AppLocalizations.of(context)!.photoByXOnUnsplash.split(",");
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 31),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!data.isOnline) Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13,),
            ),
            if (!data.isOnline) Padding(
              padding: const EdgeInsets.only(right: 7),
                child: Text(AppLocalizations.of(context)!.offline, style: TextStyle(color: highlight, fontSize: 14),)
            ),
            TextButton(
              onPressed: () async {
                await _launchUrl("${imageService.photolink}?utm_source=overmorrow&utm_medium=referral");
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(1),
                minimumSize: const Size(0, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
              child: Text(split[0], style: TextStyle(color: text, fontSize: 13, ),)
            ),
            Text(split[1], style: TextStyle(color: text, fontSize: 13),),
            TextButton(
              onPressed: () async {
                await _launchUrl("${imageService.userlink}?utm_source=overmorrow&utm_medium=referral");
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(1),
                minimumSize: const Size(0, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
              child: Text(imageService.username, style: TextStyle(color: text, fontSize: 13,),)
            ),
            Text(split[3], style: TextStyle(color: text, fontSize: 13),)      ,
            TextButton(
              onPressed: () async {
                await _launchUrl("https://unsplash.com/?utm_source=overmorrow&utm_medium=referral");
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(1),
                minimumSize: const Size(0, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
              child: Text(split[4], style: TextStyle(color: text, fontSize: 13, ),)
            ),
          ],
        ),
      );
    }
  }
}

class ProviderSelector extends StatelessWidget {
  final Function updateLocation;
  final String latLon;
  final String loc;

  const ProviderSelector({super.key, required this.loc, required this.latLon, required this.updateLocation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 80, top: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 0),
            child: Text(AppLocalizations.of(context)!.weatherProvderLowercase, style: const TextStyle(fontSize: 17),)
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 7, bottom: 7),
              child: DropdownButton(
                underline: Container(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                },
                borderRadius: BorderRadius.circular(18),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.unfold_more, color: Theme.of(context).colorScheme.tertiary, size: 22,),
                ),
                value: context.select((SettingsProvider p) => p.getWeatherProvider),
                items: ["weatherapi", "open-meteo", "met-norway"].map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(item, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18),)
                    ),
                  );
                }).toList(),
                onChanged: (String? value) async {
                  if (value != null) {
                    HapticFeedback.mediumImpact();
                    context.read<SettingsProvider>().setWeatherPovider(value);
                    await updateLocation(latLon, loc);
                  }
                },
                itemHeight: 55,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/*
class ErrorPage extends StatelessWidget {
  final errorMessage;
  final updateLocation;
  final place;
  final icon;
  final settings;
  final provider;
  final latlng;
  final shouldAdd;

  ErrorPage({super.key, required this.errorMessage,
    required this.updateLocation, required this.icon, required this.place,
    required this.settings, required this.provider, required this.latlng,  this.shouldAdd});

  @override
  Widget build(BuildContext context) {

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;

    String newStr = sanitizeErrorMessage(errorMessage);

    Image image = Image.asset("assets/backdrops/grayscale_snow2.jpg",
        fit: BoxFit.cover, width: double.infinity, height: double.infinity);

    ColorScheme palette = ColorPalette.getErrorPagePalette(settings["Color mode"]);

    return Scaffold(
      backgroundColor: palette.surface,
      body: StretchyHeader.singleChild(
        displacement: 150,
        onRefresh: () async {
          await updateLocation(latlng, place, time: 400);
        },
        headerData: HeaderData(
            blurContent: false,
            headerHeight: max(size.height * 0.5, 400), //we don't want it to be smaller than 400
            header: ParrallaxBackground(image: Image.asset("assets/backdrops/grayscale_snow2.jpg", fit: BoxFit.cover,), key: Key(place),
                color: palette.surfaceContainerHigh),
            overlay: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 50, bottom: 20),
                          child: Icon(icon, color: Colors.black54, size: 20),
                        ),
                        comfortatext(newStr, 17, settings, color: Colors.black54, weight: FontWeight.w500,
                            align: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                MySearchWidget(place: place, updateLocation: updateLocation, isTabletMode: false)
              ],
            )
        ),
        child:
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: comfortatext(shouldAdd ?? "", 16, settings, color: palette.onSurface, weight: FontWeight.w400,),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: providerSelector(settings, updateLocation, palette, provider, latlng, place, context),
            ),
          ],
        ),
      ),
    );
  }
}

 */
