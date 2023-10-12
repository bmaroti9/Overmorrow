import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui_helper.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:toggle_switch/toggle_switch.dart';


class SettingsPage extends StatelessWidget {
  final color;

  const SettingsPage({super.key, required this.color});

  @override
  Widget build(BuildContext context) {;
    final color2 = darken(color, 0.5);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        elevation: 0,
        leadingWidth: 50,
        backgroundColor: color,
        title: comfortatext('Settings', 30),
        leading:
          IconButton(
              onPressed: (){
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: comfortatext('Common', 22, color: color2),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.language),
                title: comfortatext('Language', 25),
                value: comfortatext('English', 20)
              ),
              SettingsTile.switchTile(
                onToggle: (value) {},
                initialValue: true,
                leading: Icon(Icons.format_paint),
                title: Text('Enable custom theme'),
              ),
            ],
          ),
        ],
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
