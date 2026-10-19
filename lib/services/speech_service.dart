import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Envuelve el reconocimiento de voz nativo del teléfono
/// (SFSpeechRecognizer en iOS, SpeechRecognizer en Android).
class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _permissionDenied = false;
  String? _localeId;
  final bool _useOnDevice = true;
  bool _retriedOffline = false;

  ValueNotifier<double> soundLevel = ValueNotifier<double>(0);

  void Function(String words, bool isFinal)? _onWords;
  void Function(String message)? _onError;

  bool get isListening => _speech.isListening;

  bool get permissionDenied => _permissionDenied;

  String? get localeId => _localeId;

  /// Inicializa el motor y pide permisos (micrófono + reconocimiento).
  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: _handleError,
        debugLogging: false,
      );
    } catch (_) {
      _initialized = false;
    }
    if (!_initialized) {
      _permissionDenied = true;
      return false;
    }
    await _pickSpanishLocale();
    return true;
  }

  Future<void> _pickSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return;
      const preferred = <String>[
        'es_MX', 'es_ES', 'es_US', 'es_AR', 'es_CO', 'es_CL', 'es_PE', 'es_419',
      ];
      for (final want in preferred) {
        for (final locale in locales) {
          final id = locale.localeId.replaceAll('-', '_').toLowerCase();
          if (id == want.toLowerCase()) {
            _localeId = locale.localeId;
            return;
          }
        }
      }
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('es')) {
          _localeId = locale.localeId;
          return;
        }
      }
    } catch (_) {
      // Sin locale específico usamos el predeterminado del sistema.
    }
  }

  Future<bool> start({
    required void Function(String words, bool isFinal) onWords,
    required void Function(String message) onError,
  }) async {
    final ready = await ensureInitialized();
    if (!ready) {
      onError('Necesito permiso para usar el micrófono.');
      return false;
    }
    _onWords = onWords;
    _onError = onError;
    _retriedOffline = false;
    return _listen(useOnDevice: _useOnDevice);
  }

  Future<bool> _listen({required bool useOnDevice}) async {
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _onWords?.call(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: (double level) {
          soundLevel.value = level;
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          onDevice: useOnDevice,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          localeId: _localeId,
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      return true;
    } catch (_) {
      _onError?.call('No pude iniciar el micrófono.');
      return false;
    }
  }

  void _handleError(SpeechRecognitionError error) {
    final message = error.errorMsg;
    final denied = message.contains('permission');
    if (denied) {
      _permissionDenied = true;
      _onError?.call('Necesito permiso para usar el micrófono.');
      return;
    }
    // Si el reconocimiento sin red no está disponible, reintentamos una vez.
    if (_useOnDevice && !_retriedOffline && error.permanent) {
      _retriedOffline = true;
      _listen(useOnDevice: false);
      return;
    }
    _onError?.call('No entendí bien, intenta de nuevo.');
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await cancel();
    soundLevel.dispose();
  }
}
