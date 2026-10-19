import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../services/note_actions.dart';
import '../services/notes_store.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/mic_button.dart';
import '../widgets/note_tile.dart';
import 'compose_screen.dart';
import 'detail_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotesStore _store = NotesStore.instance;
  final SpeechService _speech = SpeechService.instance;

  bool _listening = false;
  String _live = '';
  String? _error;
  String? _banner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _bannerTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _flash(String message) {
    setState(() => _banner = message);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _live = '';
    });
    final started = await _speech.start(
      onWords: (words, isFinal) {
        if (!mounted) return;
        setState(() => _live = words);
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = message;
          _listening = false;
        });
      },
    );
    if (!mounted) return;
    setState(() => _listening = started);
  }

  Future<void> _stop() async {
    await _speech.stop();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _listening = false);
    final text = _live.trim();
    if (text.isEmpty) {
      _flash('No escuché nada');
      return;
    }
    await _review(text);
  }

  Future<void> _review(String text) async {
    await _speech.cancel();
    if (!mounted) return;
    final outcome = await Navigator.of(context).push<SaveOutcome>(
      CupertinoPageRoute<SaveOutcome>(
        builder: (_) => ComposeScreen(transcript: text),
      ),
    );
    if (!mounted) return;
    setState(() => _live = '');
    if (outcome != null) {
      if (outcome.reminderScheduled) {
        _flash('Guardado · te aviso 10 min antes');
      } else if (outcome.calendarCreated) {
        _flash('Guardado en el Calendario');
      } else {
        _flash('Guardado');
      }
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => const HistoryScreen()),
    );
  }

  void _openNote(String id) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => DetailScreen(noteId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Dicta'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _openHistory,
          child: Icon(CupertinoIcons.tray_full, color: p.blue, size: 22),
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(child: _top(p)),
                _recent(p),
              ],
            ),
          ),
          if (_banner != null) _bannerView(p),
        ],
      ),
    );
  }

  Widget _top(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(child: Center(child: _transcriptView(p))),
          MicButton(listening: _listening, onTap: _toggle),
          const SizedBox(height: 12),
          Text(
            _listening ? 'Toca para terminar' : 'Toca para hablar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: p.secondaryLabel,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.red),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _transcriptView(AppPalette p) {
    final hasText = _live.trim().isNotEmpty;
    if (hasText) {
      return SingleChildScrollView(
        reverse: true,
        child: Text(
          _live,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: p.label,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _listening ? 'Escuchando…' : 'Dicta lo que quieras',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: p.label,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tareas, citas, ideas y recordatorios.\nYo los ordeno, guardo y te aviso.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.4, color: p.secondaryLabel),
        ),
      ],
    );
  }

  Widget _recent(AppPalette p) {
    final recent = _store.recent(3);
    if (recent.isEmpty) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Row(
              children: [
                Text(
                  'Recientes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: p.label,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: _openHistory,
                  child: Text(
                    'Ver todo',
                    style: TextStyle(fontSize: 15, color: p.blue),
                  ),
                ),
              ],
            ),
          ),
          SettingsCard(
            children: [
              for (final note in recent)
                NoteTile(
                  note: note,
                  onTap: () => _openNote(note.id),
                  onToggle: () => _store.toggleCompleted(note.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerView(AppPalette p) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _banner!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p.label,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
