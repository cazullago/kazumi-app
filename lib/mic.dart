import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Live mic level with exponential-moving-average smoothing.
///
/// The mouth opens proportionally to this value and closes smoothly when
/// silent (EMA decay). There is NO random open/close loop: when the mic is
/// off, denied, or silent, the level decays to 0 and the mouth stays closed.
class MicLevel extends ChangeNotifier {
  final ValueNotifier<double> level = ValueNotifier<double>(0);
  final ValueNotifier<String> status = ValueNotifier<String>('Mic idle — tap Test mic to start');

  AudioRecorder? _recorder;
  StreamSubscription<Amplitude>? _sub;
  Timer? _decayTimer;
  double _ema = 0;
  bool _running = false;

  bool get running => _running;

  /// Smoothing factor: higher = snappier, lower = smoother. 0.35 keeps
  /// speech fluid without jitter; silence decays via [stop].
  double _smooth(double normalized) {
    _ema = _ema * 0.65 + normalized * 0.35;
    return _ema.clamp(0.0, 1.0);
  }

  Future<void> start() async {
    if (_running) return;
    _decayTimer?.cancel();
    try {
      final perm = await Permission.microphone.request();
      if (!perm.isGranted) {
        status.value = 'Mic permission needed — allow microphone to test your level.';
        return;
      }
      _recorder ??= AudioRecorder();
      final hasPerm = await _recorder!.hasPermission();
      if (!hasPerm) {
        status.value = 'Mic permission needed — allow microphone to test your level.';
        return;
      }
      await _recorder!.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: '',
      );
      _running = true;
      status.value = 'Listening… speak and watch the level move.';
      _sub = _recorder!.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
        // Amplitude.current is dBFS (negative). Speech typically sits
        // between -50 and -10 dBFS; map that range smoothly to 0..1.
        final normalized = ((amp.current + 55) / 45).clamp(0.0, 1.0);
        level.value = _smooth(normalized);
      }, onError: (_) {
        status.value = 'Mic level unavailable on this device — mouth stays closed.';
      });
    } catch (_) {
      status.value = 'Mic level unavailable on this device — mouth stays closed.';
      _running = false;
    }
    notifyListeners();
  }

  /// Stops listening and decays the level smoothly to zero instead of
  /// snapping the mouth shut.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      if (_running) await _recorder?.stop();
    } catch (_) {
      // Ignore stop errors; decay still applies.
    }
    _running = false;
    status.value = 'Mic idle — tap Test mic to start';
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      _ema *= 0.82;
      level.value = _ema;
      if (_ema < 0.02) {
        _ema = 0;
        level.value = 0;
        t.cancel();
      }
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _decayTimer?.cancel();
    _recorder?.dispose();
    level.dispose();
    status.dispose();
    super.dispose();
  }
}
