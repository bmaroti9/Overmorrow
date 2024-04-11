import 'dart:math';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:overmorrow/settings_page.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:stretchy_header/stretchy_header.dart';
import 'main_ui.dart';
import 'ui_helper.dart';

class NewMain extends StatefulWidget {
  final data;
  final updateLocation;

  const NewMain({required this.data, required this.updateLocation});

  @override
  _NewMainState createState() => _NewMainState(data: data,
  updateLocation: updateLocation);
}

class _NewMainState extends State<NewMain> {
  bool isLoading = false;
  bool numbers = true;

  final FloatingSearchBarController controller = FloatingSearchBarController();

  final data;
  final updateLocation;

  _NewMainState({required this.data, required this.updateLocation});

  void _loadFakeData() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    numbers = !numbers;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    //get the size of the device
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize / view.devicePixelRatio;

    return Scaffold(
      backgroundColor: data.current.backcolor,
      drawer: MyDrawer(primary: data.current.backup_primary, back: data.current.backup_backcolor,
      settings: data.settings),
      body: Stack(
        children: [
          StretchyHeader.listView(
            displacement: 150,
            onRefresh: () {
              _loadFakeData();
            },
            headerData: HeaderData(
              //backgroundColor: WHITE,
              blurContent: false,
              headerHeight: max(size.height * 0.6, 400), //we don't want it to be smaller than 400
              header: Image.asset(
                'assets/backdrops/${data!.current.backdrop}',
                fit: BoxFit.cover,
              ),
              overlay: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 25,
                        top: MediaQuery.of(context).padding.top + 20, right: 25, bottom: 30
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(left: 0, bottom: 5),
                          child: comfortatext("${data.current.temp}°", 65, data.settings,
                              color: data.current.colorpop, weight: FontWeight.w300),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: comfortatext(data.current.text, 32, data.settings),
                        )
                      ],
                    ),
                  ),
                  MySearchParent(updateLocation: updateLocation,
                    color: data.current.backcolor, place: data.place,
                    controller: controller, settings: data.settings, real_loc: data.real_loc,
                  secondColor: data.current.primary, textColor: data.current.textcolor,
                  highlightColor: data.current.highlight,),
                ],
              )
            ),
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        if(constraints.maxWidth > 400.0) {
                          return Circles(400, data, 0.5, data.current.primary);
                        } else {
                          return Circles(constraints.maxWidth * 0.95, data, 0.5, data.current.primary);
                        }
                      }
                  ),
                ),
              ),
              NewTimes(data, true),
              buildHihiDays(data),
              buildGlanceDay(data),
              providerSelector(data, updateLocation),
              Padding(padding: EdgeInsets.only(bottom: 20))
            ],
          ),
          if (isLoading) _buildLoadingWidget()
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    //Note: this is just a demo refresh and thus doesn't do anything
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: WHITE,
          size: 40,
        ),
      ),
    );
  }
}

