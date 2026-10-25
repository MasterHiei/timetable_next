// Changes from upstream: replaced diagnostic-plugin controls with standard theme and locale menus.
import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timetable_next/timetable_next.dart';

const _supportedLocales = [
  Locale('de'),
  Locale('en'),
  Locale('es'),
  Locale('fr'),
  Locale('hu'),
  Locale('it'),
  Locale('ja'),
  Locale('pt'),
  Locale('zh', 'CN'),
  Locale('zh', 'TW'),
];

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, required this.child});
  final Widget child;
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Timetable Next example',
    theme: _createTheme(Brightness.light),
    darkTheme: _createTheme(Brightness.dark),
    themeMode: _themeMode,
    locale: _locale,
    localizationsDelegates: const [
      TimetableLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: _supportedLocales,
    home: SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<ThemeMode>(
                  tooltip: 'Theme',
                  icon: const Icon(Icons.brightness_6),
                  onSelected: (value) => setState(() => _themeMode = value),
                  itemBuilder: (_) => [
                    for (final mode in ThemeMode.values)
                      PopupMenuItem(value: mode, child: Text(mode.name)),
                  ],
                ),
                PopupMenuButton<Locale>(
                  tooltip: 'Language',
                  icon: const Icon(Icons.language),
                  onSelected: (value) => setState(() => _locale = value),
                  itemBuilder: (_) => [
                    for (final locale in _supportedLocales)
                      PopupMenuItem(
                        value: locale,
                        child: Text(locale.toLanguageTag()),
                      ),
                  ],
                ),
              ],
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    ),
  );

  ThemeData _createTheme(Brightness brightness) {
    var theme = ThemeData(
      brightness: brightness,
      applyElevationOverlayColor: true,
      primaryColor: Colors.blue,
      primarySwatch: Colors.blue,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
    theme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        onSurface: theme.colorScheme.surface.contrastColor,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: theme.textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.normal,
        ),
      ),
    );

    // We want to extend Timetable behind the navigation bar.
    SystemChrome.setSystemUIOverlayStyle(
      brightness.contrastSystemUiOverlayStyle.copyWith(
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    return theme;
  }
}
