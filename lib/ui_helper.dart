import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hihi_haha/dayforcast.dart';

const WHITE = Color(0xffFFFFFF);
const BLACK = Color(0xff000000);

class DescriptionCircle extends StatelessWidget {

  final String text;
  final String undercaption;
  final String extra;
  final double fontsize = 22;
  final double width = 68;
  final double height = 68;
  final Color color;

  const DescriptionCircle({super.key, required this.text,
      required this.undercaption, required this.color, required this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2.5, color: Colors.white),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.comfortaa(
                      color: color,
                      fontSize: fontsize,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    extra,
                    style: GoogleFonts.comfortaa(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            )
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.only(top:5),
            width: width,
            height: height,
            child: Text(
              undercaption,
              textAlign: TextAlign.center,
              style: GoogleFonts.comfortaa(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
            ),
          )
        )
      ]
      ),
    );
  }
}

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
                    decoration: const BoxDecoration(
                      color: Color(0xffAEB5B3),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverFixedExtentList(
            itemExtent: 300.0,
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                if (index < 3) {
                  return Container(
                    alignment: Alignment.center,
                    color: const Color(0xffAEB5B3),
                    child: Text(data.days[index].text),
                  );
                }
                return null; // Return null for items beyond index 2
              },
            ),
          ),
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
    Padding(
      padding: const EdgeInsets.only(top: 0.0, left: 40),
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
    Padding(
      padding: const EdgeInsets.only(top: 260.0, left: 40),
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


