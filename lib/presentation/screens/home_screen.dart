import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/content_repository.dart';
import '../../domain/progress_store.dart';
import '../../domain/master_test_generator.dart';
import '../widgets/visual_question_panel.dart';
import 'user_guide_screen.dart';

class AppQuestion {
  AppQuestion(this.id,this.lessonId,this.subdomain,this.stem,this.options,this.correct,this.explanation,this.unlock,this.difficulty,this.achievementLevel,this.nature,this.representation,this.subdomainId,this.equivalenceGroup,this.media);
  final String id,lessonId,subdomain,stem,correct,explanation;
  final Map<String,String> options; final int unlock; final String difficulty,achievementLevel,nature,representation,subdomainId,equivalenceGroup; final Map<String,dynamic> media;
  factory AppQuestion.fromJson(Map<String,dynamic> j){
    final opts=<String,String>{}; for(final o in (j['options'] as List? ?? const [])){opts[o['option_id'].toString()]=o['text'].toString();}
    final lessons=(j['lesson_ids'] as List? ?? const []); final lesson=lessons.isNotEmpty?lessons.first.toString():j['subdomain_id'].toString();
    return AppQuestion(j['id'].toString(),lesson,j['subdomain_name'].toString(),j['stem'].toString(),opts,j['correct_option_id'].toString(),j['explanation'].toString(),j['unlock_order'] as int,(j['difficulty']??'basic').toString(),(j['achievement_level']??'').toString(),(j['nature']??'theory').toString(),(j['representation']??'text').toString(),j['subdomain_id'].toString(),(j['equivalence_group']??'').toString(),Map<String,dynamic>.from(j['media'] as Map? ?? const {}));
  }
}
Future<List<AppQuestion>> loadQuestions() async{final raw=await ContentRepository.loadRaw();ContentRepository.refreshSilently();final data=jsonDecode(raw) as Map<String,dynamic>;return (data['questions'] as List).map((e)=>AppQuestion.fromJson(e)).where((q)=>q.unlock<=35).toList();}

const mainAreaNames=<String,String>{'UVF':'Увод у физику','KIN':'Кинематика'};
String mainAreaId(String subdomainId)=>subdomainId.split('-').first;

const lessonNames=<String,String>{'UVF-01':'Предмет, методе и задаци физике','UVF-02':'Физичке величине, мерење и SI јединице','UVF-03':'Скаларне и векторске физичке величине','KIN-01':'Референтни систем и материјална тачка','KIN-02':'Положај, путања, пут и померај','KIN-03':'Средња и тренутна брзина','KIN-08':'Слагање брзина и релативно кретање'};

List<AppQuestion> randomizedPractice(List<AppQuestion> source,{int count=10,String focus='mixed'}){
  final random=Random.secure(),pool=source.toList()..shuffle(random);
  final result=<AppQuestion>[];
  int targetCalculation;
  if(focus=='calculation'){targetCalculation=count;}
  else if(focus=='theory'){targetCalculation=0;}
  else{targetCalculation=(count/2).round();}
  int calc=0;
  while(pool.isNotEmpty&&result.length<count){
    final needCalc=calc<targetCalculation;
    var candidates=pool.where((q)=>focus=='calculation'?q.nature=='calculation':focus=='theory'?q.nature=='theory':(needCalc?q.nature=='calculation':q.nature!='calculation')).toList();
    if(candidates.isEmpty)candidates=pool;
    if(result.length>=2&&result.last.subdomain==result[result.length-2].subdomain){
      final alt=candidates.where((q)=>q.subdomain!=result.last.subdomain).toList();if(alt.isNotEmpty)candidates=alt;
    }
    final q=candidates[random.nextInt(candidates.length)];pool.removeWhere((x)=>x.id==q.id);result.add(q);if(q.nature=='calculation')calc++;
  }
  return result;
}

