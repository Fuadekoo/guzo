import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The best result a player has recorded for one sequence.
@immutable
class BestResult {
  const BestResult({required this.seconds, required this.coins});

  final double seconds;
  final int coins;

  @override
  bool operator ==(Object other) =>
      other is BestResult && other.seconds == seconds && other.coins == coins;

  @override
  int get hashCode => Object.hash(seconds, coins);
}

/// Local settings and records.
///
/// Entirely on-device, as the brief requires — no account, no network, nothing
/// to sync. Like [AudioService] it is safe before and without [init]: if the
/// platform store is unavailable the values live in memory for the session
/// instead of throwing.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _soundKey = 'sound_enabled';
  static const String _musicKey = 'music_enabled';
  static const String _bestTimePrefix = 'best_time_';
  static const String _bestCoinsPrefix = 'best_coins_';

  SharedPreferences? _prefs;

  /// In-memory mirror. It is the source of truth for reads, which keeps every
  /// getter synchronous and makes the whole class usable in a widget build.
  final Map<String, Object> _values = <String, Object>{
    _soundKey: true,
    _musicKey: true,
  };

  bool get isPersistent => _prefs != null;

  Future<void> init() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _prefs = prefs;

      for (final String key in prefs.getKeys()) {
        final Object? value = prefs.get(key);
        if (value != null) _values[key] = value;
      }
    } catch (error) {
      // A missing plugin (tests, an unsupported platform) is not fatal —
      // settings just do not survive a restart.
      _prefs = null;
      debugPrint('GUZO storage unavailable, using session defaults: $error');
    }
  }

  // --- Settings -----------------------------------------------------------

  bool get soundEnabled => _values[_soundKey] as bool? ?? true;
  bool get musicEnabled => _values[_musicKey] as bool? ?? true;

  Future<void> setSoundEnabled(bool value) => _setBool(_soundKey, value);
  Future<void> setMusicEnabled(bool value) => _setBool(_musicKey, value);

  // --- Records ------------------------------------------------------------

  /// The best run for [sequenceId], or null if it has never been finished.
  BestResult? bestFor(String sequenceId) {
    final double? seconds = _values['$_bestTimePrefix$sequenceId'] as double?;
    if (seconds == null) return null;

    return BestResult(
      seconds: seconds,
      coins: _values['$_bestCoinsPrefix$sequenceId'] as int? ?? 0,
    );
  }

  /// Records a finished run, keeping it only if it beats the stored time.
  ///
  /// Returns true when this run set a new record, so the result screen can say
  /// so.
  Future<bool> recordResult({
    required String sequenceId,
    required double seconds,
    required int coins,
  }) async {
    final BestResult? previous = bestFor(sequenceId);
    if (previous != null && previous.seconds <= seconds) return false;

    await _setDouble('$_bestTimePrefix$sequenceId', seconds);
    await _setInt('$_bestCoinsPrefix$sequenceId', coins);
    return true;
  }

  // --- Plumbing -----------------------------------------------------------

  Future<void> _setBool(String key, bool value) async {
    _values[key] = value;
    await _guard(() => _prefs?.setBool(key, value));
  }

  Future<void> _setInt(String key, int value) async {
    _values[key] = value;
    await _guard(() => _prefs?.setInt(key, value));
  }

  Future<void> _setDouble(String key, double value) async {
    _values[key] = value;
    await _guard(() => _prefs?.setDouble(key, value));
  }

  Future<void> _guard(Future<bool?>? Function() write) async {
    try {
      await write();
    } catch (error) {
      debugPrint('GUZO could not persist a setting: $error');
    }
  }

  /// Clears everything. Used by tests and by a future "reset progress" action.
  @visibleForTesting
  Future<void> clear() async {
    _values
      ..clear()
      ..[_soundKey] = true
      ..[_musicKey] = true;
    await _guard(() => _prefs?.clear());
  }
}
