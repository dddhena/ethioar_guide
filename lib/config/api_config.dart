/// Centralized API and Payment Gateway Configuration.
/// All sensitive keys are configured at runtime via the In-App Settings UI
/// or passed via compile-time environment flags (--dart-define),
/// keeping the repository 100% free of hardcoded secrets for safe GitHub commits.
class ApiConfig {
  // ===========================================================================
  // 1. GEMINI AI CONFIGURATION
  // ===========================================================================
  static String? _customGeminiKey;
  static set customApiKey(String? key) => _customGeminiKey = key;

  static String? _selectedGeminiModel;
  static String get selectedGeminiModel => _selectedGeminiModel ?? 'gemini-3.6-flash';
  static set selectedGeminiModel(String? model) => _selectedGeminiModel = model;

  static String get geminiApiKey {
    if (_customGeminiKey != null && _customGeminiKey!.trim().isNotEmpty) {
      return _customGeminiKey!.trim();
    }
    const envKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );
    return envKey;
  }

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY';

  // ===========================================================================
  // 2. SAFARICOM ETHIOPIA M-PESA CONFIGURATION (developer.safaricom.et)
  // ===========================================================================
  static const String safaricomEtPortalUrl = 'https://developer.safaricom.et/apps';
  static const String safaricomEtSandboxBaseUrl = 'https://apisandbox.safaricom.et';
  static const String safaricomEtLiveBaseUrl = 'https://api.safaricom.et';

  static String? _darajaConsumerKey;
  static String? _darajaConsumerSecret;
  static String? _darajaPasskey;
  static String? _darajaShortCode;
  static bool _darajaSandbox = true;
  static String? _darajaCallbackUrl;

  static String get safaricomPortalUrl => safaricomEtPortalUrl;

  static String get safaricomBaseUrl =>
      _darajaSandbox ? safaricomEtSandboxBaseUrl : safaricomEtLiveBaseUrl;

  static String get darajaConsumerKey {
    if (_darajaConsumerKey != null && _darajaConsumerKey!.trim().isNotEmpty) {
      return _darajaConsumerKey!.trim();
    }
    const etKey = String.fromEnvironment('SAFARICOM_CONSUMER_KEY', defaultValue: '');
    if (etKey.isNotEmpty) return etKey;
    return const String.fromEnvironment('DARAJA_CONSUMER_KEY', defaultValue: '');
  }

  static String get darajaConsumerSecret {
    if (_darajaConsumerSecret != null && _darajaConsumerSecret!.trim().isNotEmpty) {
      return _darajaConsumerSecret!.trim();
    }
    const etSecret = String.fromEnvironment('SAFARICOM_CONSUMER_SECRET', defaultValue: '');
    if (etSecret.isNotEmpty) return etSecret;
    return const String.fromEnvironment('DARAJA_CONSUMER_SECRET', defaultValue: '');
  }

  static String get darajaPasskey {
    if (_darajaPasskey != null && _darajaPasskey!.trim().isNotEmpty) {
      return _darajaPasskey!.trim();
    }
    const etPasskey = String.fromEnvironment('SAFARICOM_PASSKEY', defaultValue: '');
    if (etPasskey.isNotEmpty) return etPasskey;
    return const String.fromEnvironment('DARAJA_PASSKEY', defaultValue: '');
  }

  static String get darajaShortCode {
    if (_darajaShortCode != null && _darajaShortCode!.trim().isNotEmpty) {
      return _darajaShortCode!.trim();
    }
    const etCode = String.fromEnvironment('SAFARICOM_SHORTCODE', defaultValue: '');
    if (etCode.isNotEmpty) return etCode;
    return const String.fromEnvironment('DARAJA_SHORTCODE', defaultValue: '174379');
  }

  static bool get isDarajaSandbox => _darajaSandbox;

  static String get darajaCallbackUrl =>
      _darajaCallbackUrl?.trim().isNotEmpty == true
          ? _darajaCallbackUrl!.trim()
          : 'https://ethioar-guide.firebaseapp.com/api/daraja/callback';

  static bool get hasDarajaKeys =>
      darajaConsumerKey.isNotEmpty && darajaConsumerSecret.isNotEmpty;

  static void setDarajaConfig({
    String? consumerKey,
    String? consumerSecret,
    String? passkey,
    String? shortCode,
    bool isSandbox = true,
    String? callbackUrl,
  }) {
    if (consumerKey != null) _darajaConsumerKey = consumerKey;
    if (consumerSecret != null) _darajaConsumerSecret = consumerSecret;
    if (passkey != null) _darajaPasskey = passkey;
    if (shortCode != null) _darajaShortCode = shortCode;
    _darajaSandbox = isSandbox;
    if (callbackUrl != null) _darajaCallbackUrl = callbackUrl;
  }

  static void clearDarajaConfig() {
    _darajaConsumerKey = null;
    _darajaConsumerSecret = null;
    _darajaPasskey = null;
    _darajaShortCode = null;
    _darajaSandbox = true;
    _darajaCallbackUrl = null;
  }

  // ===========================================================================
  // 3. TELEBIRR DEVELOPER GATEWAY CONFIGURATION
  // ===========================================================================
  static String? _telebirrAppId;
  static String? _telebirrAppKey;
  static String? _telebirrPublicKey;
  static String? _telebirrShortCode;
  static bool _telebirrSandbox = true;

  static String get telebirrAppId =>
      _telebirrAppId?.trim() ??
      const String.fromEnvironment('TELEBIRR_APP_ID', defaultValue: '');

  static String get telebirrAppKey =>
      _telebirrAppKey?.trim() ??
      const String.fromEnvironment('TELEBIRR_APP_KEY', defaultValue: '');

  static String get telebirrPublicKey =>
      _telebirrPublicKey?.trim() ??
      const String.fromEnvironment('TELEBIRR_PUBLIC_KEY', defaultValue: '');

  static String get telebirrShortCode =>
      (_telebirrShortCode != null && _telebirrShortCode!.trim().isNotEmpty)
          ? _telebirrShortCode!.trim()
          : const String.fromEnvironment('TELEBIRR_SHORTCODE', defaultValue: '10011');

  static bool get isTelebirrSandbox => _telebirrSandbox;

  static bool get hasTelebirrKeys =>
      telebirrAppId.isNotEmpty && telebirrAppKey.isNotEmpty;

  static void setTelebirrConfig({
    String? appId,
    String? appKey,
    String? publicKey,
    String? shortCode,
    bool isSandbox = true,
  }) {
    if (appId != null) _telebirrAppId = appId;
    if (appKey != null) _telebirrAppKey = appKey;
    if (publicKey != null) _telebirrPublicKey = publicKey;
    if (shortCode != null) _telebirrShortCode = shortCode;
    _telebirrSandbox = isSandbox;
  }

  static void clearTelebirrConfig() {
    _telebirrAppId = null;
    _telebirrAppKey = null;
    _telebirrPublicKey = null;
    _telebirrShortCode = null;
    _telebirrSandbox = true;
  }

  // ===========================================================================
  // 4. OPENSTREETMAP & MAPPING CONFIGURATION
  // ===========================================================================
  static String? _osmTileUrl;
  static String? _osmApiKey;
  static String? _osrmRoutingUrl;
  static String? _osmUserAgent;

  static String get osmTileUrl {
    if (_osmTileUrl != null && _osmTileUrl!.trim().isNotEmpty) {
      return _osmTileUrl!.trim();
    }
    return const String.fromEnvironment(
      'OSM_TILE_URL',
      defaultValue: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    );
  }

  /// Resolved tile URL (automatically injecting apiKey if {apiKey} placeholder is present)
  static String get resolvedTileUrl {
    var url = osmTileUrl;
    final key = osmApiKey;
    if (key.isNotEmpty) {
      if (url.contains('{apiKey}')) {
        url = url.replaceAll('{apiKey}', key);
      } else if (url.contains('{key}')) {
        url = url.replaceAll('{key}', key);
      } else if (url.contains('api_key=')) {
        // already has param
      } else {
        url = url.contains('?') ? '$url&api_key=$key' : '$url?api_key=$key';
      }
    }
    return url;
  }

  static String get osmApiKey {
    if (_osmApiKey != null && _osmApiKey!.trim().isNotEmpty) {
      return _osmApiKey!.trim();
    }
    return const String.fromEnvironment('OSM_API_KEY', defaultValue: '');
  }

  static String get osrmRoutingUrl {
    if (_osrmRoutingUrl != null && _osrmRoutingUrl!.trim().isNotEmpty) {
      var url = _osrmRoutingUrl!.trim();
      if (url.endsWith('/')) url = url.substring(0, url.length - 1);
      return url;
    }
    return const String.fromEnvironment(
      'OSRM_ROUTING_URL',
      defaultValue: 'https://router.project-osrm.org',
    );
  }

  static String get osmUserAgent {
    if (_osmUserAgent != null && _osmUserAgent!.trim().isNotEmpty) {
      return _osmUserAgent!.trim();
    }
    return const String.fromEnvironment(
      'OSM_USER_AGENT',
      defaultValue: 'com.example.ethioar_guide',
    );
  }

  static void setOsmConfig({
    String? tileUrl,
    String? apiKey,
    String? routingUrl,
    String? userAgent,
  }) {
    if (tileUrl != null) _osmTileUrl = tileUrl;
    if (apiKey != null) _osmApiKey = apiKey;
    if (routingUrl != null) _osrmRoutingUrl = routingUrl;
    if (userAgent != null) _osmUserAgent = userAgent;
  }

  static void clearOsmConfig() {
    _osmTileUrl = null;
    _osmApiKey = null;
    _osrmRoutingUrl = null;
    _osmUserAgent = null;
  }

  // ===========================================================================
  // 5. PRESET LOADER FOR FREE SANDBOX / TEST ENVIRONMENTS
  // ===========================================================================
  /// Pre-loads standard sandbox development presets so developers & tourists can test right away
  static void loadSandboxPresets() {
    // Daraja M-Pesa standard developer sandbox shortcode & test passkey
    _darajaShortCode = '174379';
    _darajaPasskey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
    _darajaSandbox = true;

    // Telebirr test developer sandbox preset
    _telebirrShortCode = '10011';
    _telebirrSandbox = true;

    // OpenStreetMap default preset
    _osmTileUrl = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    _osrmRoutingUrl = 'https://router.project-osrm.org';
    _osmUserAgent = 'com.example.ethioar_guide';
  }
}
