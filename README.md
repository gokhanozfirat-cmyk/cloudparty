# CloudParty

CloudParty is a Flutter app for connecting cloud drives and playing audio files with playlists and offline support.

## Current status

- Localization: Turkish + English
- Playlist management + autoplay switch
- Offline download + playback
- Player controls: speed, shuffle/repeat, sleep timer
- Google Drive OAuth + audio file listing
- Provider architecture ready for Dropbox/OneDrive/Box/pCloud/HiDrive/Mediafire/WebDAV integrations

## Run

```bash
flutter pub get
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your_web_client_id \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your_server_client_id
```

## Production checklist

See: `docs/production-readiness.md`
