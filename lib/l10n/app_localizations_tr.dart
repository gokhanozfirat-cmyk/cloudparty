// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'CloudParty';

  @override
  String get playerControlsTooltip => 'Oynatıcı kontrolleri';

  @override
  String get languageLabel => 'Dil';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get navClouds => 'Bulutlar';

  @override
  String get navLibrary => 'Kütüphane';

  @override
  String get navPlaylists => 'Çalma Listeleri';

  @override
  String get cloudSynced => 'Bulut senkronlandı.';

  @override
  String get cloudConnectFailed =>
      'Bulut bağlantısı kurulamadı. Lütfen tekrar dene.';

  @override
  String get cloudSyncFailed =>
      'Bulut senkronu başarısız. Tekrar bağlayıp yeniden dene.';

  @override
  String get trackDownloadedOffline => 'Parça çevrimdışı mod için indirildi.';

  @override
  String get downloadFailed => 'İndirme başarısız. URL ve ağı kontrol et.';

  @override
  String connectedMessage(String platform) {
    return '$platform bağlandı.';
  }

  @override
  String get addFileUrl => 'Dosya URL\'si ekle';

  @override
  String get trackTitleLabel => 'Parça başlığı';

  @override
  String get audioUrlLabel => 'Ses URL\'si';

  @override
  String get cancel => 'İptal';

  @override
  String get add => 'Ekle';

  @override
  String get invalidTitleOrUrl => 'Geçerli bir başlık ve URL gir.';

  @override
  String get trackAddedFromUrl => 'Parça URL ile eklendi.';

  @override
  String get createPlaylistTitle => 'Çalma listesi oluştur';

  @override
  String get playlistNameLabel => 'Çalma listesi adı';

  @override
  String get create => 'Oluştur';

  @override
  String get defaultPlaylistName => 'Listem';

  @override
  String get trackMovedToPlaylist => 'Parça çalma listesine taşındı.';

  @override
  String get play => 'Oynat';

  @override
  String get noTracksInPlaylist => 'Bu çalma listesinde parça yok.';

  @override
  String get supportedCloudServices => 'Desteklenen bulut servisleri';

  @override
  String supportedFormats(String formats) {
    return 'Desteklenen formatlar: $formats';
  }

  @override
  String get connectAnotherCloud => 'Bulut bağla';

  @override
  String get noCloudConnected =>
      'Henüz bulut bağlanmadı. Sesleri taramak için bir tane ekle.';

  @override
  String filesCount(int count) {
    return '$count dosya';
  }

  @override
  String get addUrlTrackTooltip => 'URL ile parça ekle';

  @override
  String get syncNowTooltip => 'Şimdi senkronla';

  @override
  String get libraryEmpty =>
      'Kütüphane boş. Bir bulut bağlayıp senkronlayarak parçaları getir.';

  @override
  String get noPlaylistYet => 'Henüz çalma listesi yok.';

  @override
  String get autoplay => 'Otomatik oynat';

  @override
  String get noTrackSelected => 'Henüz bir parça seçilmedi.';

  @override
  String get shuffle => 'Karışık';

  @override
  String repeatMode(String mode) {
    return 'Tekrar $mode';
  }

  @override
  String get repeatOff => 'kapalı';

  @override
  String get repeatAll => 'tümü';

  @override
  String get repeatOne => 'tek';

  @override
  String get speed => 'Hız';

  @override
  String get sleepTimer => 'Uyku zamanlayıcısı';

  @override
  String get timerOff => 'Kapalı';

  @override
  String tracksCount(int count) {
    return '$count parça';
  }

  @override
  String get moveToPlaylist => 'Çalma listesine taşı';

  @override
  String get downloadForOffline => 'Çevrimdışı indir';

  @override
  String get iosShort => 'iOS';

  @override
  String get cloudGoogleDrive => 'Google Drive';

  @override
  String get cloudDropbox => 'Dropbox';

  @override
  String get cloudOneDrive => 'OneDrive';

  @override
  String get cloudOneDriveBusiness => 'OneDrive İş';

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
  String get cloudHintIosClientSupport => 'iOS istemci desteği';

  @override
  String get cloudHintWebdav => 'ownCloud / NextCloud / NAS';
}
