import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui_helper.dart';

List<String> unitsList = ['Temperature', 'Volume', 'Wind', 'Pressure'];

Map<String, List<String>> settingSwitches = {
  'Temperature': ['˚C', '˚F'],
  'Volume': ['mm', 'in'],
  'Wind': ['m/s', 'kph', 'mph'],
  'Pressure' : ['mmHg', 'inHg', 'mb', 'hPa']
};

Future<List<String>> getUnitsUsed() async {
  List<String> units = [];
  for (String name in unitsList) {
    final prefs = await SharedPreferences.getInstance();
    final ifnot = settingSwitches[name] ?? ['˚C', '˚F'];
    final used = prefs.getString('unit$name') ?? ifnot[0];
    units.add(used);
  }
  return units;
}

SetData(String name, String to) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(name, to);
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

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit) {
  List<String> Items = settingSwitches[name] ?? ['˚C', '˚F'];
  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(20),
    icon: const Padding(
      padding: EdgeInsets.only(left:20),
      child: Icon(Icons.arrow_drop_down, color: WHITE,),
    ),
    style: GoogleFonts.comfortaa(
      color: WHITE,
      fontSize: 20,
      fontWeight: FontWeight.w300,
    ),
    //value: selected_temp_unit.isNotEmpty ? selected_temp_unit : null, // guard it with null if empty
    value: unit,
    items: Items.map((item) {
      return DropdownMenuItem(
        value: item,
        child: new Text(item),
      );
    }).toList(),
    onChanged: (Object? value) {
      updatePage(name, value);
    }
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

  void updatePage(String name, String to) {
    setState(() {
      //selected_temp_unit = newSelect;
      print(('unit$name', to));
      SetData('unit$name', to);
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
          backgroundColor: darken(color, 0.3),
          title: comfortatext('Settings', 25),
          leading:
          IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: WHITE,),
          )
      ),
      body: FutureBuilder<List<String>>(
        future: getUnitsUsed(),
        builder: (BuildContext context,
            AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
              child: ErrorWidget(snapshot.error as Object),
            );
          }
          //return buildWholeThing(snapshot.data);
          return UnitsMain(color, snapshot.data, updatePage);
        },
      ),
    );
  }
}

Widget UnitsMain(Color color, List<String>? units, Function updatePage) {
  return Container(
    padding: const EdgeInsets.only(top: 30, left: 10, right: 30),
    color: color,
    child: Column(
        children: [
          leftpad(
              comfortatext('Units', 30, color: WHITE),
              10
          ),
          leftpad(
              SizedBox(
                height: 70.0 * units!.length,
                child: ListView.builder(
                  itemCount: units.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          comfortatext(unitsList[index], 23),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 130,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: darken(color, 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10, right: 4),
                                    child: dropdown(
                                        darken(color, 0.2),
                                        unitsList[index],
                                        updatePage,
                                        units[index]
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              30
          )
        ]
    ),
  );
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
            leading: const Icon(Icons.settings, color: WHITE,),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(color: color,)),
              );
            },
          ),
          ListTile(
            title: comfortatext('About', 25),
            leading: const Icon(Icons.info_outline, color: WHITE,),
            onTap: () {
              // Handle the option 1 tap here
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            title: comfortatext('Donate', 25),
            leading: const Icon(Icons.favorite_border, color: WHITE,),
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
