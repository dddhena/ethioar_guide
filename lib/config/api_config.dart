/// API keys — pass at build time: --dart-define=GEMINI_API_KEY=your_key
/// or set dynamically at runtime.
abstract class ApiConfig {
  static String? _customApiKey;
  static set customApiKey(String? key) => _customApiKey = key;

  static String get geminiApiKey {
    if (_customApiKey != null && _customApiKey!.trim().isNotEmpty) {
      return _customApiKey!.trim();
    }
    const envKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );
    return envKey;
  }

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'YOUR_GEMINI_API_KEY';
}
