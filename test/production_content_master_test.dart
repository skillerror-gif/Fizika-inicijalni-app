import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fizika_adaptivno_vezbanje/domain/master_test_generator.dart';

MasterLevel level(String achievementLevel){switch(achievementLevel){case 'N1':return MasterLevel.basic;case 'N2':return MasterLevel.intermediate;case 'N3':return MasterLevel.advanced;default:throw FormatException('Nepoznat achievement_level: $achievementLevel');}}

void main(){
  final raw=jsonDecode(File('assets/content/g1_fizika_1.3.0_PASS.json').readAsStringSync()) as Map<String,dynamic>;
  final qs=(raw['questions'] as List).cast<Map<String,dynamic>>().map((q)=>TestQuestion(
    id:q['id'].toString(),unlockOrder:q['unlock_order'] as int,level:level(q['achievement_level'].toString()),
    nature:q['nature'].toString(),representation:q['representation'].toString(),subdomainId:q['subdomain_id'].toString(),
    correctOptionId:q['correct_option_id'].toString(),equivalenceGroup:(q['equivalence_group']??'').toString(),
    published:q['status']=='published',scientificPass:q['scientific_status'].toString().toLowerCase()=='pass')).toList();

  test('production bank respects current internal boundary and can generate repeated MASTER tests',(){
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
      final answerCounts=['A','B','V','G'].map((a)=>out.where((q)=>q.correctOptionId==a).length).toList();
      expect(answerCounts.every((n)=>n>=2&&n<=6),isTrue);
      for(var i=2;i<out.length;i++){expect(out[i].correctOptionId==out[i-1].correctOptionId&&out[i-1].correctOptionId==out[i-2].correctOptionId,isFalse);}
      for(var i=4;i<out.length;i++){final s=out.sublist(i-4,i+1).map((q)=>q.correctOptionId).toList();expect(s[0]==s[2]&&s[2]==s[4]&&s[1]==s[3],isFalse);}
      expect(out.map((q)=>q.subdomainId).toSet(),containsAll(['UVF-01','UVF-02','UVF-03','KIN-01','KIN-02','KIN-03','KIN-08']));
    }
  });
}
