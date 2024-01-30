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

  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  Size size = view.physicalSize / view.devicePixelRatio;

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
        child: Row(
          children: [
            SizedBox(
              height: 550,
              width: 800,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      ParallaxBackground(data: data),
                      buildCurrent(data, size.height),
                      Align(
                        alignment: Alignment.topRight,
                        child: FlutterTimeDemo(settings: data.settings,),
                      )
                    ],
                  )
              ),
            )
          ],
        ),
      )
    )
  );
}

class FlutterTimeDemo extends StatefulWidget{

  final settings;

  const FlutterTimeDemo({this.settings});

  @override
  _FlutterTimeDemoState createState()=> _FlutterTimeDemoState();

}

class _FlutterTimeDemoState extends State<FlutterTimeDemo>
{
  late String _timeString;

  @override
  void initState(){
    _timeString = "${DateTime.now().hour} : ${DateTime.now().minute}";
    Timer.periodic(Duration(seconds:1), (Timer t)=>_getCurrentTime());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //return Text(_timeString, style: TextStyle(fontSize: 30),);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: comfortatext(_timeString, 40, widget.settings),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _getCurrentTime()  {
    setState(() {
      _timeString = "${DateTime.now().hour} : ${DateTime.now().minute}";
    });
  }
}