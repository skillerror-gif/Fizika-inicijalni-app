import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fizika_adaptivno_vezbanje/domain/master_test_generator.dart';

TestQuestion q(int i,{MasterLevel level=MasterLevel.basic,String nature='theory',String rep='text',int unlock=35,String? sub,String? ans,String? eq})=>TestQuestion(id:'q$i',unlockOrder:unlock,level:level,nature:nature,representation:rep,subdomainId:sub??'s${i%4}',correctOptionId:ans??['A','B','V','G'][i%4],equivalenceGroup:eq??'e$i',published:true,scientificPass:true);

void main(){
 test('HARD STOP excludes later material',(){
   final g=MasterTestGenerator(random:Random(1));
   final pool=[q(1),q(2,unlock:40)];
   expect(g.auditPool(pool,35).isNotEmpty,isTrue);
 });
 test('audit reports missing graph and scheme',(){
   final pool=<TestQuestion>[];
   for(var i=0;i<8;i++) pool.add(q(i,level:MasterLevel.basic,nature:i<4?'theory':'calculation',rep:i==0?'table':'text'));
   for(var i=8;i<13;i++) pool.add(q(i,level:MasterLevel.intermediate,nature:i.isEven?'theory':'calculation'));
   for(var i=13;i<16;i++) pool.add(q(i,level:MasterLevel.advanced,nature:i.isEven?'theory':'calculation'));
   final reasons=MasterTestGenerator(random:Random(1)).auditPool(pool,35);
   expect(reasons.any((x)=>x.contains('grafička')),isTrue);
   expect(reasons.any((x)=>x.contains('šematskog')),isTrue);
 });
 test('random ordering avoids obvious consecutive pattern when alternatives exist',(){
   final source=<TestQuestion>[];
   for(var i=0;i<16;i++){
     final level=i<8?MasterLevel.basic:i<13?MasterLevel.intermediate:MasterLevel.advanced;
     final nature=i.isEven?'theory':'calculation';
     final rep=i==0||i==1?'graph':i==2?'table':i==3?'scheme':'text';
     source.add(q(i,level:level,nature:nature,rep:rep));
   }
   final out=MasterTestGenerator(random:Random(4)).generate(source,35);
   expect(out.length,16);
   for(var i=2;i<out.length;i++){
     expect(out[i].subdomainId==out[i-1].subdomainId&&out[i].subdomainId==out[i-2].subdomainId,isFalse);
     expect(out[i].correctOptionId==out[i-1].correctOptionId&&out[i].correctOptionId==out[i-2].correctOptionId,isFalse);
   }
   for(var i=1;i<out.length;i++) expect(out[i].equivalenceGroup==out[i-1].equivalenceGroup,isFalse);
 });
}