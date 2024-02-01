import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/settings_page.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'main_ui.dart';
import 'ui_helper.dart';

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
    drawer: MyDrawer(color: data.current.backcolor, settings: data.settings),
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
                ))
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                          child: buildCurrent(data, safeHeight - 100),
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
                            top: Radius.circular(27),
                          ),
                        ),
                      ),
                    ),
                    MySearchParent(updateLocation: updateLocation,
                      color: data.current.backcolor, place: data.place,
                      controller: controller, settings: data.settings, real_loc: data.real_loc,),
                  ],
                ),
              ),
              NewTimes(data),
              buildHihiDays(data),
              buildGlanceDay(data),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top:20, right: 20),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WHITE, width: 1.2)
                    ),
                    child: Column(
                      children: [
                        comfortatext(translation('Weather provider', data.settings[0]), 18, data.settings),
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
                              fontSize: 20 * getFontSize(data.settings[7]),
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

  double toppad = MediaQuery.of(context).viewPadding.top;

  return Scaffold(
    backgroundColor: data.current.backcolor,
    drawer: MyDrawer(color: data.current.backcolor, settings: data.settings),
    body: RefreshIndicator(
      onRefresh: () async {
        await updateLocation("${data.lat}, ${data.lng}", data.real_loc);
      },
      backgroundColor: WHITE,
      color: data.current.backcolor,
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: toppad + 20),
        child: ListView(
          physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
          children: [
            AspectRatio(
              aspectRatio: 2.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      ParallaxBackground(data: data),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 50.0, left: 30),
                            child: Align(
                                alignment: Alignment.topLeft,
                                child: comfortatext("${data.current.temp}°", 85, data.settings)
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 30, bottom: 50),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: comfortatext(data.current.text, 45, data.settings),
                            ),
                          ),
                      ]
                    ),
                    LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          if(constraints.maxWidth > 400.0) {
                            return Circles(400, data);
                          } else {
                            return Circles(constraints.maxWidth, data);
                          }
                        }
                      ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: FlutterTimeDemo(settings: data.settings,),
                    ),
                    MySearchParent(updateLocation: updateLocation,
                        color: data.current.backcolor, place: data.place,
                        controller: controller, settings: data.settings,
                        real_loc: data.real_loc)
                  ],
                  )
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(3, (index) {
                final day = data.days[index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(top: 30, bottom: 10),
                            child: comfortatext(day.name, 20, data.settings)
                        ),
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: day.mm_precip > 0.1 ? darken(data.current.backcolor, 0.1) : data.current.backcolor,
                            ),
                            padding: const EdgeInsets.only(top: 8, left: 3, right: 5, bottom: 3),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(left: 10, right: 20),
                                      child: Image.asset(
                                        'assets/icons/' + day.icon,
                                        fit: BoxFit.contain,
                                        height: 40,
                                      ),
                                    ),
                                    Flexible(
                                        fit: FlexFit.loose,
                                        child: Row(
                                          children: [
                                            comfortatext(day.text, 22, data.settings, color: WHITE),
                                            Spacer(),
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
                                            ),
                                          ],
                                        )
                                    )
                                  ],
                                ),
                                Visibility(
                                    visible: day.mm_precip > 0.1,
                                    child: RainWidget(data.settings, day)
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5, right: 5, top: 15, bottom: 30),
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
                                                  data.settings[2], 20, data.settings),
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
                                                  .settings[3]}', 20, data.settings),
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
                        buildHours(day.hourly, data.settings, data.current.accentcolor, data.settings),
                      ],
                    ),
                  ),
                );
              },
            )
            )
          ],
        ),
      )
    )
  );
}
class FlutterTimeDemo extends StatefulWidget{

  final settings;

  const FlutterTimeDemo({required this.settings});

  @override
  _FlutterTimeDemoState createState()=> _FlutterTimeDemoState();

}

class _FlutterTimeDemoState extends State<FlutterTimeDemo>
{
  late String _timeString;

  @override
  void initState(){
    _timeString = "${DateTime.now().hour}:${DateTime.now().minute}";
    Timer.periodic(const Duration(minutes: 1), (Timer t)=>_getCurrentTime());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 40, bottom: 60),
      child: comfortatext(_timeString, 40, widget.settings),
    );
  }

  void _getCurrentTime()  {
    setState(() {
      _timeString = "${DateTime.now().hour}:${DateTime.now().minute}";
    });
  }
}