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

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:overmorrow/main_screens.dart';
import 'package:overmorrow/services/image_service.dart';
import 'package:overmorrow/services/preferences_service.dart';
import 'package:overmorrow/services/widget_service.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'decoders/weather_data.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(
      myCallbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: kDebugMode // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  HomeWidget.registerInteractivityCallback(interactiveCallback);

  if (kDebugMode) {
    print("thissssssssssssssssssssssssssssssssss");
    Workmanager().registerOneOffTask("test_task_${DateTime.now().millisecondsSinceEpoch}", updateWeatherDataKey);
  }

  Workmanager().registerPeriodicTask(
    "updateWeatherWidget",
    updateWeatherDataKey,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected, requiresBatteryNotLow: true),
  );

  await PreferenceUtils.init();

  final data = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  final commonProviders = [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ];

  if (data.shortestSide / ratio < 600) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((value) => runApp(
          MultiProvider(
            providers: commonProviders,
            child: const MyApp(),
          ),
        )
    );
  } else {
    runApp(
      MultiProvider(
        providers: commonProviders,
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = context.watch<ThemeProvider>().getThemeMode;
    final Locale locale = context.select((SettingsProvider p) => p.getLocale);

    final ColorScheme? lightColorScheme = context.watch<ThemeProvider>().getColorSchemeLight;
    final ColorScheme? darkColorScheme = context.watch<ThemeProvider>().getColorSchemeDark;

    final EdgeInsets systemGestureInsets = MediaQuery.of(context).systemGestureInsets;
    if (systemGestureInsets.left > 0) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme dynamicLightColorScheme;
        ColorScheme dynamicDarkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          dynamicLightColorScheme = lightDynamic.harmonized();
          dynamicDarkColorScheme = darkDynamic.harmonized();
        } else {
          dynamicLightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
          dynamicDarkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
        }

        return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
                colorScheme: lightColorScheme ?? dynamicLightColorScheme,
                useMaterial3: true,
                fontFamily: GoogleFonts.outfit().fontFamily,
                pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: FadeForwardsPageTransitionsBuilder()
                    }
                )
            ),
            darkTheme: ThemeData(
                colorScheme: darkColorScheme ?? dynamicDarkColorScheme,
                useMaterial3: true,
                fontFamily: GoogleFonts.outfit().fontFamily,
                pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: FadeForwardsPageTransitionsBuilder()
                    }
                )
            ),
            home: const MyHomePage()
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({key}) : super(key: key);

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  bool isLoading = false;
  WeatherData? data;
  ImageService? imageService;

  String? _lastImageSource;
  String? _lastColorSource;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        updateLocation(context.read<SettingsProvider>().getLatLon, context.read<SettingsProvider>().getLocation);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newImageSource = context.read<SettingsProvider>().getImageSource;
    final newColorSource = context.read<ThemeProvider>().getColorSource;

    //only update if these two have changed
    if (newImageSource != _lastImageSource || newColorSource != _lastColorSource) {
      _lastImageSource = newImageSource;
      _lastColorSource = newColorSource;

      if (data != null) {
        updateImage(data!);
      }
    }
  }


  void updateLocation(String latLon, String location) {
    fetchData(location, latLon);
    context.read<SettingsProvider>().setLocationAndLatLon(location, latLon);
  }

  void fetchData(String location, String latLon) async {
    setState(() {
      isLoading = true;
    });

    const minDuration = Duration(milliseconds: 300);
    final minimumDelayFuture = Future.delayed(minDuration);

    final String provider = context.read<SettingsProvider>().getWeatherProvider;

    final dataFetchFuture = WeatherData.getFullData(location, latLon, provider);

    final results = await Future.wait([
      dataFetchFuture,
      minimumDelayFuture,
    ]);

    WeatherData _data = results[0];

    setState(() {
      data = _data;
    });

    await updateImage(_data);

    //keep it there while the image is animating
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateImage(WeatherData data) async {
    final settingsProvider = context.read<SettingsProvider>();
    final themeProvider = context.read<ThemeProvider>();

    ImageService _imageService = await ImageService.getImageService(
        data.current.condition, data.place, settingsProvider.getImageSource);
    ImageProvider imageProvider = _imageService.image.image;

    if (themeProvider.getColorSource == "image") {
      ColorScheme colorSchemeLight = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: Brightness.light,
      );
      ColorScheme colorSchemeDark = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: Brightness.dark,
      );

      themeProvider.changeColorSchemeToImageScheme(colorSchemeLight, colorSchemeDark);
    }

    // precache the image so that it is guaranteed to be ready for the fading
    if (mounted) {
      await precacheImage(imageProvider, context);
    }

    if (mounted) {
      setState(() {
        imageService = _imageService;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    context.watch<SettingsProvider>().getImageSource;
    context.watch<ThemeProvider>().getColorSource;

    return Stack(
      children: [
        Container(color: Theme.of(context).colorScheme.surface,),
        if (data != null) NewMain(data: data!, updateLocation: updateLocation, imageService: imageService),
        //if (data != null) TabletLayout(data: data!, updateLocation: updateLocation, imageService: imageService),
        LoadingIndicator(isLoading: isLoading,)
      ],
    );
  }
}


class LoadingIndicator extends StatelessWidget {
  final bool isLoading;
  const LoadingIndicator({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final Offset offset = isLoading ? Offset.zero : const Offset(0, -0.3);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isLoading ? 1.0 : 0.0,
      curve: Curves.easeInOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: offset,
        curve: Curves.easeInOut,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Theme.of(context).colorScheme.primaryContainer
            ),
            margin: const EdgeInsets.only(top: 210),
            padding: const EdgeInsets.all(3),
            width: 64,
            height: 64,
            child: const ExpressiveLoadingIndicator(),
          ),
        ),
      ),
    );
  }
}

