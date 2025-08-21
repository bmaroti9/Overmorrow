import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bg'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('ta'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get feelsLike;

  /// No description provided for @precipCapital.
  ///
  /// In en, this message translates to:
  /// **'Precip.'**
  String get precipCapital;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @windCapital.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get windCapital;

  /// No description provided for @uvCapital.
  ///
  /// In en, this message translates to:
  /// **'UV'**
  String get uvCapital;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrowLowercase.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get tomorrowLowercase;

  /// No description provided for @overmorrowLowercase.
  ///
  /// In en, this message translates to:
  /// **'Overmorrow'**
  String get overmorrowLowercase;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @precipitaion.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get precipitaion;

  /// No description provided for @rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// No description provided for @clearNight.
  ///
  /// In en, this message translates to:
  /// **'Clear Night'**
  String get clearNight;

  /// No description provided for @partlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy'**
  String get partlyCloudy;

  /// No description provided for @clearSky.
  ///
  /// In en, this message translates to:
  /// **'Clear Sky'**
  String get clearSky;

  /// No description provided for @overcast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get overcast;

  /// No description provided for @haze.
  ///
  /// In en, this message translates to:
  /// **'Haze'**
  String get haze;

  /// No description provided for @sleet.
  ///
  /// In en, this message translates to:
  /// **'Sleet'**
  String get sleet;

  /// No description provided for @drizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get drizzle;

  /// No description provided for @thunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get thunderstorm;

  /// No description provided for @heavySnow.
  ///
  /// In en, this message translates to:
  /// **'Heavy Snow'**
  String get heavySnow;

  /// No description provided for @fog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get fog;

  /// No description provided for @snow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get snow;

  /// No description provided for @heavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy Rain'**
  String get heavyRain;

  /// No description provided for @cloudyNight.
  ///
  /// In en, this message translates to:
  /// **'Cloudy Night'**
  String get cloudyNight;

  /// No description provided for @weakOrNoWifiConnection.
  ///
  /// In en, this message translates to:
  /// **'Weak or no wifi connection'**
  String get weakOrNoWifiConnection;

  /// No description provided for @notConnectedToTheInternet.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the internet'**
  String get notConnectedToTheInternet;

  /// No description provided for @placeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Place not found'**
  String get placeNotFound;

  /// No description provided for @unableToLocateDevice.
  ///
  /// In en, this message translates to:
  /// **'Unable to locate device'**
  String get unableToLocateDevice;

  /// No description provided for @locationServicesAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'location services are disabled.'**
  String get locationServicesAreDisabled;

  /// No description provided for @locationPermissionIsDenied.
  ///
  /// In en, this message translates to:
  /// **'location permission is denied'**
  String get locationPermissionIsDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'location permission denied forever'**
  String get locationPermissionDeniedForever;

  /// No description provided for @grantLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'grant location permission'**
  String get grantLocationPermission;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'current location'**
  String get currentLocation;

  /// No description provided for @favoritesLowercase.
  ///
  /// In en, this message translates to:
  /// **'favorites'**
  String get favoritesLowercase;

  /// No description provided for @failedToAccessGps.
  ///
  /// In en, this message translates to:
  /// **'failed to access gps'**
  String get failedToAccessGps;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @sunriseSunset.
  ///
  /// In en, this message translates to:
  /// **'sunrise/sunset'**
  String get sunriseSunset;

  /// No description provided for @airQuality.
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get airQuality;

  /// No description provided for @airQualityLowercase.
  ///
  /// In en, this message translates to:
  /// **'air quality'**
  String get airQualityLowercase;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'fair'**
  String get fair;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get moderate;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'poor'**
  String get poor;

  /// No description provided for @veryPoor.
  ///
  /// In en, this message translates to:
  /// **'very poor'**
  String get veryPoor;

  /// No description provided for @unhealthy.
  ///
  /// In en, this message translates to:
  /// **'unhealthy'**
  String get unhealthy;

  /// No description provided for @radar.
  ///
  /// In en, this message translates to:
  /// **'radar'**
  String get radar;

  /// No description provided for @colorMode.
  ///
  /// In en, this message translates to:
  /// **'Color mode'**
  String get colorMode;

  /// No description provided for @weatherProvderLowercase.
  ///
  /// In en, this message translates to:
  /// **'weather provider'**
  String get weatherProvderLowercase;

  /// No description provided for @timeMode.
  ///
  /// In en, this message translates to:
  /// **'Time mode'**
  String get timeMode;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @dailyLowercase.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get dailyLowercase;

  /// No description provided for @searchProvider.
  ///
  /// In en, this message translates to:
  /// **'Search provider'**
  String get searchProvider;

  /// No description provided for @updatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'updated, just now'**
  String get updatedJustNow;

  /// No description provided for @colorSource.
  ///
  /// In en, this message translates to:
  /// **'Color source'**
  String get colorSource;

  /// No description provided for @imageSource.
  ///
  /// In en, this message translates to:
  /// **'Image source'**
  String get imageSource;

  /// short for summary, overview, gist or something similar, used in the context of hourly list
  ///
  /// In en, this message translates to:
  /// **'sum'**
  String get sumLowercase;

  /// No description provided for @precipLowercase.
  ///
  /// In en, this message translates to:
  /// **'precip'**
  String get precipLowercase;

  /// No description provided for @windLowercase.
  ///
  /// In en, this message translates to:
  /// **'wind'**
  String get windLowercase;

  /// No description provided for @uvLowercase.
  ///
  /// In en, this message translates to:
  /// **'uv'**
  String get uvLowercase;

  /// No description provided for @goodAqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Air quality is excellent; no health risk.'**
  String get goodAqiDesc;

  /// No description provided for @fairAqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Acceptable air quality; minor risk for sensitive people.'**
  String get fairAqiDesc;

  /// No description provided for @moderateAqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Sensitive individuals may experience mild effects.'**
  String get moderateAqiDesc;

  /// No description provided for @poorAqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Health effects possible for everyone, serious for sensitive groups.'**
  String get poorAqiDesc;

  /// No description provided for @veryPoorAqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Serious health effects for everyone.'**
  String get veryPoorAqiDesc;

  /// No description provided for @unhealthyAqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Emergency conditions; severe health effects for all.'**
  String get unhealthyAqiDesc;

  /// No description provided for @photoByXOnUnsplash.
  ///
  /// In en, this message translates to:
  /// **'Photo, by ,x, on ,Unsplash'**
  String get photoByXOnUnsplash;

  /// No description provided for @sourceCodeLowercase.
  ///
  /// In en, this message translates to:
  /// **'source code'**
  String get sourceCodeLowercase;

  /// No description provided for @emailLowercase.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get emailLowercase;

  /// No description provided for @reportAnIssueLowercase.
  ///
  /// In en, this message translates to:
  /// **'report an issue'**
  String get reportAnIssueLowercase;

  /// No description provided for @donateLowercase.
  ///
  /// In en, this message translates to:
  /// **'donate'**
  String get donateLowercase;

  /// No description provided for @versionUppercase.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionUppercase;

  /// No description provided for @apiAndServices.
  ///
  /// In en, this message translates to:
  /// **'APIs & Services'**
  String get apiAndServices;

  /// No description provided for @licenseUppercase.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get licenseUppercase;

  /// No description provided for @weatherDataLowercase.
  ///
  /// In en, this message translates to:
  /// **'weather data'**
  String get weatherDataLowercase;

  /// No description provided for @imagesLowercase.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get imagesLowercase;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appearanceSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'color theme, image source'**
  String get appearanceSettingDesc;

  /// No description provided for @generalSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'time mode, font size'**
  String get generalSettingDesc;

  /// No description provided for @languageSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'the language used'**
  String get languageSettingDesc;

  /// No description provided for @unitsSettingdesc.
  ///
  /// In en, this message translates to:
  /// **'the units used in the app'**
  String get unitsSettingdesc;

  /// No description provided for @aboutSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'about this app'**
  String get aboutSettingsDesc;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get hr;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @layoutSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'widget order, customization'**
  String get layoutSettingDesc;

  /// No description provided for @thirtyMinutes.
  ///
  /// In en, this message translates to:
  /// **'30m'**
  String get thirtyMinutes;

  /// No description provided for @mainPollutant.
  ///
  /// In en, this message translates to:
  /// **'main pollutant'**
  String get mainPollutant;

  /// No description provided for @alderPollen.
  ///
  /// In en, this message translates to:
  /// **'Alder Pollen'**
  String get alderPollen;

  /// No description provided for @birchPollen.
  ///
  /// In en, this message translates to:
  /// **'Birch Pollen'**
  String get birchPollen;

  /// No description provided for @grassPollen.
  ///
  /// In en, this message translates to:
  /// **'Grass Pollen'**
  String get grassPollen;

  /// No description provided for @mugwortPollen.
  ///
  /// In en, this message translates to:
  /// **'Mugwort Pollen'**
  String get mugwortPollen;

  /// No description provided for @olivePollen.
  ///
  /// In en, this message translates to:
  /// **'Olive Pollen'**
  String get olivePollen;

  /// No description provided for @ragweedPollen.
  ///
  /// In en, this message translates to:
  /// **'Ragweed Pollen'**
  String get ragweedPollen;

  /// No description provided for @dailyAqi.
  ///
  /// In en, this message translates to:
  /// **'daily AQI'**
  String get dailyAqi;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get dateFormat;

  /// short for day
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get d;

  /// No description provided for @aerosolOpticalDepth.
  ///
  /// In en, this message translates to:
  /// **'aerosol optical depth'**
  String get aerosolOpticalDepth;

  /// No description provided for @dust.
  ///
  /// In en, this message translates to:
  /// **'dust'**
  String get dust;

  /// No description provided for @europeanAqi.
  ///
  /// In en, this message translates to:
  /// **'european aqi'**
  String get europeanAqi;

  /// No description provided for @unitedStatesAqi.
  ///
  /// In en, this message translates to:
  /// **'united states aqi'**
  String get unitedStatesAqi;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offline;

  /// No description provided for @helpTranslate.
  ///
  /// In en, this message translates to:
  /// **'help translate'**
  String get helpTranslate;

  /// No description provided for @extremelyClear.
  ///
  /// In en, this message translates to:
  /// **'extremely clear'**
  String get extremelyClear;

  /// No description provided for @veryClear.
  ///
  /// In en, this message translates to:
  /// **'very clear'**
  String get veryClear;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'clear'**
  String get clear;

  /// No description provided for @slightlyHazy.
  ///
  /// In en, this message translates to:
  /// **'slightly hazy'**
  String get slightlyHazy;

  /// No description provided for @hazy.
  ///
  /// In en, this message translates to:
  /// **'hazy'**
  String get hazy;

  /// No description provided for @veryHazy.
  ///
  /// In en, this message translates to:
  /// **'very hazy'**
  String get veryHazy;

  /// No description provided for @extremelyHazy.
  ///
  /// In en, this message translates to:
  /// **'extremely hazy'**
  String get extremelyHazy;

  /// text displayed at the end of the air quality page, crediting open-meteo for the data
  ///
  /// In en, this message translates to:
  /// **'powered by open-meteo'**
  String get poweredByOpenMeteo;

  /// rain in the next half an hour
  ///
  /// In en, this message translates to:
  /// **'rain in the next half an hour'**
  String get rainInHalfHour;

  /// rain in the next X minutes
  ///
  /// In en, this message translates to:
  /// **'rain in the next {minutes, plural, =1 {minute} other {{minutes} minutes}}'**
  String rainInMinutes(int minutes);

  /// rain in the next hour
  ///
  /// In en, this message translates to:
  /// **'rain in the next hour'**
  String get rainInOneHour;

  /// rain in the next X hours
  ///
  /// In en, this message translates to:
  /// **'rain in the next {hours, plural, =1 {hour} other {{hours} hours}}'**
  String rainInHours(int hours);

  /// rain expected in the next X minutes
  ///
  /// In en, this message translates to:
  /// **'rain expected in {minutes, plural, =1 {minute} other {{minutes} minutes}}'**
  String rainExpectedInMinutes(int minutes);

  /// rain expected in the next hour
  ///
  /// In en, this message translates to:
  /// **'rain expected in an hour'**
  String get rainExpectedInOneHour;

  /// rain expected in the next X hours
  ///
  /// In en, this message translates to:
  /// **'rain expected in {hours, plural, =1 {hour} other {{hours} hours}}'**
  String rainExpectedInHours(int hours);

  /// No description provided for @updatedXMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'updated, {minutes} min ago'**
  String updatedXMinutesAgo(Object minutes);

  /// updated x hours ago
  ///
  /// In en, this message translates to:
  /// **'updated, {hours, plural, =1 {1 hour} other {{hours} hours}} ago'**
  String updatedXHoursAgo(int hours);

  /// updated x days ago
  ///
  /// In en, this message translates to:
  /// **'updated, {days, plural, =1 {1 day} other {{days} days}} ago'**
  String updatedXDaysAgo(int days);

  /// setting for enabling or disabling haptic feedback for the radar
  ///
  /// In en, this message translates to:
  /// **'Radar haptics'**
  String get radarHaptics;

  /// No description provided for @alertsCapital.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsCapital;

  /// No description provided for @alertsLowercase.
  ///
  /// In en, this message translates to:
  /// **'alerts'**
  String get alertsLowercase;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'severity'**
  String get severity;

  /// No description provided for @certainty.
  ///
  /// In en, this message translates to:
  /// **'certainty'**
  String get certainty;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'urgency'**
  String get urgency;

  /// No description provided for @areas.
  ///
  /// In en, this message translates to:
  /// **'areas'**
  String get areas;

  /// light precipitation
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get light;

  /// heavy precipitation
  ///
  /// In en, this message translates to:
  /// **'heavy'**
  String get heavy;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'show less'**
  String get showLess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bg',
        'de',
        'el',
        'en',
        'es',
        'fi',
        'fr',
        'hr',
        'hu',
        'id',
        'it',
        'ja',
        'nl',
        'pl',
        'pt',
        'ru',
        'ta',
        'tr',
        'uk',
        'ur',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bg':
      return AppLocalizationsBg();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
