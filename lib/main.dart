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
import 'dart:io';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
import 'main_ui.dart';

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

  final display = PlatformDispatcher.instance.views.first.display;

  final commonProviders = [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ];

  if (display.size.shortestSide / display.devicePixelRatio < 600) {
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

    final textScaleFactor = context.watch<SettingsProvider>().getTextScale;

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

            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: child!,
              );
            },

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
                fontFamilyFallback: const ['NotoSans',],
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
                fontFamilyFallback: const ['NotoSans',],
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
  WeatherError? weatherError;

  String? _lastImageSource;
  String? _lastColorSource;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadOldImageServiceFromCache();
        initialLocationLoad();
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

  Future<void> initialLocationLoad() async {
    String latLon = context.read<SettingsProvider>().getLatLon;
    String location = context.read<SettingsProvider>().getLocation;

    if (Platform.isAndroid) {
      Uri? appLaunchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();

      if (appLaunchUri != null) {
        if (appLaunchUri.host == "opened" && appLaunchUri.queryParameters.containsKey("location")
            && appLaunchUri.queryParameters.containsKey("latlon")) {

          if (appLaunchUri.queryParameters["location"] != null && appLaunchUri.queryParameters["latlon"] != null) {

            if (appLaunchUri.queryParameters["location"] == "CurrentLocation") {
              location = PreferenceUtils.getString('LastKnownPositionName', 'unknown');
              latLon = PreferenceUtils.getString('LastKnownPositionCord', 'unknown');
            }
            else {
              location = appLaunchUri.queryParameters["location"]!;
              latLon = appLaunchUri.queryParameters["latlon"]!;
            }
          }
        }
      }
    }

    updateLocation(latLon, location);
  }

  Future<void> updateLocation(String latLon, String location) async {
    try {
      await fetchData(location, latLon);
      if (mounted) {
        context.read<SettingsProvider>().setLocationAndLatLon(location, latLon);
      }
      weatherError = null;
    } on TimeoutException {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        weatherError = WeatherError(
          errorTitle: AppLocalizations.of(context)!.weakOrNoWifiConnection,
          errorIcon: Icons.signal_wifi_0_bar,
          location: location,
          latLon: latLon,
        );
        isLoading = false;
      });

    } on HttpExceptionWithStatus catch (exception){
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        weatherError = WeatherError(
          errorTitle: "Http exception with status",
          errorIcon: Icons.signal_wifi_bad,
          errorDesc: exception.toString(),
          location: location,
          latLon: latLon,
        );
        isLoading = false;
      });

    } on SocketException {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        weatherError = WeatherError(
          errorTitle: AppLocalizations.of(context)!.notConnectedToTheInternet,
          errorIcon: Icons.wifi_off_rounded,
          location: location,
          latLon: latLon,
        );
        isLoading = false;
      });
    }
    catch (e, stacktrace) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (kDebugMode) {
        debugPrint('Stack trace: $stacktrace');
      }
      setState(() {
        weatherError = WeatherError(
          errorTitle: "General Error",
          errorIcon: Icons.bug_report_outlined,
          errorDesc: e.toString(),
          location: location,
          latLon: latLon,
        );
        isLoading = false;
      });

    }
  }

  Future<void> fetchData(String location, String latLon) async {
    setState(() {
      isLoading = true;
    });

    const minDuration = Duration(milliseconds: 600);
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

    HapticFeedback.selectionClick();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadOldImageServiceFromCache() async {
    String imageSource = context.read<SettingsProvider>().getImageSource;
    ImageService? _imageService = await ImageService.getOldImageServiceFromCache(imageSource);
    if (_imageService != null) {
      if (mounted) {
        await precacheImage(_imageService.image.image, context);
      }

      if (mounted) {
        setState(() {
          imageService = _imageService;
        });
      }
    }
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

    context.select((SettingsProvider p) => p.getImageSource);
    context.select((ThemeProvider p) => p.getColorSource);

    return Stack(
      children: [
        Container(color: Theme.of(context).colorScheme.surface,),
        if (weatherError != null) ErrorPage(weatherError: weatherError!, updateLocation: updateLocation),
        if (data != null && weatherError == null) NewMain(data: data!, updateLocation: updateLocation, imageService: imageService),
        LoadingIndicator(isLoading: isLoading,)
      ],
    );
  }
}