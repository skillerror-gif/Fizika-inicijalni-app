import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fizika_adaptivno_vezbanje/presentation/screens/home_screen.dart';

void main() {
  final path = 'assets/content/g3_fizika_3.2.0.json';
  test('cumulative grade III catalog preserves magnetic questions and filters drafts', () {
    final data = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final original = jsonDecode(File('assets/content/g3_magnetno_polje_3.0.0_PASS.json').readAsStringSync()) as Map<String, dynamic>;
    final qs = questionsFromRaw(jsonEncode(data));
    expect(qs.length, 156);
    final map = {for (final q in (data['questions'] as List)) q['id']: q};
    for (final q in original['questions'] as List) {
      expect(map[q['id']], q);
    }
    expect(qs.where((q) => q.subdomainId.startsWith('IND-')).length, 56);
    expect(qs.any((q) => q.subdomainId == 'IND-19' || q.subdomainId == 'IND-20'), isFalse);
    final altered = Map<String, dynamic>.from((data['questions'] as List).last as Map);
    altered['id'] = 'unapproved'; altered['status'] = 'draft'; altered['unlock_order'] = null;
    (data['questions'] as List).add(altered);
    expect(questionsFromRaw(jsonEncode(data)).length, 156);
    data['current_unlock_order'] = 8;
    expect(questionsFromRaw(jsonEncode(data)).length, 100);
  });

  test('chosen induction group and question type stay inside the selection', () {
    final qs = questionsFromRaw(File(path).readAsStringSync());
    for (final id in qs.map((q) => q.subdomainId).toSet()) {
      final pool = qs.where((q) => q.subdomainId == id).toList();
      for (final focus in ['theory', 'calculation']) {
        final out = randomizedPractice(pool, count: min(10, pool.length), focus: focus);
        expect(out.every((q) => q.subdomainId == id && q.nature == focus), isTrue);
        expect(out.map((q) => q.id).toSet().length, out.length);
      }
    }
  });

  testWidgets('induction appears in material selection and expands to named groups', (tester) async {
    final qs = questionsFromRaw(File(path).readAsStringSync());
    await tester.pumpWidget(MaterialApp(home: PracticePersonalizationScreen(allQuestions: qs)));
    final title = find.text('Електромагнетна индукција и самоиндукција');
    expect(title, findsOneWidget);
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.text('Магнетни флукс и услови за индукцију'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Самоиндукција и промена струје'), 300);
    expect(find.text('Самоиндукција и промена струје'), findsOneWidget);
  });
}