/*
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();

    setPreferedLocale();
  }

  void setPreferedLocale() async {
    String loc = await getLanguageUsed();
    Locale to = languageNameToLocale[loc] ?? const Locale('en');

    setState(() {
      _locale = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets systemGestureInsets = MediaQuery.of(context).systemGestureInsets;
    if (systemGestureInsets.left > 0) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    // I have no idea why this works but thank you to https://stackoverflow.com/a/72754385
    return MaterialApp(
      locale: _locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(key: Key(_locale.toString()),),
    );
  }
}


class _HomePageState extends State<HomePage> {
  String _sanitizePlaceName(String input) {
    final safe = input.replaceAll(RegExp(r'[^\w\s\-,]'), '').trim();
    if (safe.isEmpty) return ''; // Handle empty input after sanitization
    return safe.length > 100 ? safe.substring(0, 100) : safe;
  }

  Future<Widget> getDays(bool recall, proposedLoc, backupName, startup) async {
    try {

      AppLocalizations localizations = AppLocalizations.of(context)!;

      Map<String, String> settings = await getSettingsUsed();
      String weatherProvider = await getWeatherProvider();
      backupName = _sanitizePlaceName(backupName);

      if (startup) {

        //if the app was launched from a widget, then the place will be set to the widget's place
        Uri? appLaunchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        print(("appLaunchUri", appLaunchUri));
        if (appLaunchUri != null) {
          if (appLaunchUri.host == "opened" && appLaunchUri.queryParameters.containsKey("location")
              && appLaunchUri.queryParameters.containsKey("latlon")) {
            String? placeName = appLaunchUri.queryParameters["location"];
            String? latLon = appLaunchUri.queryParameters["latlon"];

            if (placeName != null && latLon != null) {
              proposedLoc = latLon;
              backupName = placeName;
              startup = false;
            }

          }
        }

        if (startup) {
          List<String> n = await getLastPlace();  //loads the last place you visited
          proposedLoc = n[1];
          backupName = n[0];
          startup = false;
        }
      }

      String absoluteProposed = proposedLoc;
      bool isItCurrentLocation = false;

      if (backupName == 'CurrentLocation') {
        String loc_status = await isLocationSafe(localizations);
        if (loc_status == "enabled") {
          Position position;
          try {
            position = await Geolocator.getCurrentPosition(
                locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium,
                    timeLimit: const Duration(seconds: 3)
                )
            );
          } on TimeoutException {
            try {
              position = (await Geolocator.getLastKnownPosition())!;
            } on Error {
              return ErrorPage(errorMessage: localizations.unableToLocateDevice,
                  updateLocation: updateLocation,
                  icon: Icons.gps_off,
                  place: backupName,
                  settings: settings, provider: weatherProvider, latlng: absoluteProposed);
            }
          } on LocationServiceDisabledException {
            return ErrorPage(errorMessage: localizations.locationServicesAreDisabled,
              updateLocation: updateLocation,
              icon: Icons.gps_off,
              place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
          }

          isItCurrentLocation = true;

          try {

            List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude).timeout(const Duration(seconds: 3));
            Placemark place = placemarks[0];

            backupName = place.locality ?? place.subLocality ?? place.thoroughfare ?? place.subThoroughfare ?? "";
            absoluteProposed = "${position.latitude}, ${position.longitude}";

            //update the last known position for the home screen widgets
            setLastKnownLocation(backupName, absoluteProposed);

          } on Error {
            backupName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
          }
        }
        else {
          return ErrorPage(errorMessage: loc_status, updateLocation: updateLocation, icon: Icons.gps_off,
            place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
        }
      }

      if (proposedLoc == 'query') {
        List<dynamic> suggestedLocations = await LocationService.getRecommendation(backupName, settings["Search provider"], settings);
        if (suggestedLocations.isNotEmpty) {
          var split = json.decode(suggestedLocations[0]);
          absoluteProposed = "${split["lat"]},${split["lon"]}";
          backupName = split["name"];
        } else {
          return ErrorPage(
            errorMessage: '${localizations.placeNotFound}: \n $backupName',
            updateLocation: updateLocation,
            icon: Icons.location_disabled,
            key: Key(backupName),
            place: backupName,
            settings: settings,
            provider: weatherProvider,
            latlng: absoluteProposed,
          );
        }
      }

      String RealName = backupName.toString();
      if (isItCurrentLocation) {
        backupName = 'CurrentLocation';
      }

      WeatherData weatherData;

      try {
        weatherData = await WeatherData.getFullData(settings, RealName, backupName, absoluteProposed, weatherProvider, localizations);
      } on TimeoutException {
        return ErrorPage(errorMessage: localizations.weakOrNoWifiConnection,
          updateLocation: updateLocation,
          icon: Icons.wifi_off, key: Key(backupName),
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
      } on HttpExceptionWithStatus catch (hihi){
        return ErrorPage(errorMessage: "general error at place 1: ${hihi.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,
          shouldAdd: "Please try another weather provider!",);
      } on SocketException {
        return ErrorPage(errorMessage: localizations.notConnectedToTheInternet,
          updateLocation: updateLocation,
          icon: Icons.wifi_off, key: Key(backupName),
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,);
      }
      catch (e, stacktrace) {
        if (kDebugMode) {
          debugPrint('Stack trace: $stacktrace');
        }
        return ErrorPage(errorMessage: "general error at place 1: ${e.toString()}", updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName, settings: settings, provider: weatherProvider, latlng: absoluteProposed,
          shouldAdd: "Please try another weather provider!",);
      }

      await setLastPlace(backupName, absoluteProposed);  // if the code didn't fail
      // then this will be the new startup place

      //WidgetService.saveData('counter', weatherData.current.temp);
      //WidgetService.reloadWidget();

      return WeatherPage(data: weatherData, updateLocation: updateLocation);

    } catch (e, stacktrace) {
      Map<String, String> settings = await getSettingsUsed();
      String weatherProvider = await getWeatherProvider();

      if (kDebugMode) {
        debugPrint('Error fetching weather data: $e');
        debugPrint('Stack trace: $stacktrace');
      }

      await cacheManager2.emptyCache();

      if (recall) {
        return ErrorPage(
          errorMessage: "An error occurred while fetching data",
          updateLocation: updateLocation,
          icon: Icons.bug_report,
          place: backupName,
          settings: settings,
          provider: weatherProvider,
          latlng: 'query',
          shouldAdd: "Please try another weather provider!",
        );
      } else {
        //retry after clearing cache
        return getDays(true, proposedLoc, backupName, startup);
      }
    }
  }

  Widget w1 = Container();
  bool isLoading = false;
  bool startup2 = false;

  @override
  void initState() {
    super.initState();

    //defaults to new york when no previous location was found
    updateLocation('40.7128, -74.0060', "New York", time: 300, startup: true); //just for testing
  }

  Future<void> updateLocation(proposedLoc, backupName, {time = 0, startup = false}) async {

    setState(() {
      HapticFeedback.lightImpact();
      if (startup) {
        startup2 = true;
      }
      isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: time));

    if (!mounted) return;

    try {

      Widget screen = await getDays(false, proposedLoc, backupName, startup);

      setState(() {
        w1 = screen;
        if (!mounted) return;
        if (startup) {
          startup2 = false;
        }
      });

      setState(() {
        isLoading = false;
      });

    } catch (error,s) {

      if (kDebugMode) {
        print((error, s));
      }

      setState(() {
        isLoading = false;
      });
    }

    if (startup) {
      startup2 = false;
    }
  }

  List<Color> colors = getStartBackColor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WHITE,
      body: Stack(
        children: [
          w1,
          if (isLoading) Container(
            color: startup2 ? colors[0] : const Color.fromRGBO(0, 0, 0, 0.7),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: startup2 ? colors[1] : WHITE,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> getStartBackColor() {
  var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool isDarkMode = brightness == Brightness.dark;
  Color back = isDarkMode ? BLACK : WHITE;
  Color front = isDarkMode ? const Color.fromRGBO(250, 250, 250, 0.7) : const Color.fromRGBO(0, 0, 0, 0.3);
  return [back, front];
}

 */