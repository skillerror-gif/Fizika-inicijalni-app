import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fizika_adaptivno_vezbanje/domain/master_test_generator.dart';

MasterLevel level(String achievementLevel)=>achievementLevel=='N3'?MasterLevel.advanced:achievementLevel=='N2'?MasterLevel.intermediate:MasterLevel.basic;

void main(){
  final raw=jsonDecode(File('assets/content/g1_kinematika_1.2.0_PASS.json').readAsStringSync()) as Map<String,dynamic>;
  final qs=(raw['questions'] as List).cast<Map<String,dynamic>>().map((q)=>TestQuestion(
    id:q['id'].toString(),unlockOrder:q['unlock_order'] as int,level:level(q['achievement_level'].toString()),
    nature:q['nature'].toString(),representation:q['representation'].toString(),subdomainId:q['subdomain_id'].toString(),
    correctOptionId:q['correct_option_id'].toString(),equivalenceGroup:(q['equivalence_group']??'').toString(),
    published:q['status']=='published',scientificPass:q['scientific_status'].toString().toLowerCase()=='pass')).toList();

  test('production bank respects lesson-7 HARD STOP and can generate repeated MASTER tests',(){
    for(var seed=0;seed<50;seed++){
      final out=MasterTestGenerator(random:Random(seed)).generate(qs,35);
      expect(out.length,16);
      expect(out.where((q)=>q.level==MasterLevel.basic).length,8);
      expect(out.where((q)=>q.level==MasterLevel.intermediate).length,5);
      expect(out.where((q)=>q.level==MasterLevel.advanced).length,3);
      expect(out.every((q)=>q.unlockOrder<=35),isTrue);
      final theory=out.where((q)=>q.nature=='theory').length;
      final calc=out.where((q)=>q.nature=='calculation').length;
      expect(theory,inInclusiveRange(7,9));expect(calc,inInclusiveRange(7,9));
      expect(out.where((q)=>q.representation=='graph').length,greaterThanOrEqualTo(2));
      expect(out.where((q)=>q.representation=='table').length,greaterThanOrEqualTo(1));
      expect(out.where((q)=>q.representation=='scheme').length,greaterThanOrEqualTo(1));
      final answerCounts=['A','B','V','G'].map((a)=>out.where((q)=>q.correctOptionId==a).length).toList();\n      expect(answerCounts.reduce(max)-answerCounts.reduce(min),lessThanOrEqualTo(1));
      expect(out.map((q)=>q.subdomainId).toSet(),containsAll(['KIN-01','KIN-02','KIN-03','KIN-08']));
    }
  });
}
