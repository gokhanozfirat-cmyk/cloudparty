import 'app_localizations.dart';

import '../models/cloud_models.dart';

extension CloudPlatformTexts on CloudPlatform {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case CloudPlatform.googleDrive:
        return l10n.cloudGoogleDrive;
      case CloudPlatform.dropbox:
        return l10n.cloudDropbox;
      case CloudPlatform.oneDrive:
        return l10n.cloudOneDrive;
      case CloudPlatform.oneDriveBusiness:
        return l10n.cloudOneDriveBusiness;
      case CloudPlatform.box:
        return l10n.cloudBox;
      case CloudPlatform.pCloud:
        return l10n.cloudPCloud;
      case CloudPlatform.hiDrive:
        return l10n.cloudHiDrive;
      case CloudPlatform.mediafireIos:
        return l10n.cloudMediafireIos;
      case CloudPlatform.webDav:
        return l10n.cloudWebDav;
    }
  }

  String localizedHint(AppLocalizations l10n) {
    switch (this) {
      case CloudPlatform.googleDrive:
        return l10n.cloudHintDriveApi;
      case CloudPlatform.dropbox:
        return l10n.cloudHintDropboxApi;
      case CloudPlatform.oneDrive:
      case CloudPlatform.oneDriveBusiness:
        return l10n.cloudHintMicrosoftGraph;
      case CloudPlatform.box:
        return l10n.cloudHintBoxApi;
      case CloudPlatform.pCloud:
        return l10n.cloudHintPcloudApi;
      case CloudPlatform.hiDrive:
        return l10n.cloudHintHidriveApi;
      case CloudPlatform.mediafireIos:
        return l10n.cloudHintIosClientSupport;
      case CloudPlatform.webDav:
        return l10n.cloudHintWebdav;
    }
  }
}
