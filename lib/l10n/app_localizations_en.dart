// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CloudParty';

  @override
  String get playerControlsTooltip => 'Player controls';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get navClouds => 'Clouds';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get cloudSynced => 'Cloud synced.';

  @override
  String get cloudConnectFailed => 'Cloud connection failed. Please try again.';

  @override
  String get cloudSyncFailed =>
      'Cloud sync failed. Please reconnect and retry.';

  @override
  String get trackDownloadedOffline => 'Track downloaded for offline mode.';

  @override
  String get downloadFailed => 'Download failed. Check URL and network.';

  @override
  String connectedMessage(String platform) {
    return '$platform connected.';
  }

  @override
  String get addFileUrl => 'Add file URL';

  @override
  String get trackTitleLabel => 'Track title';

  @override
  String get audioUrlLabel => 'Audio URL';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get invalidTitleOrUrl => 'Enter a valid title and URL.';

  @override
  String get trackAddedFromUrl => 'Track added from URL.';

  @override
  String get createPlaylistTitle => 'Create playlist';

  @override
  String get playlistNameLabel => 'Playlist name';

  @override
  String get create => 'Create';

  @override
  String get defaultPlaylistName => 'My Playlist';

  @override
  String get trackMovedToPlaylist => 'Track moved to playlist.';

  @override
  String get play => 'Play';

  @override
  String get noTracksInPlaylist => 'No tracks in this playlist.';

  @override
  String get supportedCloudServices => 'Supported cloud services';

  @override
  String supportedFormats(String formats) {
    return 'Supported formats: $formats';
  }

  @override
  String get connectAnotherCloud => 'Connect cloud';

  @override
  String get noCloudConnected =>
      'No cloud connected yet. Add one to scan audio tracks.';

  @override
  String filesCount(int count) {
    return '$count files';
  }

  @override
  String get addUrlTrackTooltip => 'Add URL track';

  @override
  String get syncNowTooltip => 'Sync now';

  @override
  String get libraryEmpty =>
      'Library is empty. Connect a cloud and sync to fetch tracks.';

  @override
  String get noPlaylistYet => 'No playlist yet.';

  @override
  String get autoplay => 'Autoplay';

  @override
  String get noTrackSelected => 'No track selected yet.';

  @override
  String get shuffle => 'Shuffle';

  @override
  String repeatMode(String mode) {
    return 'Repeat $mode';
  }

  @override
  String get repeatOff => 'off';

  @override
  String get repeatAll => 'all';

  @override
  String get repeatOne => 'one';

  @override
  String get speed => 'Speed';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get timerOff => 'Off';

  @override
  String tracksCount(int count) {
    return '$count tracks';
  }

  @override
  String get moveToPlaylist => 'Move to playlist';

  @override
  String get downloadForOffline => 'Download for offline';

  @override
  String get iosShort => 'iOS';

  @override
  String get cloudGoogleDrive => 'Google Drive';

  @override
  String get cloudDropbox => 'Dropbox';

  @override
  String get cloudOneDrive => 'OneDrive';

  @override
  String get cloudOneDriveBusiness => 'OneDrive for Business';

  @override
  String get cloudBox => 'Box';

  @override
  String get cloudPCloud => 'pCloud';

  @override
  String get cloudHiDrive => 'HiDrive';

  @override
  String get cloudMediafireIos => 'Mediafire (iOS)';

  @override
  String get cloudWebDav => 'WebDAV';

  @override
  String get cloudHintDriveApi => 'OAuth + Drive API';

  @override
  String get cloudHintDropboxApi => 'OAuth + Dropbox API';

  @override
  String get cloudHintMicrosoftGraph => 'OAuth + Microsoft Graph';

  @override
  String get cloudHintBoxApi => 'OAuth + Box API';

  @override
  String get cloudHintPcloudApi => 'OAuth + pCloud API';

  @override
  String get cloudHintHidriveApi => 'OAuth + HiDrive API';

  @override
  String get cloudHintIosClientSupport => 'iOS client support';

  @override
  String get cloudHintWebdav => 'ownCloud / NextCloud / NAS';
}
