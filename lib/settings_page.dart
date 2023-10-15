import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui_helper.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'dayforcast.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/counter.txt');
}

Widget leftpad(Widget child, double hihimargin) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(left: hihimargin, top: 10),
      child: child,
    ),
  );
}

Widget dropdown(Color bgcolor, Function updatePage) {
  List<String> Items = ['˚C', '˚F'];
  return DropdownButton(
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(20),
    icon: const Padding(
      padding: EdgeInsets.only(left:20),
      child: Icon(Icons.expand_circle_down, color: WHITE,),
    ),
    style: GoogleFonts.comfortaa(
      color: WHITE,
      fontSize: 20,
      fontWeight: FontWeight.w300,
    ),
    value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
    items: Items.map((item) {
      return DropdownMenuItem(
        value: item,
        child: new Text(item),
      );
    }).toList(),
    onChanged: (String? value) {
      updatePage(value);
    },
  );
}


class SettingsPage extends StatefulWidget {
  final Color color;

  const SettingsPage({Key? key, required this.color}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState(color: color);
}

class _SettingsPageState extends State<SettingsPage> {
  // You can add your state variables here

  final color;
  _SettingsPageState({required this.color});

  void updatePage(String newSelect) {
    setState(() {
      selected_temp_unit = newSelect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 65,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
          ),
          elevation: 0,
          leadingWidth: 50,
          backgroundColor: darken(color, 0.5),
          title: comfortatext('Settings', 25),
          leading:
          IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 30, left: 10, right: 30),
        color: color,
        child: Column(
            children: [
              leftpad(
                  comfortatext('Units', 25, color: Colors.blueAccent),
                  10
              ),
              leftpad(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      comfortatext('Temperature', 23),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: dropdown(darken(color, 0.4), updatePage),
                      ),
                    ],
                  ),
                  30
              )
            ]
        ),
      ),
    );
  }
}


class MyDrawer extends StatelessWidget {

  final color;

  MyDrawer({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: color,
      elevation: 0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: darken(color, 0.5),
            ),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: comfortatext('Overmorrow', 30, color: color)
                ),
                Align(
                  alignment: Alignment.centerRight,
                    child: comfortatext('Weather', 30, color: color)
                ),
              ],
            ),
          ),
          ListTile(
            title: comfortatext('Settings', 25),
            leading: Icon(Icons.settings, color: WHITE,),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(color: color,)),
              );
            },
          ),
          ListTile(
            title: comfortatext('About', 25),
            leading: Icon(Icons.info_outline, color: WHITE,),
            onTap: () {
              // Handle the option 1 tap here
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            title: comfortatext('Donate', 25),
            leading: Icon(Icons.favorite_border, color: WHITE,),
            onTap: () {
              // Handle the option 1 tap here
              Navigator.pop(context); // Close the drawer
            },
          ),
        ],
      ),
    );
  }
}
