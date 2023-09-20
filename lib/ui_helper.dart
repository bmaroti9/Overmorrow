import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final days ;

  WeatherPage({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: WHITE,
            bottom: PreferredSize(
              child: Container(),
              preferredSize: Size(0, 20),
            ),
            pinned: false,
            expandedHeight: MediaQuery.of(context).size.height * 0.8,
            flexibleSpace: Stack(
              children: [
                const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/backdrops/fog.jpg'),
                    )),
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: WHITE,
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
            itemExtent: 50.0,

            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return Container(
                  alignment: Alignment.center,
                  color: WHITE,
                  child: Text('List Item $index'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParallaxBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backdrops/fog.jpg'), // Replace with your image path
          fit: BoxFit.cover,
        ),
      ),

    );
  }
}


