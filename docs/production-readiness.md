# CloudParty Production Readiness

This document lists the minimum steps to deploy CloudParty safely.

## 1) Google Drive OAuth (Implemented in app)

CloudParty now includes real Google Drive OAuth + file listing.

Required setup:

1. Create OAuth client(s) in Google Cloud Console.
2. Enable **Google Drive API**.
3. Configure consent screen and publish app (External).
4. For iOS add reversed client id to URL schemes.
5. For Android make sure SHA-1/SHA-256 are registered.
6. Run app with defines:

```bash
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your_web_client_id \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your_server_client_id
```

## 2) Security

- Connection metadata is stored in `flutter_secure_storage`.
- Do not persist long-lived secrets in plain SharedPreferences.
- Use TLS only endpoints for all media links.
- Rotate OAuth credentials regularly.

## 3) Sync behavior

- Manual sync: available per connection.
- Automatic sync: runs every 5 minutes while app is active.
- Recommendation for scale: add backend webhook/push sync for Drive/Dropbox/OneDrive.

## 4) Cloud providers status

- Google Drive: OAuth + listing wired.
- Dropbox / OneDrive / Box / pCloud / HiDrive / Mediafire / WebDAV: placeholder adapters exist and are ready to be upgraded with real OAuth/API implementations.

## 5) Release checklist

- `flutter analyze` passes.
- `flutter test` passes.
- Validate background behavior on real devices.
- Verify OAuth login/logout flow on Android + iOS.
- Verify offline playback for downloaded files.
- Add crash reporting and analytics before store release.
- Prepare privacy policy and data disclosure for store forms.