MasterLevel _level(String a){switch(a){case 'N1':return MasterLevel.basic;case 'N2':return MasterLevel.intermediate;case 'N3':return MasterLevel.advanced;default:throw FormatException('Nepoznat achievement_level: $a');}}
void _openMasterTest(BuildContext context,List<AppQuestion> qs){
  final map={for(final q in qs)q.id:q};
  final tq=qs.map((q)=>TestQuestion(id:q.id,unlockOrder:q.unlock,level:_level(q.achievementLevel),nature:q.nature,representation:q.representation,subdomainId:q.subdomainId,correctOptionId:q.correct,equivalenceGroup:q.equivalenceGroup,published:true,scientificPass:true)).toList();
  try{final picked=MasterTestGenerator().generate(tq,35);Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:picked.map((x)=>map[x.id]!).toList())));}on TestGenerationException catch(e){showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Test trenutno nije moguće sastaviti'),content:Text('${e.reasons.join('\n')}\n\nNijedno pitanje iz kasnijeg gradiva neće biti upotrebljeno.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('U redu'))]));}
}

class HomeScreen extends StatefulWidget{const HomeScreen({super.key});@override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen>{
  late Future<List<AppQuestion>> _questions;@override void initState(){super.initState();_questions=loadQuestions();}
  Future<void> _practice(List<AppQuestion> qs,{int count=10}) async{
    final summaries=await AdaptiveEngine.all();
    final weak=summaries.where((x)=>x.isWeak).map((x)=>x.subdomain).toSet();
    final focused=weak.isEmpty?qs:qs.where((q)=>weak.contains(q.subdomain)).toList();
    if(!mounted)return;
    Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:randomizedPractice(focused,count:min(count,focused.length)))));
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Fizika za I razred gimnazije')),body:FutureBuilder<List<AppQuestion>>(future:_questions,builder:(context,s){
    if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Greška pri učitavanju baze: ${s.error}')));if(!s.hasData)return const Center(child:CircularProgressIndicator());final qs=s.data!;
    return ListView(padding:const EdgeInsets.all(20),children:[
      const Text('Fizika za I razred gimnazije',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('Vežbanje i provera znanja',style:TextStyle(fontSize:18,fontWeight:FontWeight.w500)),const SizedBox(height:8),const Text('Izaberi način rada.'),const SizedBox(height:20),
      _HomeCard(icon:Icons.school,title:'Vežbaj',subtitle:'Mešovito vežbanje: teorijski i računski zadaci',onTap:()=>_practice(qs)),
      _HomeCard(icon:Icons.tune,title:'Personalizuj vežbanje',subtitle:'Izaberi jednu, više ili sve oblasti',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PracticePersonalizationScreen(allQuestions:qs)))),
      _HomeCard(icon:Icons.fact_check,title:'Formativna provera časa',subtitle:'Kratka provera sa povratnom informacijom',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>FormativeLessonScreen(allQuestions:qs)))),
      _HomeCard(icon:Icons.assignment,title:'Test',subtitle:'Provera znanja',onTap:()=>_openMasterTest(context,qs)),
      _HomeCard(icon:Icons.insights,title:'Moj napredak',subtitle:'Pregled napretka i oblasti za dodatno vežbanje',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProgressScreen(allQuestions:qs)))),
      _HomeCard(icon:Icons.help_outline,title:'Korisničko uputstvo',subtitle:'Kako se koriste vežbanje, provera, test i napredak',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const UserGuideScreen()))),
    ]);
  }));
}
class _HomeCard extends StatelessWidget{const _HomeCard({required this.icon,required this.title,required this.subtitle,required this.onTap});final IconData icon;final String title,subtitle;final VoidCallback onTap;@override Widget build(BuildContext context)=>Card(child:ListTile(leading:Icon(icon),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:onTap));}

