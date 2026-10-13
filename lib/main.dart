import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/entries_provider.dart';
import 'providers/guards_provider.dart';
import 'providers/roster_provider.dart';
import 'providers/calendar_and_phone_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/root_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoreAxisApp());
}

class CoreAxisApp extends StatelessWidget {
  const CoreAxisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EntriesProvider()),
        ChangeNotifierProvider(create: (_) => GuardsProvider()),
        ChangeNotifierProvider(create: (_) => RosterProvider()),
        ChangeNotifierProvider(create: (_) => PhoneProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'CoreAxis',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            // English only, per the app requirements.
            locale: const Locale('en', 'US'),
            supportedLocales: const [Locale('en', 'US')],
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

/// Loads settings + all provider data once at startup, then routes to
/// Onboarding (first launch) or the main app shell.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  bool _setupDone = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsProvider>();
    await settings.load();
    await Future.wait([
      context.read<EntriesProvider>().load(),
      context.read<GuardsProvider>().load(),
      context.read<PhoneProvider>().load(),
      context.read<CalendarProvider>().load(),
    ]);
    if (!mounted) return;
    setState(() {
      _ready = true;
      _setupDone = settings.settings.setupDone;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return _setupDone ? const RootShell() : const OnboardingScreen();
  }
}