Widget PhoneLayout(data, updateLocation, context) {

  final FloatingSearchBarController controller = FloatingSearchBarController();

  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

  Size size = view.physicalSize / view.devicePixelRatio;
  double safeHeight = size.height;
  final availableHeight = MediaQuery.of(context).size.height -
      AppBar().preferredSize.height -
      MediaQuery.of(context).padding.top -
      MediaQuery.of(context).padding.bottom;

  return Scaffold(
    backgroundColor: data.current.backcolor,
    drawer: MyDrawer(primary: data.current.backup_primary, back: data.current.backup_backcolor,
        settings: data.settings),
    body: RefreshIndicator(
      onRefresh: () async {
        await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
      },
      backgroundColor: WHITE,
      color: data.current.backcolor,
      child: Stack(
        children: [
          Container(
          decoration: BoxDecoration(
          color: data.current.backcolor,
              border: const Border.symmetric(vertical: BorderSide(
                  width: 1.2,
                  color: WHITE
                )
              )
            ),
          ),
          CustomScrollView(
            physics: Platform.isLinux? const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast)
                : const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                automaticallyImplyLeading: false, // remove the hamburger-menu
                backgroundColor: Colors.transparent, // Set background to transparent
                bottom: PreferredSize(
                  preferredSize: const Size(0, 380),
                  child: Container(),
                ),
                pinned: false,

                expandedHeight: availableHeight + 43,
                flexibleSpace: Stack(
                  children: [
                    ParallaxBackground(data: data,),
                    Positioned(
                      bottom: 25,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          child: buildCurrent(data, safeHeight - 100, 1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -3,
                      left: 0,
                      right: 0,
                      child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                      border: Border.all(width: 1.2, color: WHITE),
                      color: data.current.backcolor,
                      borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(27),)
                    ),),),
                    MySearchParent(updateLocation: updateLocation,
                      color: data.current.backcolor, place: data.place,
                      controller: controller, settings: data.settings, real_loc: data.real_loc,
                    secondColor: WHITE, textColor: data.current.textcolor,
                    highlightColor: data.current.highlight,),
                  ],
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 30)),
              NewTimes(data, true),
              buildHihiDays(data),
              buildGlanceDay(data),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top:20, right: 20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WHITE, width: 1.2)
                    ),
                    child: Column(
                      children: [
                        comfortatext(translation('Weather provider', data.settings["Language"]), 18, data.settings),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: DropdownButton(
                            underline: Container(),
                            borderRadius: BorderRadius.circular(20),
                            icon: const Padding(
                              padding: EdgeInsets.only(left:5),
                              child: Icon(Icons.arrow_drop_down_circle, color: WHITE,),
                            ),
                            style: GoogleFonts.comfortaa(
                              color: WHITE,
                              fontSize: 20 * getFontSize(data.settings["Font size"]),
                              fontWeight: FontWeight.w300,
                            ),
                            //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
                            value: data.provider.toString(),
                            items: ['weatherapi.com', 'open-meteo'].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (String? value) async {
                              SetData('weather_provider', value!);
                              await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
                            },
                            isExpanded: true,
                            dropdownColor: darken(data.current.backcolor, 0.1),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 30))
            ],
          ),
        ],
      ),
    ),
  );
}

