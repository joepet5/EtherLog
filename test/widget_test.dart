// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:etherlog/main.dart';

import 'package:etherlog/l10n/achievement_localizations.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EtherlogApp());
    expect(find.byType(EtherlogApp), findsOneWidget);
  });

  test('AchievementLocalizations covers all 15 sections across all 9 non-English languages', () {
    final sampleIndices = [0, 50, 88, 124, 165, 218, 255, 325, 385, 425, 460, 472, 483, 571, 591];
    final languages = ['es', 'fr', 'de', 'pt', 'zh', 'ar', 'ko', 'ja', 'id'];

    for (final idx in sampleIndices) {
      final id = 'ach_$idx';
      for (final lang in languages) {
        final title = AchievementLocalizations.getTitle(id, 'Fallback', lang);
        final desc = AchievementLocalizations.getDescription(id, 'Fallback', lang);
        
        expect(title, isNotEmpty);
        expect(title, isNot(equals('Fallback')));
        expect(desc, isNotEmpty);
        expect(desc, isNot(equals('Fallback')));
      }
    }
  });

  test('Scan for untranslated descriptions', () {
    const sampleIds = [
      'ach_82', 'ach_100', 'ach_150', 'ach_200', 'ach_250',
      'ach_300', 'ach_350', 'ach_400', 'ach_450', 'ach_500',
      'ach_550', 'ach_600', 'ach_650', 'ach_700'
    ];
    final languages = ['es', 'fr', 'de', 'pt', 'zh', 'ar', 'ko', 'ja', 'id'];

    for (final id in sampleIds) {
      for (final lang in languages) {
        final desc = AchievementLocalizations.getDescription(id, 'Fallback', lang);
        print('[$lang][$id]: $desc');
      }
    }
  });
}
