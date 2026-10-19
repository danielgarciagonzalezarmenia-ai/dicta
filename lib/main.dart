import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/splash_screen.dart';
import 'services/notes_store.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await NotesStore.instance.init();
  await NotificationService.instance.init();
  runApp(const DictaApp());
}

class DictaApp extends StatefulWidget {
  const DictaApp({super.key});

  @override
  State<DictaApp> createState() => _DictaAppState();
}

class _DictaAppState extends State<DictaApp> with WidgetsBindingObserver {
  Brightness _brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      _brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Dicta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(_brightness),
      locale: const Locale('es'),
      supportedLocales: const <Locale>[Locale('es'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
