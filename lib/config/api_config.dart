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
  // 2. SAFARICOM DARAJA (M-PESA) CONFIGURATION
  // ===========================================================================
  static String? _darajaConsumerKey;
  static String? _darajaConsumerSecret;
  static String? _darajaPasskey;
  static String? _darajaShortCode;
  static bool _darajaSandbox = true;
  static String? _darajaCallbackUrl;

  static String get darajaConsumerKey =>
      _darajaConsumerKey?.trim() ??
      const String.fromEnvironment('DARAJA_CONSUMER_KEY', defaultValue: '');

  static String get darajaConsumerSecret =>
      _darajaConsumerSecret?.trim() ??
      const String.fromEnvironment('DARAJA_CONSUMER_SECRET', defaultValue: '');

  static String get darajaPasskey =>
      _darajaPasskey?.trim() ??
      const String.fromEnvironment('DARAJA_PASSKEY', defaultValue: '');

  static String get darajaShortCode =>
      (_darajaShortCode != null && _darajaShortCode!.trim().isNotEmpty)
          ? _darajaShortCode!.trim()
          : const String.fromEnvironment('DARAJA_SHORTCODE', defaultValue: '174379'); // Daraja Sandbox shortcode

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
  // 4. PRESET LOADER FOR FREE SANDBOX / TEST ENVIRONMENTS
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
  }
}