class PracticePersonalizationScreen extends StatefulWidget{const PracticePersonalizationScreen({super.key,required this.allQuestions});final List<AppQuestion> allQuestions;@override State<PracticePersonalizationScreen> createState()=>_PracticePersonalizationScreenState();}
class _PracticePersonalizationScreenState extends State<PracticePersonalizationScreen>{
  final Set<String> selectedSubdomains={};final Set<String> expandedAreas={};int count=10;String focus='mixed';
  List<String> get areas{final ids=widget.allQuestions.map((q)=>mainAreaId(q.subdomainId)).toSet().toList();ids.sort();return ids;}
  List<String> subdomains(String area){final ids=widget.allQuestions.where((q)=>mainAreaId(q.subdomainId)==area).map((q)=>q.subdomainId).toSet().toList();ids.sort();return ids;}
  bool areaSelected(String area){final ids=subdomains(area);return ids.isNotEmpty&&ids.every(selectedSubdomains.contains);}
  void toggleArea(String area,bool value){final ids=subdomains(area);setState((){if(value){selectedSubdomains.addAll(ids);}else{selectedSubdomains.removeAll(ids);}});}
  void start(){final pool=widget.allQuestions.where((q)=>selectedSubdomains.isEmpty||selectedSubdomains.contains(q.subdomainId)).toList();if(pool.isEmpty)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:randomizedPractice(pool,count:min(count,pool.length),focus:focus))));}
  @override Widget build(BuildContext context){final all=selectedSubdomains.isEmpty;return Scaffold(appBar:AppBar(title:const Text('Personalizuj vežbanje')),body:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Oblasti',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('Izaberi sve obrađene oblasti, glavnu oblast ili pojedinačno gradivo unutar nje.'),
    CheckboxListTile(value:all,title:const Text('Sve obrađene oblasti'),subtitle:const Text('Koristi ceo trenutno dostupan fond pitanja'),onChanged:(_)=>setState(selectedSubdomains.clear)),
    ...areas.map((area){final open=expandedAreas.contains(area);final ids=subdomains(area);return Card(child:Column(children:[
      ListTile(leading:Checkbox(value:areaSelected(area),onChanged:(v)=>toggleArea(area,v==true)),title:Text(mainAreaNames[area]??area),subtitle:Text('${ids.length} obrađenih celina'),trailing:Icon(open?Icons.expand_less:Icons.expand_more),onTap:()=>setState(()=>open?expandedAreas.remove(area):expandedAreas.add(area))),
      if(open)...ids.map((id)=>CheckboxListTile(contentPadding:const EdgeInsets.only(left:48,right:16),value:selectedSubdomains.contains(id),title:Text(lessonNames[id]??id),onChanged:(v)=>setState((){if(v==true){selectedSubdomains.add(id);}else{selectedSubdomains.remove(id);}})))
    ]));}),
    const SizedBox(height:12),const Text('Vrsta zadataka',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    SegmentedButton<String>(segments:const [ButtonSegment(value:'mixed',label:Text('Mešovito')),ButtonSegment(value:'calculation',label:Text('Računski')),ButtonSegment(value:'theory',label:Text('Teorijski'))],selected:{focus},onSelectionChanged:(v)=>setState(()=>focus=v.first)),
    const SizedBox(height:12),Text('Broj pitanja: $count'),Slider(value:count.toDouble(),min:5,max:20,divisions:15,label:'$count',onChanged:(v)=>setState(()=>count=v.round())),
    const SizedBox(height:12),FilledButton.icon(onPressed:start,icon:const Icon(Icons.play_arrow),label:Text(all?'Vežbaj sve obrađene oblasti':'Vežbaj izabrano (${selectedSubdomains.length})'))
  ]));}
}

class FormativeLessonScreen extends StatelessWidget{const FormativeLessonScreen({super.key,required this.allQuestions});final List<AppQuestion> allQuestions;@override Widget build(BuildContext context){final ids=allQuestions.map((q)=>q.lessonId).toSet().where(lessonNames.containsKey).toList()..sort((a,b)=>allQuestions.firstWhere((q)=>q.lessonId==a).unlock.compareTo(allQuestions.firstWhere((q)=>q.lessonId==b).unlock));return Scaffold(appBar:AppBar(title:const Text('Formativna provera časa')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('Izaberi obrađenu nastavnu celinu',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('Provera je kratka, daje povratnu informaciju i ne predstavlja brojčanu ocenu.'),const SizedBox(height:16),...ids.map((id){final pool=allQuestions.where((q)=>q.lessonId==id).toList();return Card(child:ListTile(leading:const Icon(Icons.menu_book),title:Text(lessonNames[id]!),subtitle:const Text('5–8 nasumičnih pitanja'),trailing:const Icon(Icons.chevron_right),onTap:(){pool.shuffle(Random.secure());final n=min(8,pool.length);Navigator.push(context,MaterialPageRoute(builder:(_)=>FormativeQuizScreen(questions:pool.take(n).toList(),lessonName:lessonNames[id]!)));}));})]));}}