Widget TabletLayout(data, updateLocation, context) {

  final FloatingSearchBarController controller = FloatingSearchBarController();

  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

  Size size = view.physicalSize / view.devicePixelRatio;

  double toppad = MediaQuery.of(context).viewPadding.top;

  double width = size.width - min(max(size.width * 0.4, 400), 450);
  double heigth = min(max(width / 1.5, 450), 510);

  return Scaffold(
    backgroundColor: data.current.backcolor,
    drawer: MyDrawer(primary: data.current.backup_primary, back: data.current.backup_backcolor,
        settings: data.settings),
    body: RefreshIndicator(
      onRefresh: () async {
        await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
      },
      backgroundColor: WHITE,
      color: data.current.backcolor,
      displacement: 100,
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 10, bottom: 10, top: toppad + 10),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width,
                child: Column(
                  children: [
                    SizedBox(
                      height: heigth * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ParallaxBackground(data: data)
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: buildCurrent(data, 100, 0.6),
                                ),
                              ),
                              MySearchParent(updateLocation: updateLocation,
                                  color: data.current.backcolor, place: data.place,
                                  controller: controller, settings: data.settings,
                                  real_loc: data.real_loc, secondColor: WHITE,
                                  textColor: data.current.textcolor,
                                  highlightColor: data.current.highlight,),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                        itemBuilder:
                              (BuildContext context, int index) {
                            if (index < 3) {
                              final day = data.days[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.only(top: 30, bottom: 10),
                                      child: comfortatext(day.name, 20, data.settings)
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2, right: 2, bottom: 20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: day.mm_precip > 0.1 ? darken(data.current.backcolor) : data.current.backcolor
                                      ),
                                      padding: const EdgeInsets.all(5.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: day.mm_precip > 0.2 ? width - max(width * 0.4, 300) : width - 20,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 10),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.only(left: 10, right: 20, top: 4),
                                                        child: Image.asset(
                                                          'assets/icons/' + day.icon,
                                                          fit: BoxFit.contain,
                                                          height: 40,
                                                        ),
                                                      ),
                                                      comfortatext(day.text, 22, data.settings, color: WHITE),
                                                      const Spacer(),
                                                      Padding(
                                                        padding: const EdgeInsets.only(right: 6),
                                                        child: Container(
                                                            padding: const EdgeInsets.only(top:7,bottom: 7, left: 5, right: 5),
                                                            decoration: BoxDecoration(
                                                              //border: Border.all(color: Colors.blueAccent)
                                                                color: WHITE,
                                                                borderRadius: BorderRadius.circular(10)
                                                            ),
                                                            child: comfortatext(day.minmaxtemp, 17, data.settings, color: data.current.backcolor)
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 15, right: 5, top: 15),
                                                  child: Container(
                                                    height: 85,
                                                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(width: 1.2, color: WHITE),
                                                        borderRadius: BorderRadius.circular(20)
                                                    ),
                                                    child:  LayoutBuilder(
                                                        builder: (BuildContext context, BoxConstraints constraints) {
                                                          return GridView.count(
                                                              padding: const EdgeInsets.all(0),
                                                              physics: const NeverScrollableScrollPhysics(),
                                                              crossAxisSpacing: 1,
                                                              mainAxisSpacing: 1,
                                                              crossAxisCount: 2,
                                                              childAspectRatio: constraints.maxWidth / constraints.maxHeight,
                                                              children: [
                                                                Padding(
                                                                  padding: const EdgeInsets.only(
                                                                      left: 8, right: 8),
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(Icons.water_drop_outlined,
                                                                        color: WHITE,),
                                                                      const Padding(
                                                                          padding: EdgeInsets.only(right: 10)),
                                                                      comfortatext('${day.precip_prob}%', 20, data.settings),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets.only(
                                                                      left: 8, right: 8),
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(
                                                                        Icons.water_drop, color: WHITE,),
                                                                      const Padding(
                                                                          padding: EdgeInsets.only(right: 10)),
                                                                      comfortatext(day.total_precip.toString() +
                                                                          data.settings["Rain"], 20, data.settings),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets.only(
                                                                      left: 8, right: 8),
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(
                                                                        CupertinoIcons.wind, color: WHITE,),
                                                                      const Padding(
                                                                          padding: EdgeInsets.only(right: 10)),
                                                                      comfortatext('${day.windspeed} ${data
                                                                          .settings["Wind"]}', 20, data.settings),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets.only(
                                                                      left: 8, right: 8),
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(CupertinoIcons.sun_min,
                                                                        color: WHITE,),
                                                                      const Padding(
                                                                          padding: EdgeInsets.only(right: 10)),
                                                                      comfortatext('${day.uv} UV', 20, data.settings),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ]
                                                          );
                                                        }
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Visibility(
                                                visible: day.mm_precip > 0.2,
                                                child: RainWidget(data.settings, day)
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  buildHours(day.hourly, data),
                                ],
                              );
                            }
                            return null;
                          },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 50),
                  child: Column(
                    children: [
                      CustomScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                            slivers: [
                              NewTimes(data, false),
                              buildGlanceDay(data)
                            ]
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: WHITE, width: 1.2)
                          ),
                          child: Column(
                            children: [
                              comfortatext(translation('Weather provider', data.settings["Language"]), 18, data.settings),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, right: 20),
                                child: DropdownButton(
                                  underline: Container(),
                                  borderRadius: BorderRadius.circular(20),
                                  icon: const Padding(
                                    padding: EdgeInsets.only(left:5),
                                    child: Icon(Icons.arrow_drop_down_circle, color: WHITE,),
                                  ),
                                  style: GoogleFonts.comfortaa(
                                    color: WHITE,
                                    fontSize: 20 * getFontSize(data.settings["Font size"]),
                                    fontWeight: FontWeight.w300,
                                  ),
                                  //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
                                  value: data.provider.toString(),
                                  items: ['weatherapi.com', 'open-meteo'].map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (String? value) async {
                                    SetData('weather_provider', value!);
                                    await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
                                  },
                                  isExpanded: true,
                                  dropdownColor: darken(data.current.backcolor, 0.1),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    )
  );
}