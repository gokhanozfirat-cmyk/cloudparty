import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import '../secure_connection_store.dart';
import 'cloud_provider_adapter.dart';

/// Key used to persist pending OAuth state across process restarts.
const String _kPendingOAuth = 'cloudparty.pending_oauth';

/// Base class for OAuth 2.0 / PKCE cloud providers.
///
/// Opens the auth URL in the EXTERNAL browser (not Custom Tab) so the flow
/// completes even if MIUI kills the Flutter process while the browser is open.
/// Pending auth state is saved to SharedPreferences; AppState.initialize()
/// calls [completePendingIfNeeded] to finish the exchange after a restart.
abstract class OAuthProviderAdapter extends CloudProviderAdapter {
  OAuthProviderAdapter({
    SecureConnectionStore? secureStore,
    Dio? dio,
  })  : _secureStore = secureStore ?? SecureConnectionStore(),
        _dio = dio ?? Dio();

  final SecureConnectionStore _secureStore;
  final Dio _dio;

  static const String _redirectUrl = 'com.cloudparty.app://oauth/callback';

  String get clientId;
  String? get clientSecret => null;
  String get authorizationEndpoint;
  String get tokenEndpoint;
  List<String> get scopes;
  String get redirectUrl => _redirectUrl;
  Map<String, String> get extraAuthParams => const <String, String>{};

