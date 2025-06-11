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
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overmorrow/main_screens.dart';
import 'package:overmorrow/services/color_service.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:stretchy_header/stretchy_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_key.dart';
import 'ui_helper.dart';
import '../l10n/app_localizations.dart';


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

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize / view.devicePixelRatio;

    if (size.width > 950) {
      return TabletLayout(
        data: data, updateLocation: updateLocation,
        key: Key("${data.place}, ${data.provider} ${data.updatedTime}"),);
    }

    //return SearchHeroDemo();

    return NewMain(data: data, updateLocation: updateLocation, context: context,
        key: Key("${data.place}, ${data.provider} ${data.updatedTime}"),);
  }
}

class ParrallaxBackground extends StatelessWidget {
  final Image image;
  final Color color;

  const ParrallaxBackground({Key? key, required this.image, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0, end: 1.0),
      curve: Curves.decelerate,
      builder: (context, value, child) {
        return Container(
          color: color,
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 1.0 + (0.1 * value),
              child: image,
            ),
          ),
        );
      },
    );
  }
}

Widget Circles(var data, double bottom, context, ColorScheme palette) {
  return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 13, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DescriptionCircle(
              text: '${data.current.feels_like}°',
              undercaption: AppLocalizations.of(context)!.feelsLike,
              extra: '',
              settings: data.settings,
              dir: -1,
              palette: palette
            ),
            DescriptionCircle(
              text: '${data.current.humidity}',
              undercaption: AppLocalizations.of(context)!.humidity,
              extra: '%',
              settings: data.settings,
              dir: -1,
              palette: palette
            ),
            DescriptionCircle(
              text: '${data.current.precip}',
              undercaption: AppLocalizations.of(context)!.precipCapital,
              extra: data.settings["Precipitation"],
              settings: data.settings,
              dir: -1,
              palette: palette
            ),
            DescriptionCircle(
              text: '${data.current.wind}',
              undercaption: AppLocalizations.of(context)!.windCapital,
              extra: data.settings["Wind"],
              settings: data.settings,
              dir: data.current.wind_dir + 180,
              palette: palette
            ),
          ]
      )
  );
}


class DescriptionCircle extends StatelessWidget {

  final String text;
  final String undercaption;
  final String extra;
  final settings;
  final dir;

  final ColorScheme palette;

  const DescriptionCircle({super.key, required this.text,
    required this.undercaption,  required this.extra,
    required this.settings, required this.dir,
    required this.palette});

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
                          border: Border.all(width: 2, color: palette.primary),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              comfortatext(text, 20, settings, color: palette.primary, weight: FontWeight.w400),
                              Flexible(
                                  child: comfortatext(extra, 16, settings, color: palette.primary, weight: FontWeight.w400)
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
                                        child: Icon(Icons.keyboard_arrow_up_outlined, color: palette.onSurface, size: 17,)
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
                  child: comfortatext(undercaption, 14, settings, align: TextAlign.center, color: palette.outline,
                  weight: FontWeight.w300)
                )
              )
            ]
        ),
      ),
    );
  }
}


class FadingWidget extends StatefulWidget  {
  final data;
  final time;

  const FadingWidget({super.key, required this.data, required this.time});

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
    _timer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
    _timer = Timer(const Duration(milliseconds: 2000), () {
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

    final dif = widget.time.difference(widget.data.fetch_datetime).inMinutes;

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

    ColorScheme palette = widget.data.current.palette;

    return Container(
      color: widget.data.isonline ? Colors.transparent : palette.primaryContainer,
      margin: widget.data.isonline ? const EdgeInsets.only(bottom: 1) : const EdgeInsets.only(bottom: 5),
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
        ),
      ),
    );
  }
}


class SinceLastUpdate extends StatefulWidget {
  final split;
  final data;
  final isVisible;

  SinceLastUpdate({Key? key, required this.data, required this.split, required this.isVisible}) : super(key: key);

  @override
  _SinceLastUpdateState createState() => _SinceLastUpdateState();
}