class FormativeQuizScreen extends StatefulWidget{const FormativeQuizScreen({super.key,required this.questions,required this.lessonName});final List<AppQuestion> questions;final String lessonName;@override State<FormativeQuizScreen> createState()=>_FormativeQuizScreenState();}
class _FormativeQuizScreenState extends State<FormativeQuizScreen>{int i=0,correct=0;String? selected;bool answered=false;final List<AppQuestion> missed=[];void answer(String id){if(answered)return;final q=widget.questions[i];final ok=id==q.correct;setState((){selected=id;answered=true;if(ok){correct++;}else{missed.add(q);}});ProgressStore.record(questionId:q.id,subdomain:q.subdomain,correct:ok,difficulty:q.difficulty);}void next(){if(i+1>=widget.questions.length){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>FormativeResultScreen(correct:correct,total:widget.questions.length,lessonName:widget.lessonName,missed:missed)));}else{setState((){i++;selected=null;answered=false;});}}@override Widget build(BuildContext context){final q=widget.questions[i];return Scaffold(appBar:AppBar(title:Text('Formativna provera • ${i+1}/${widget.questions.length}')),body:ListView(padding:const EdgeInsets.all(20),children:[LinearProgressIndicator(value:(i+1)/widget.questions.length),const SizedBox(height:16),Text(widget.lessonName,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:10),Text(q.stem,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),VisualQuestionPanel(representation:q.representation,media:q.media),const SizedBox(height:16),...q.options.entries.map((e){final good=e.key==q.correct,sel=e.key==selected;Color? c;if(answered&&good)c=Colors.green.shade100;else if(answered&&sel)c=Colors.red.shade100;return Card(color:c,child:ListTile(title:Text('${e.key}. ${e.value}'),onTap:()=>answer(e.key)));}),if(answered)...[const SizedBox(height:12),Text(selected==q.correct?'Tačno.':'Netačno.',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:selected==q.correct?Colors.green:Colors.red)),const SizedBox(height:6),Text(q.explanation),const SizedBox(height:20),FilledButton(onPressed:next,child:Text(i+1==widget.questions.length?'Pregled':'Sledeće pitanje'))]]));}}

class FormativeResultScreen extends StatelessWidget{const FormativeResultScreen({super.key,required this.correct,required this.total,required this.lessonName,required this.missed});final int correct,total;final String lessonName;final List<AppQuestion> missed;@override Widget build(BuildContext context){final pct=(100*correct/total).round();final msg=pct>=75?'Ključni ishodi ove celine su uglavnom usvojeni.':pct>=60?'Potrebno je kratko utvrđivanje pojedinih pojmova.':'Preporučeno je ciljano obnavljanje ove celine.';return Scaffold(appBar:AppBar(title:const Text('Povratna informacija')),body:ListView(padding:const EdgeInsets.all(24),children:[Text(lessonName,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),Text('$correct / $total',style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold)),Text('$pct%'),const SizedBox(height:16),Text(msg,style:const TextStyle(fontSize:18)),if(missed.isNotEmpty)...[const SizedBox(height:20),const Text('Obnovi:',style:TextStyle(fontWeight:FontWeight.bold)),...missed.map((q)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.refresh),title:Text(q.subdomain)))],const SizedBox(height:20),if(missed.isNotEmpty)FilledButton.icon(onPressed:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:randomizedPractice(missed,count:missed.length)))),icon:const Icon(Icons.replay),label:const Text('Vežbaj ovo')),TextButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))]));}}

