enum JourneyMode { unset, guided, ar }

/// Tracks the tourist's chosen exploration mode for the current session.
class JourneyPreferenceService {
  JourneyPreferenceService._();
  static final JourneyPreferenceService instance = JourneyPreferenceService._();

  JourneyMode _mode = JourneyMode.unset;

  JourneyMode get mode => _mode;
  bool get hasChosen => _mode != JourneyMode.unset;

  void setMode(JourneyMode mode) => _mode = mode;

  void clear() => _mode = JourneyMode.unset;
}
