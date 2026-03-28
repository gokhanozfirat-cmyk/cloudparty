import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CloudParty'**
  String get appTitle;

  /// No description provided for @playerControlsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Player controls'**
  String get playerControlsTooltip;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @navClouds.
  ///
  /// In en, this message translates to:
  /// **'Clouds'**
  String get navClouds;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @cloudSynced.
  ///
  /// In en, this message translates to:
  /// **'Cloud synced.'**
  String get cloudSynced;

  /// No description provided for @cloudConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud connection failed. Please try again.'**
  String get cloudConnectFailed;

  /// No description provided for @cloudSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync failed. Please reconnect and retry.'**
  String get cloudSyncFailed;

  /// No description provided for @trackDownloadedOffline.
  ///
  /// In en, this message translates to:
  /// **'Track downloaded for offline mode.'**
  String get trackDownloadedOffline;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check URL and network.'**
  String get downloadFailed;

  /// No description provided for @connectedMessage.
  ///
  /// In en, this message translates to:
  /// **'{platform} connected.'**
  String connectedMessage(String platform);

  /// No description provided for @addFileUrl.
  ///
  /// In en, this message translates to:
  /// **'Add file URL'**
  String get addFileUrl;

  /// No description provided for @trackTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Track title'**
  String get trackTitleLabel;

  /// No description provided for @audioUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio URL'**
  String get audioUrlLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @invalidTitleOrUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid title and URL.'**
  String get invalidTitleOrUrl;

  /// No description provided for @trackAddedFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Track added from URL.'**
  String get trackAddedFromUrl;

  /// No description provided for @createPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylistTitle;

  /// No description provided for @playlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameLabel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @defaultPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'My Playlist'**
  String get defaultPlaylistName;

  /// No description provided for @trackMovedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Track moved to playlist.'**
  String get trackMovedToPlaylist;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @noTracksInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No tracks in this playlist.'**
  String get noTracksInPlaylist;

  /// No description provided for @supportedCloudServices.
  ///
  /// In en, this message translates to:
  /// **'Supported cloud services'**
  String get supportedCloudServices;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: {formats}'**
  String supportedFormats(String formats);

  /// No description provided for @connectAnotherCloud.
  ///
  /// In en, this message translates to:
  /// **'Connect another cloud'**
  String get connectAnotherCloud;

  /// No description provided for @noCloudConnected.
  ///
  /// In en, this message translates to:
  /// **'No cloud connected yet. Add one to scan audio tracks.'**
  String get noCloudConnected;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String filesCount(int count);

  /// No description provided for @addUrlTrackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add URL track'**
  String get addUrlTrackTooltip;

  /// No description provided for @syncNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowTooltip;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Library is empty. Connect a cloud and sync to fetch tracks.'**
  String get libraryEmpty;

  /// No description provided for @noPlaylistYet.
  ///
  /// In en, this message translates to:
  /// **'No playlist yet.'**
  String get noPlaylistYet;

  /// No description provided for @autoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay'**
  String get autoplay;

  /// No description provided for @noTrackSelected.
  ///
  /// In en, this message translates to:
  /// **'No track selected yet.'**
  String get noTrackSelected;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeatMode.
  ///
  /// In en, this message translates to:
  /// **'Repeat {mode}'**
  String repeatMode(String mode);

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'one'**
  String get repeatOne;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @timerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get timerOff;

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String tracksCount(int count);

  /// No description provided for @moveToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Move to playlist'**
  String get moveToPlaylist;

  /// No description provided for @downloadForOffline.
  ///
  /// In en, this message translates to:
  /// **'Download for offline'**
  String get downloadForOffline;

  /// No description provided for @iosShort.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get iosShort;

  /// No description provided for @cloudGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get cloudGoogleDrive;

  /// No description provided for @cloudDropbox.
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get cloudDropbox;

  /// No description provided for @cloudOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get cloudOneDrive;

  /// No description provided for @cloudOneDriveBusiness.
  ///
  /// In en, this message translates to:
  /// **'OneDrive for Business'**
  String get cloudOneDriveBusiness;

  /// No description provided for @cloudBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get cloudBox;

  /// No description provided for @cloudPCloud.
  ///
  /// In en, this message translates to:
  /// **'pCloud'**
  String get cloudPCloud;

  /// No description provided for @cloudHiDrive.
  ///
  /// In en, this message translates to:
  /// **'HiDrive'**
  String get cloudHiDrive;

  /// No description provided for @cloudMediafireIos.
  ///
  /// In en, this message translates to:
  /// **'Mediafire (iOS)'**
  String get cloudMediafireIos;

  /// No description provided for @cloudWebDav.
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get cloudWebDav;

  /// No description provided for @cloudHintDriveApi.
  ///
  /// In en, this message translates to:
  /// **'OAuth + Drive API'**
  String get cloudHintDriveApi;

  /// No description provided for @cloudHintDropboxApi.
  ///
  /// In en, this message translates to:
  /// **'OAuth + Dropbox API'**
  String get cloudHintDropboxApi;

  /// No description provided for @cloudHintMicrosoftGraph.
  ///
  /// In en, this message translates to:
  /// **'OAuth + Microsoft Graph'**
  String get cloudHintMicrosoftGraph;

  /// No description provided for @cloudHintBoxApi.
  ///
  /// In en, this message translates to:
  /// **'OAuth + Box API'**
  String get cloudHintBoxApi;

  /// No description provided for @cloudHintPcloudApi.
  ///
  /// In en, this message translates to:
  /// **'OAuth + pCloud API'**
  String get cloudHintPcloudApi;

  /// No description provided for @cloudHintHidriveApi.
  ///
  /// In en, this message translates to:
  /// **'OAuth + HiDrive API'**
  String get cloudHintHidriveApi;

  /// No description provided for @cloudHintIosClientSupport.
  ///
  /// In en, this message translates to:
  /// **'iOS client support'**
  String get cloudHintIosClientSupport;

  /// No description provided for @cloudHintWebdav.
  ///
  /// In en, this message translates to:
  /// **'ownCloud / NextCloud / NAS'**
  String get cloudHintWebdav;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
