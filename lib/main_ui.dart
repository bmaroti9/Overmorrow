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
import 'package:overmorrow/main_screens.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';
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
      return TabletLayout(data, updateLocation, context);
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
      duration: const Duration(milliseconds: 1300),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          color: color,
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 1.0 + (0.06 * value),
              child: image,
            ),
          ),
        );
      },
    );
  }
}


Widget Circles(var data, double bottom, context, primary, onSurface, outline) {
  return Padding(
      //top padding is slightly bigger because of the offline colored bar
      padding: EdgeInsets.only(top: data.isonline ? 28 : 33, left: 20, right: 20, bottom: 13),
      child: Row(
          children: [
            DescriptionCircle(
              text: '${data.current.feels_like}°',
              undercaption: AppLocalizations.of(context)!.feelsLike,
              extra: '',
              settings: data.settings,
              bottom: bottom,
              dir: -1,
              primary: primary,
              outline: outline,
              onSurface: onSurface,
            ),
            DescriptionCircle(
              text: '${data.current.humidity}',
              undercaption: AppLocalizations.of(context)!.humidity,
              extra: '%',

              settings: data.settings,
              bottom: bottom,
              dir: -1,
              primary: primary,
              outline: outline,
              onSurface: onSurface,
            ),
            DescriptionCircle(
              text: '${data.current.precip}',
              undercaption: AppLocalizations.of(context)!.precipCapital,
              extra: data.settings["Precipitation"],
              settings: data.settings,
              bottom: bottom,
              dir: -1,
              primary: primary,
              outline: outline,
              onSurface: onSurface,
            ),
            DescriptionCircle(
              text: '${data.current.wind}',
              undercaption: AppLocalizations.of(context)!.windCapital,
              extra: data.settings["Wind"],
              settings: data.settings,
              bottom: bottom,
              dir: data.current.wind_dir + 180,
              primary: primary,
              outline: outline,
              onSurface: onSurface,
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
  final bottom;
  final dir;

  final Color primary;
  final Color onSurface;
  final Color outline;

  const DescriptionCircle({super.key, required this.text,
    required this.undercaption,  required this.extra,
    required this.settings, required this.bottom, required this.dir,
    required this.primary, required this.onSurface, required this.outline});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 4.5, right: 4.5),
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

                          border: Border.all(width: 2.0, color: primary),
                          //color: WHITE,
                          //borderRadius: BorderRadius.circular(size * 0.09)
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              comfortatext(text, 20, settings, color: primary),
                              Flexible(
                                  child: comfortatext(extra, 16, settings, color: primary, weight: FontWeight.w400)
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
                                        child: Icon(Icons.keyboard_arrow_up_outlined, color: onSurface, size: 17,)
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
                  child: comfortatext(undercaption, 15, settings, align: TextAlign.center, color: outline)
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

    return Container(
      color: widget.data.isonline ? widget.data.current.surface : widget.data.current.primaryLight,
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

    Color text = widget.data.isonline ? widget.data.current.onSurface : widget.data.current.onPrimaryLight;
    Color highlight = widget.data.isonline ? widget.data.current.primary : widget.data.current.onPrimaryLight;

    if (widget.isVisible) {
      return SizedBox(
        height: 21,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.download_for_offline_outlined, color: highlight, size: 13,),
              ),
              if (!widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 7),
                child: comfortatext(AppLocalizations.of(context)!.offline, 14, widget.data.settings,
                    color: highlight),
              ),
              if (widget.data.isonline) Padding(
                padding: const EdgeInsets.only(right: 3, top: 1),
                child: Icon(Icons.access_time, color: highlight, size: 13,),
              ),
              comfortatext('${widget.split[0]},', 14, widget.data.settings,
                  color: widget.data.isonline ? highlight
                      : text),

              comfortatext(widget.split.length > 1 ? widget.split[1] : "", 14, widget.data.settings,
                  color: text),
            ],
          ),
        ),
      );
    } else{
      List<String> split = AppLocalizations.of(context)!.photoByXOnUnsplash.split(",");
      return SizedBox(
        height: 21,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
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
                    color: highlight, weight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  await _launchUrl(widget.data.current.photoUrl + "?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(split[0], 13, widget.data.settings, color: text,
                    decoration: TextDecoration.underline),
              ),
              comfortatext(split[1], 13, widget.data.settings, color: text),
              TextButton(
                onPressed: () async {
                  await _launchUrl(widget.data.current.photographerUrl + "?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(widget.data.current.photographerName, 13, widget.data.settings, color: text,
                    decoration: TextDecoration.underline),
              ),
              comfortatext(split[3], 13, widget.data.settings, color: text),
              TextButton(
                onPressed: () async {
                  await _launchUrl("https://unsplash.com/?utm_source=overmorrow&utm_medium=referral");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(1),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,),
                child: comfortatext(split[4], 13, widget.data.settings, color: text,
                    decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      );
    }
  }
}


Widget providerSelector(settings, updateLocation, textcolor, highlight, primary,
    provider, latlng, real_loc, context) {
  return Padding(
    padding: const EdgeInsets.only(left: 23, right: 23, bottom: 30, top: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: comfortatext(
                AppLocalizations.of(context)!.weatherProvider, 16,
                settings,
                color: textcolor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
            child: DropdownButton(
              underline: Container(),
              onTap: () {
                HapticFeedback.mediumImpact();
              },
              borderRadius: BorderRadius.circular(20),
              icon: Padding(
                padding: const EdgeInsets.only(left:5),
                child: Icon(Icons.arrow_drop_down_circle_outlined, color: primary, size: 22,),
              ),
              style: GoogleFonts.comfortaa(
                color: primary,
                fontSize: 18 * getFontSize(settings["Font size"]),
                fontWeight: FontWeight.w500,
              ),
              //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
              value: provider.toString(),
              items: ['weatherapi.com', 'open-meteo', 'met norway'].map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? value) async {
                HapticFeedback.mediumImpact();
                SetData('weather_provider', value!);
                await updateLocation(latlng, real_loc);
              },
              isExpanded: true,
              dropdownColor: highlight,
              elevation: 0,
            ),
          ),
        ),
      ],
    ),
  );
}
