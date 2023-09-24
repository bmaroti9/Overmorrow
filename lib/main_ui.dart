import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui_helper.dart';


class WeatherPage extends StatelessWidget {
  final data;

  const WeatherPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.transparent, // Set background to transparent
            bottom: PreferredSize(
              preferredSize: Size(0, MediaQuery.of(context).size.height * 0.4),
              child: Container(),
            ),
            pinned: false,
            expandedHeight: MediaQuery.of(context).size.height * 0.92,
            flexibleSpace: Stack(
              children: [
                ParallaxBackground(data: data,),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      child: buildCurrent(data), // Place your buildCurrent widget here
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: data.current.backcolor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          buildHihiDays(data),
        ],
      ),
    );
  }
}

class ParallaxBackground extends StatelessWidget {
  final data;
  const ParallaxBackground({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backdrops/${data!.current.backdrop}'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


Widget buildCurrent(var data) => Column(
  children: [
    SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, left: 40),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              data.place,
              style: GoogleFonts.comfortaa(
                  fontSize: 42,
                  color: data.current.contentColor[0]
              ),
            )
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 150.0, left: 40),
      child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            '${data.current.temp}°',
            style: GoogleFonts.comfortaa(
              color: data.current.contentColor[1],
              fontSize: 85,
              fontWeight: FontWeight.w100,
            ),
          )
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            data.current.text,
            style: GoogleFonts.comfortaa(
              color: data.current.contentColor[1],
              fontSize: 50,
              height: 0.7,
              fontWeight: FontWeight.w300,
            ),
          )
      ),
    ),
    Container(
        padding: const EdgeInsets.only(top:30),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DescriptionCircle(
                color: WHITE,
                text: '${data.current.maxtemp}°',
                undercaption: 'temp. max',
                extra: '',
              ),
              DescriptionCircle(
                color: WHITE,
                text: '${data.current.mintemp}°',
                undercaption: 'temp. min',
                extra: '',
              ),
              DescriptionCircle(
                color: WHITE,
                text: '${data.current.precip}',
                undercaption: 'precip.',
                extra: 'mm',
              ),
              DescriptionCircle(
                color: WHITE,
                text: '${data.current.wind}',
                undercaption: 'wind',
                extra: 'kmh',
              ),
            ]
        )
    )
  ],
);


Widget buildDays(var thesedays) => ListView.builder(
    itemCount: thesedays.length,
    itemExtent: 380,
    itemBuilder: (context, index) {
      final day = thesedays[index];

      return Container(
        //margin: EdgeInsets.all(0),
        //color: day.color,
        decoration: BoxDecoration(
          color: day.color,
          image: const DecorationImage(
              image: AssetImage("assets/images/squigly_line.png"),
              fit: BoxFit.fill),
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
              height: 10, child: Image.asset('assets/images/' + day.icon)),
        ),
      );
    });

Widget buildHihiDays(var data) => SliverFixedExtentList(
  itemExtent: 180.0,
  delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          if (index < data.days.length) {
            final day = data.days[index];

            return Container(
              decoration: BoxDecoration(
                color: darken(data.current.backcolor, index * 0.03),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Text(
                      day.name,
                      style: GoogleFonts.comfortaa(
                        color: WHITE,
                        fontSize: 30,
                        height: 0.7,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50, bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align the Row to the right
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 20),
                          child: Image.asset(
                            'assets/icons/' + day.icon,
                            fit: BoxFit.contain,
                            height: 45,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            day.text,
                            style: GoogleFonts.comfortaa(
                              color: WHITE,
                              fontSize: 25,
                              height: 0.7,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            day.minmaxtemp,
                            style: GoogleFonts.comfortaa(
                              color: WHITE,
                              fontSize: 22,
                              height: 0.7,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            );
          }
          return null;
    },
  ),
);