  @override
  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
    Map<String, String> extraData = const {},
  }) async {
    if (clientId.isEmpty) {
      throw CloudSyncException(
        '${platform.label} bağlantısı için istemci kimliği yapılandırılmamış.',
      );
    }

    final String codeVerifier = _generateCodeVerifier();
    final String codeChallenge = _generateCodeChallenge(codeVerifier);
    final String state = _generateState();

    final Uri authUri = Uri.parse(authorizationEndpoint).replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'scope': scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        ...extraAuthParams,
      },
    );

    // Persist pending state so AppState can complete the flow after restart
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPendingOAuth,
      jsonEncode(<String, String>{
        'connectionId': connectionId,
        'codeVerifier': codeVerifier,
        'state': state,
        'platform': platform.name,
        'fallbackDisplayName': fallbackDisplayName,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );

    // Open in external browser (full Chrome, not Custom Tab)
    // so the browser runs in a completely separate process from our app.
    final bool launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await prefs.remove(_kPendingOAuth);
      throw CloudSyncException('Tarayıcı açılamadı.');
    }

    // Happy-path: process was NOT killed — wait for the deep link callback.
    // If the process IS killed by MIUI, this future is abandoned and
    // AppState.initialize() picks up the flow via completePendingIfNeeded().
    final AppLinks appLinks = AppLinks();
    try {
      final Uri callbackUri = await appLinks.uriLinkStream
          .where((Uri uri) => uri.scheme == 'com.cloudparty.app')
          .timeout(const Duration(minutes: 5))
          .first;

      await prefs.remove(_kPendingOAuth);
      return await _exchangeCode(
        code: callbackUri.queryParameters['code'] ?? '',
        codeVerifier: codeVerifier,
        connectionId: connectionId,
        fallbackDisplayName: fallbackDisplayName,
      );
    } on TimeoutException {
      await prefs.remove(_kPendingOAuth);
      throw CloudSyncException('Giriş zaman aşımına uğradı. Lütfen tekrar dene.');
    }
  }

  /// Called by AppState.initialize() to complete an OAuth exchange that was
  /// interrupted by a process kill.  Returns null if no pending state exists
  /// or if the initialLink doesn't match our callback scheme.
  Future<CloudConnection?> completePendingIfNeeded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? pendingJson = prefs.getString(_kPendingOAuth);
    if (pendingJson == null) return null;

    // Only the adapter whose platform matches the saved platform should run.
    final Map<String, dynamic> pending =
        jsonDecode(pendingJson) as Map<String, dynamic>;
    if ((pending['platform'] as String?) != platform.name) return null;

    // Check if this was saved recently enough (10 min window)
    final String? savedAtStr = pending['savedAt'] as String?;
    if (savedAtStr != null) {
      final DateTime savedAt = DateTime.tryParse(savedAtStr) ?? DateTime(0);
      if (DateTime.now().difference(savedAt).inMinutes > 10) {
        await prefs.remove(_kPendingOAuth);
        return null;
      }
    }

    // Get the callback URL that Android delivered to MainActivity
    final AppLinks appLinks = AppLinks();
    final Uri? initialLink = await appLinks.getInitialLink();
    if (initialLink == null || initialLink.scheme != 'com.cloudparty.app') {
      return null; // Not a callback — leave pending state for later
    }

    final String? code = initialLink.queryParameters['code'];
    if (code == null || code.isEmpty) {
      await prefs.remove(_kPendingOAuth);
      return null;
    }

    await prefs.remove(_kPendingOAuth);
    return _exchangeCode(
      code: code,
      codeVerifier: (pending['codeVerifier'] as String?) ?? '',
      connectionId: (pending['connectionId'] as String?) ?? '',
      fallbackDisplayName:
          (pending['fallbackDisplayName'] as String?) ?? platform.label,
    );
  }

  // ── Token exchange ────────────────────────────────────────────────────────

  Future<CloudConnection> _exchangeCode({
    required String code,
    required String codeVerifier,
    required String connectionId,
    required String fallbackDisplayName,
  }) async {
    if (code.isEmpty) {
      throw CloudSyncException('${platform.label} yetkilendirme kodu alınamadı.');
    }

    final Map<String, dynamic> tokenData;
    try {
      final Map<String, String> body = <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUrl,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      };
      if (clientSecret != null) body['client_secret'] = clientSecret!;

      final Response<dynamic> resp = await _dio.post<dynamic>(
        tokenEndpoint,
        data: body,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      tokenData = resp.data is Map
          ? Map<String, dynamic>.from(resp.data as Map)
          : jsonDecode(resp.data.toString()) as Map<String, dynamic>;
    } catch (e) {
      throw CloudSyncException(
        '${platform.label} token alınamadı.',
        debugDetails: e.toString(),
      );
    }

    final String? accessToken = tokenData['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw CloudSyncException('${platform.label} token alınamadı.');
    }

    final String? refreshToken = tokenData['refresh_token'] as String?;
    final int? expiresIn = tokenData['expires_in'] as int?;
    final DateTime? expiry = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    await _storeTokens(
      connectionId: connectionId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );

    final String displayName =
        await fetchDisplayName(accessToken) ?? fallbackDisplayName;

    return CloudConnection(
      id: connectionId,
      platform: platform,
      displayName: displayName,
      connectedAt: DateTime.now(),
    );
  }

  /// Override to fetch the account display name from the provider API.
  Future<String?> fetchDisplayName(String accessToken) async => null;

  @override
  Future<Map<String, String>?> getFreshHeaders(
      CloudConnection connection) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) return null;
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  @override
  Future<void> disconnect(CloudConnection connection) async {
    await _secureStore.delete(connection.id);
  }

  Future<String?> getValidAccessToken(String connectionId) async {
    final Map<String, dynamic>? data = await _secureStore.read(connectionId);
    if (data == null) return null;

    final String accessToken = (data['accessToken'] as String?) ?? '';
    final String? refreshToken = data['refreshToken'] as String?;
    final String? expiryStr = data['accessTokenExpiry'] as String?;

    if (accessToken.isEmpty) return null;

    if (expiryStr != null && expiryStr.isNotEmpty) {
      try {
        final DateTime expiry = DateTime.parse(expiryStr);
        if (DateTime.now()
            .isBefore(expiry.subtract(const Duration(minutes: 5)))) {
          return accessToken;
        }
      } catch (_) {}
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final Map<String, String> body = <String, String>{
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        };
        if (clientSecret != null) body['client_secret'] = clientSecret!;

        final Response<dynamic> resp = await _dio.post<dynamic>(
          tokenEndpoint,
          data: body,
          options: Options(contentType: 'application/x-www-form-urlencoded'),
        );
        final Map<String, dynamic> tokenData = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : jsonDecode(resp.data.toString()) as Map<String, dynamic>;

        final String? newToken = tokenData['access_token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          final String? newRefresh = tokenData['refresh_token'] as String?;
          final int? expiresIn = tokenData['expires_in'] as int?;
          await _storeTokens(
            connectionId: connectionId,
            accessToken: newToken,
            refreshToken: newRefresh ?? refreshToken,
            expiry: expiresIn != null
                ? DateTime.now().add(Duration(seconds: expiresIn))
                : null,
          );
          return newToken;
        }
      } catch (_) {}
    }

    return accessToken;
  }

  Future<void> _storeTokens({
    required String connectionId,
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    await _secureStore.write(connectionId, <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken ?? '',
      'accessTokenExpiry': expiry?.toIso8601String() ?? '',
    });
  }

  // ── PKCE ─────────────────────────────────────────────────────────────────

  String _generateCodeVerifier() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final Random rng = Random.secure();
    return List<String>.generate(
        128, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final Digest digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _generateState() {
    final Random rng = Random.secure();
    return base64Url
        .encode(List<int>.generate(16, (_) => rng.nextInt(256)))
        .replaceAll('=', '');
  }
}