class ProgressScreen extends StatefulWidget{const ProgressScreen({super.key,required this.allQuestions});final List<AppQuestion> allQuestions;@override State<ProgressScreen> createState()=>_ProgressScreenState();}
class _ProgressScreenState extends State<ProgressScreen>{late Future<List<ProgressSummary>> data;@override void initState(){super.initState();data=AdaptiveEngine.all();}String label(String s)=>s=='targeted'?'Potrebno ciljano vežbanje':s=='consolidation'?'Utvrdite gradivo':s=='stable'?'Stabilno usvojeno':'Još nema dovoljno pokušaja';@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Moj napredak')),body:FutureBuilder<List<ProgressSummary>>(future:data,builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!;if(rows.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Reši nekoliko pitanja da bi se pojavio pregled napretka.')));return ListView(padding:const EdgeInsets.all(20),children:[const Text('Napredak po oblastima',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('Procena se zasniva na poslednjim pokušajima i služi za usmeravanje vežbanja.'),const SizedBox(height:12),...rows.map((r)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r.subdomain,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(label(r.state)),Text('Poslednjih pokušaja: ${r.attempts} • uspešnost: ${r.weightedScore.round()}%'),if(r.isWeak)...[const SizedBox(height:8),FilledButton.tonal(onPressed:(){final pool=widget.allQuestions.where((q)=>q.subdomain==r.subdomain).toList();Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:randomizedPractice(pool,count:min(10,pool.length)))));},child:const Text('Vežbaj ovu oblast'))]]))))]);}));}

class QuizScreen extends StatefulWidget{const QuizScreen({super.key,required this.questions});final List<AppQuestion> questions;@override State<QuizScreen> createState()=>_QuizScreenState();}
class _QuizScreenState extends State<QuizScreen>{int i=0,correct=0;String? selected;bool answered=false;void answer(String id){if(answered||widget.questions.isEmpty)return;final q=widget.questions[i];final ok=id==q.correct;setState((){selected=id;answered=true;if(ok)correct++;});ProgressStore.record(questionId:q.id,subdomain:q.subdomain,correct:ok,difficulty:q.difficulty);}void next(){if(i+1>=widget.questions.length){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ResultScreen(correct:correct,total:widget.questions.length)));}else{setState((){i++;selected=null;answered=false;});}}@override Widget build(BuildContext context){if(widget.questions.isEmpty)return Scaffold(appBar:AppBar(),body:Center(child:FilledButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))));final q=widget.questions[i];return Scaffold(appBar:AppBar(title:Text('Pitanje ${i+1} / ${widget.questions.length}')),body:ListView(padding:const EdgeInsets.all(20),children:[LinearProgressIndicator(value:(i+1)/widget.questions.length),const SizedBox(height:20),Text(q.subdomain,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:8),Text(q.stem,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),VisualQuestionPanel(representation:q.representation,media:q.media),const SizedBox(height:16),...q.options.entries.map((e){final good=e.key==q.correct,sel=e.key==selected;Color? c;if(answered&&good)c=Colors.green.shade100;else if(answered&&sel)c=Colors.red.shade100;return Card(color:c,child:ListTile(title:Text('${e.key}. ${e.value}'),onTap:()=>answer(e.key)));}),if(answered)...[const SizedBox(height:12),Text(selected==q.correct?'Tačno.':'Netačno.',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:selected==q.correct?Colors.green:Colors.red)),const SizedBox(height:6),Text(q.explanation),const SizedBox(height:20),FilledButton(onPressed:next,child:Text(i+1==widget.questions.length?'Rezultat':'Sledeće pitanje'))]]));}}
class ResultScreen extends StatelessWidget{const ResultScreen({super.key,required this.correct,required this.total});final int correct,total;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Rezultat')),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.emoji_events,size:64),Text('$correct / $total',style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold)),Text(total==0?'—':'${(100*correct/total).round()}%'),const SizedBox(height:24),FilledButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))]))));}
