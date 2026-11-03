import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  final original = Intl.defaultLocale;
  tearDown(() => Intl.defaultLocale = original);
  const delegate = TimetableLocalizationsDelegate();
  const week = Week(2024, 9);
  testWidgets('locale changes update timetable labels and Material tooltips', (
    tester,
  ) async {
    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh', 'CN')],
      localizationsDelegates: const [
        TimetableLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(
        body: Column(
          children: [
            MonthIndicator(DateTime.utc(2024, 2)),
            DateHeader(DateTime.utc(2024, 2, 26)),
            BackButton(onPressed: () {}),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('February'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.longPress(find.byType(DateHeader));
    await tester.pumpAndSettle();
    expect(find.text('Monday, February 26, 2024'), findsOneWidget);
    await tester.pumpWidget(app(const Locale('zh', 'CN')));
    await tester.pumpAndSettle();
    expect(find.text('February'), findsNothing);
    expect(find.text('Monday, February 26, 2024'), findsNothing);
    expect(find.text('二月'), findsOneWidget);
    expect(find.text('周一'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);
    await tester.longPress(find.byType(DateHeader));
    await tester.pumpAndSettle();
    expect(find.text('2024年2月26日星期一'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (locale, labels, description) in <(Locale, List<String>, String)>[
    (
      const Locale('de'),
      ['Kalenderwoche 9, 2024', 'Woche 9', 'KW 9', '9'],
      'Kalenderwoche 9, 2024',
    ),
    (
      const Locale('en'),
      ['Week 9, 2024', 'Week 9', 'W 9', '9'],
      'Week 9, 2024',
    ),
    (
      const Locale('es'),
      ['Semana 9, 2024', 'Semana 9', 'S 9', '9'],
      'Semana 9, 2024',
    ),
    (
      const Locale('fr'),
      ['Semaine 9, 2024', 'Semaine 9', 'S 9', '9'],
      'Semaine 9, 2024',
    ),
    (const Locale('hu'), ['9. hét, 2024', '9. hét', '9'], '9. hét, 2024'),
    (
      const Locale('it'),
      ['Settimana 9, 2024', 'Settimana 9', 'S 9', '9'],
      'Settimana 9, 2024',
    ),
    (const Locale('ja'), ['Week 9, 2024', '第9週', '9週', '9'], 'Week 9, 2024'),
    (
      const Locale('pt'),
      ['Semana 9, 2024', 'Semana 9', 'S 9', '9'],
      'Semana 9, 2024',
    ),
    (
      const Locale('zh', 'CN'),
      ['Week 9, 2024', '第9周', '9周', '9'],
      'Week 9, 2024',
    ),
    (
      const Locale('zh', 'TW'),
      ['Week 9, 2024', '第9週', '9週', '9'],
      'Week 9, 2024',
    ),
  ]) {
    test('$locale returns the complete ordered week labels', () async {
      expect(delegate.isSupported(locale), isTrue);
      final strings = await delegate.load(locale);
      expect(strings.weekLabels(week), labels);
      expect(strings.weekOfYear(week), description);
      expect(strings.allDayOverflow(3), '+3');
      expect(Intl.defaultLocale, locale.toLanguageTag());
    });
  }
  test('fallback and Intl ownership are explicit', () async {
    const fallback = TimetableLocalizationsDelegate(
      setIntlLocale: false,
      fallbackLocale: Locale('en'),
    );
    Intl.defaultLocale = 'fr';
    expect(delegate.isSupported(const Locale('xx')), isFalse);
    expect(fallback.isSupported(const Locale('xx')), isTrue);
    expect(
      (await fallback.load(const Locale('xx'))).weekOfYear(week),
      'Week 9, 2024',
    );
    expect(Intl.defaultLocale, 'fr');
    expect(delegate.shouldReload(fallback), isFalse);
    expect(
      () =>
          const TimetableLocalizationsDelegate(fallbackLocale: Locale('xx'))
              .isSupported(const Locale('en')),
      throwsAssertionError,
    );
  });
  testWidgets('missing delegate reports its owning configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) =>
              Text(TimetableLocalizations.of(context).weekOfYear(week)),
        ),
      ),
    );
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (error) => error.toString(),
        'message',
        contains('TimetableLocalization'),
      ),
    );
  });
}
