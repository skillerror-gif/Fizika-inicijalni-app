import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fizika_adaptivno_vezbanje/domain/master_test_generator.dart';
import 'package:fizika_adaptivno_vezbanje/presentation/screens/home_screen.dart';

TestQuestion item(int id, MasterLevel level, {int unlock = 1, bool published = true, bool pass = true}) => TestQuestion(
  id: '$id', unlockOrder: unlock, level: level, nature: 'theory', representation: 'text',
  subdomainId: 'topic', correctOptionId: ['A','B','V','G'][id % 4],
  equivalenceGroup: 'same', published: published, scientificPass: pass,
);

List<TestQuestion> bank(int b, int m, int a) => [
  for (var i=0; i<b; i++) item(i, MasterLevel.basic),
  for (var i=0; i<m; i++) item(100+i, MasterLevel.intermediate),
  for (var i=0; i<a; i++) item(200+i, MasterLevel.advanced),
];

void main() {
  test('one missing advanced adds three unused basics', () {
    final r = MasterTestGenerator(random: Random(1)).generateConfiguredWithReport(bank(11,5,2), 35, count:16, focus:'theory');
    expect(r.questions.length,18);
    expect(r.replacementBasics,3);
    expect(r.missingAdvanced,1);
    expect(r.missingIntermediate,0);
    expect(r.adjusted,isTrue);
  });
  test('one missing intermediate adds two unused basics', () {
    final r = MasterTestGenerator(random: Random(2)).generateConfiguredWithReport(bank(10,4,3),35,count:16,focus:'theory');
    expect(r.questions.length,17);
    expect(r.replacementBasics,2);
    expect(r.missingIntermediate,1);
  });
  test('shortage uses remaining basics once, and a single topic cannot block ordering', () {
    final r = MasterTestGenerator().generateConfiguredWithReport(bank(10,0,0),35,count:16,focus:'theory');
    expect(r.questions.length,10);
    expect(r.replacementBasics,2);
    expect(r.questions.map((q)=>q.id).toSet().length,10);
    final one = MasterTestGenerator().generateConfiguredWithReport(bank(1,0,0),35,count:16,focus:'theory');
    expect(one.questions.length,1);
  });
  test('normal complete pool retains requested counts', () {
    final r = MasterTestGenerator(random:Random(3)).generateConfiguredWithReport([
      for (var i=0; i<16; i++) TestQuestion(id:'$i',unlockOrder:1,
        level:i<8?MasterLevel.basic:i<13?MasterLevel.intermediate:MasterLevel.advanced,
        nature:'theory', representation:'text',subdomainId:'s${i%4}',correctOptionId:['A','B','V','G'][i%4],
        equivalenceGroup:'e$i',published:true,scientificPass:true),
    ],35,count:16,focus:'theory');
    expect(r.questions.length,16);
    expect(r.adjusted,isFalse);
  });
  test('hard eligibility, focus and uniqueness never relax', () {
    final source = [item(1,MasterLevel.basic),item(1,MasterLevel.basic),
      item(2,MasterLevel.basic,unlock:36),item(3,MasterLevel.basic,published:false),item(4,MasterLevel.basic,pass:false)];
    final g = MasterTestGenerator();
    expect(g.generateConfigured(source,35,count:16,focus:'theory').map((q)=>q.id),['1']);
    expect(()=>g.generateConfigured(source,35,count:16,focus:'calculation'),throwsA(isA<TestGenerationException>()));
    expect(()=>g.generateConfigured(source,35,count:4),throwsA(isA<TestGenerationException>()));
  });
  test('real grade III groups and focus choices work at every requested length', () {
    final d = jsonDecode(File('assets/content/g3_fizika_3.2.0.json').readAsStringSync()) as Map<String,dynamic>;
    final all = questionsFromRaw(jsonEncode(d));
    final scopes = <List<AppQuestion>>[all,all.where((q)=>q.subdomainId.startsWith('IND')).toList(),
      for(final id in all.map((q)=>q.subdomainId).toSet()) all.where((q)=>q.subdomainId==id).toList()];
    final levels = {'N1':MasterLevel.basic,'N2':MasterLevel.intermediate,'N3':MasterLevel.advanced};
    for(final scope in scopes) {
      for(final focus in ['mixed','theory','calculation']) {
        final eligible = scope.where((q)=>focus=='mixed'||q.nature==focus).toList();
        final pool=scope.map((q)=>TestQuestion(id:q.id,unlockOrder:q.unlock,level:levels[q.achievementLevel]!,nature:q.nature,
          representation:q.representation,subdomainId:q.subdomainId,correctOptionId:q.correct,equivalenceGroup:q.equivalenceGroup,published:true,scientificPass:true)).toList();
        for(var count=5;count<=20;count++) {
          final g=MasterTestGenerator(random:Random(count));
          if(eligible.isEmpty) {
            expect(()=>g.generateConfiguredWithReport(pool,26,count:count,focus:focus),throwsA(isA<TestGenerationException>()));
          } else {
            final r=g.generateConfiguredWithReport(pool,26,count:count,focus:focus);
            expect(r.questions,isNotEmpty);
            expect(r.questions.map((q)=>q.id).toSet().length,r.questions.length);
            expect(r.questions.every((q)=>eligible.any((x)=>x.id==q.id)),isTrue);
          }
        }
      }
    }
  });
  testWidgets('setup reports one available question and starts a one-question test', (tester) async {
    final qs=questionsFromRaw(File('assets/content/g3_fizika_3.2.0.json').readAsStringSync());
    final single=qs.where((q)=>q.subdomainId=='IND-17').toList();
    await tester.pumpWidget(MaterialApp(home:TestSetupScreen(allQuestions:single)));
    await tester.scrollUntilVisible(find.text('Направи тест'),300);
    await tester.tap(find.text('Направи тест'));
    await tester.pumpAndSettle();
    expect(find.text('Тест је прилагођен'),findsOneWidget);
    expect(find.textContaining('Број питања: 1'),findsOneWidget);
    await tester.tap(find.text('Почни тест'));
    await tester.pumpAndSettle();
    expect(find.text('Тест • 1/1'),findsOneWidget);
  });
}