class _SinceLastUpdateState extends State<SinceLastUpdate>{

  @override
  Widget build(BuildContext context) {

    Color text = widget.data.isonline ? widget.data.current.palette.onSurface
        : widget.data.current.palette.onPrimaryContainer;
    Color highlight = widget.data.isonline ? widget.data.current.palette.primary
        : widget.data.current.palette.onPrimaryContainer;

    if (widget.isVisible) {
      return SizedBox(
        height: 21,
        child: Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13),
              ),
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 7),
                child: comfortatext(AppLocalizations.of(context)!.offline, 14, widget.data.settings,
                    color: highlight, weight: FontWeight.w300,),
              ),
              if (widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 3, top: 1),
                child: Icon(Icons.access_time, color: highlight, size: 13,),
              ),
              comfortatext('${widget.split[0]},', 14, widget.data.settings,
                  color: widget.data.isonline ? highlight
                      : text, weight: FontWeight.w300,),

              comfortatext(widget.split.length > 1 ? widget.split[1] : "", 14, widget.data.settings,
                  color: text, weight: FontWeight.w300,),
            ],
          ),
        ),
      );
    } else{
      List<String> split = AppLocalizations.of(context)!.photoByXOnUnsplash.split(",");
      return SizedBox(
        height: 21,
        child: Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13,),
              ),
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 7),
                child: comfortatext(AppLocalizations.of(context)!.offline, 13, widget.data.settings,
                    color: highlight, weight: FontWeight.w300),
              ),
              TextButton(
                onPressed: () async {
                  await _launchUrl(widget.data.current.imageService.photolink + "?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(split[0], 13, widget.data.settings, color: text,
                    decoration: TextDecoration.underline, weight: FontWeight.w300),
              ),
              comfortatext(split[1], 13, widget.data.settings, color: text, weight: FontWeight.w300),
              TextButton(
                onPressed: () async {
                  await _launchUrl(widget.data.current.imageService.userlink + "?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(widget.data.current.imageService.username, 13, widget.data.settings, color: text,
                    decoration: TextDecoration.underline, weight: FontWeight.w300),
              ),
              comfortatext(split[3], 13, widget.data.settings, color: text, weight: FontWeight.w300),              TextButton(
                onPressed: () async {
                  await _launchUrl("https://unsplash.com/?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(split[4], 13, widget.data.settings, color: text,
                    decoration: TextDecoration.underline, weight: FontWeight.w300),
              ),
            ],
          ),
        ),
      );
    }
  }
}


Widget providerSelector(settings, updateLocation, ColorScheme palette, provider, latlng, real_loc, context) {
  return Padding(
    padding: const EdgeInsets.only(left: 25, right: 25, bottom: 80, top: 35),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 0),
          child: comfortatext(
              AppLocalizations.of(context)!.weatherProvderLowercase, 17,
              settings,
              color: palette.onSurface),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              //border: Border.all(color: palette.secondary, width: 2)
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
                child: Icon(Icons.unfold_more, color: palette.secondary, size: 22,),
              ),
              value: provider.toString(),
              items: ['weatherapi.com', 'open-meteo', 'met norway'].map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: comfortatext(item, 18, settings, color: palette.secondary),
                  ),
                );
              }).toList(),
              onChanged: (String? value) async {
                HapticFeedback.mediumImpact();
                SetData('weather_provider', value!);
                await updateLocation(latlng, real_loc);
              },
              itemHeight: 55,
              isExpanded: true,
              dropdownColor: palette.surfaceContainerHigh,
              elevation: 0,
            ),
          ),
        ),
      ],
    ),
  );
}


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

    const replacement = "<api_key>";
    String newStr = errorMessage.toString().replaceAll(wapi_Key, replacement);
    newStr = newStr.replaceAll(access_key, replacement);
    newStr = newStr.replaceAll(timezonedbKey, replacement);

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
                MySearchParent(updateLocation: updateLocation,
                  palette: palette, place: place, settings: settings, image: image,
                isTabletMode: false,)
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
