import 'package:flutter_test/flutter_test.dart';
import 'package:fizika_adaptivno_vezbanje/domain/adaptive_engine.dart';
import 'package:fizika_adaptivno_vezbanje/domain/models.dart';
Attempt a(int i,bool ok,{Difficulty d=Difficulty.basic,String? q,String? err})=>Attempt(id:'a$i',questionId:q??'q${i%5}',lessonId:'KIN-01',difficulty:d,correct:ok,at:DateTime(2026,9,19,12,i),errorCategory:err);
Question q(String id,{int unlock=10,bool pub=true,bool pass=true,bool adaptive=true,bool meta=true,String lesson='KIN-01'})=>Question(id:id,lessonId:lesson,unlockOrder:unlock,difficulty:Difficulty.basic,stem:'s',options:const {'A':'a','B':'b'},correctOptionId:'A',explanation:'e',published:pub,scientificPass:pass,adaptiveEnabled:adaptive,metadataComplete:meta);
void main(){final e=AdaptiveEngine();
 test('1-4 attempts insufficient',()=>expect(e.diagnose([a(1,false),a(2,false),a(3,false),a(4,false)]).state,PracticeState.insufficientData));
 test('five attempts on two questions insufficient',()=>expect(e.diagnose(List.generate(5,(i)=>a(i,false,q:'q${i%2}'))).state,PracticeState.insufficientData));
 test('S below 60 targeted',()=>expect(e.diagnose(List.generate(6,(i)=>a(i,i==0))).state,PracticeState.targetedPractice));
 test('60-74.99 consolidation',(){final h=[a(1,true,q:'q1'),a(2,true,q:'q2'),a(3,true,q:'q3'),a(4,false,q:'q4'),a(5,false,q:'q5')];expect(e.diagnose(h).state,PracticeState.consolidation);});
 test('>=75 without stable evidence stays consolidation',(){final h=[a(1,true,q:'q1'),a(2,true,q:'q2'),a(3,true,q:'q3'),a(4,true,q:'q1'),a(5,false,q:'q2')];expect(e.diagnose(h).state,PracticeState.consolidation);});
 test('stable requires 8 attempts 4 unique and recent 4/5',(){final h=[a(1,true,q:'q1'),a(2,true,q:'q2'),a(3,true,q:'q3'),a(4,true,q:'q4'),a(5,true,q:'q1'),a(6,true,q:'q2'),a(7,true,q:'q3'),a(8,true,q:'q4')];expect(e.diagnose(h).state,PracticeState.stable);});
 test('eligibility hard stops',(){final out=e.eligible([q('ok'),q('locked',unlock:20),q('approved',pub:false),q('fail',pass:false),q('meta',meta:false),q('nonadaptive',adaptive:false)],10);expect(out.map((x)=>x.id),['ok']);});
 test('manual lesson selection cannot bypass unlock',(){final out=e.eligible([q('locked',unlock:20),q('other',lesson:'KIN-02')],10,adaptive:false,lessonId:'KIN-01');expect(out,isEmpty);});
 test('cooldown avoids last two when alternatives exist',(){final c=[q('q1'),q('q2'),q('q3')];final out=e.applyCooldown(c,[a(9,true,q:'q1'),a(8,true,q:'q2')]);expect(out.map((x)=>x.id),['q3']);});
 test('difficulty rises at most one level after 3 correct',()=>expect(e.preferredDifficulty([a(1,true),a(2,true),a(3,true)],Difficulty.basic),Difficulty.intermediate));
 test('difficulty falls at most one after 2 of 3 wrong',()=>expect(e.preferredDifficulty([a(1,false),a(2,true),a(3,false)],Difficulty.advanced),Difficulty.intermediate));
 test('error signal needs 3 wrong on 2 unique questions',(){final h=[a(1,false,q:'q1',err:'units'),a(2,false,q:'q2',err:'units'),a(3,false,q:'q1',err:'units'),a(4,true,q:'q3'),a(5,true,q:'q4')];expect(e.diagnose(h).errorSignal,'units');});
}