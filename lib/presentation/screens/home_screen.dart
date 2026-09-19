import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppQuestion {
  AppQuestion(this.id,this.lessonId,this.subdomain,this.stem,this.options,this.correct,this.explanation,this.unlock);
  final String id,lessonId,subdomain,stem,correct,explanation;
  final Map<String,String> options;
  final int unlock;
  factory AppQuestion.fromJson(Map<String,dynamic> j) {
    final opts=<String,String>{};
    for(final o in (j['options'] as List? ?? const [])){opts[o['option_id'].toString()]=o['text'].toString();}
    final lessons=(j['lesson_ids'] as List? ?? const []);
    final lesson=lessons.isNotEmpty?lessons.first.toString():j['subdomain_id'].toString();
    return AppQuestion(j['id'].toString(),lesson,j['subdomain_name'].toString(),j['stem'].toString(),opts,j['correct_option_id'].toString(),j['explanation'].toString(),j['unlock_order'] as int);
  }
}

Future<List<AppQuestion>> loadQuestions() async {
  final raw=await rootBundle.loadString('assets/content/g1_kinematika_1.1.1.json');
  final data=jsonDecode(raw) as Map<String,dynamic>;
  return (data['questions'] as List).map((e)=>AppQuestion.fromJson(e)).where((q)=>q.unlock<=35).toList();
}

const lessonNames=<String,String>{
  'KIN-01':'Референтни систем и материјална тачка',
  'KIN-02':'Положај, путања, пут и померај',
  'KIN-03':'Средња и тренутна брзина',
  'KIN-08':'Слагање брзина и релативно кретање',
};

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen>{
  late Future<List<AppQuestion>> _questions;
  @override void initState(){super.initState();_questions=loadQuestions();}
  void _openPractice(List<AppQuestion> all,{String? subdomain,int count=10}){
    var pool=all.where((q)=>subdomain==null||q.subdomain==subdomain).toList()..shuffle(Random.secure());
    Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:pool.take(count.clamp(1,pool.length)).toList())));
  }
  void _openFormative(List<AppQuestion> qs){
    Navigator.push(context,MaterialPageRoute(builder:(_)=>FormativeLessonScreen(allQuestions:qs)));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Fizika za I razred gimnazije')),
    body:FutureBuilder<List<AppQuestion>>(future:_questions,builder:(context,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Greška pri učitavanju baze: ${s.error}')));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final qs=s.data!; final areas=qs.map((q)=>q.subdomain).toSet().toList();
      return ListView(padding:const EdgeInsets.all(20),children:[
        const Text('Vežbanje kinematike',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),const Text('Izaberi način rada. Dostupno je samo gradivo obrađeno do 7. časa.'),
        const SizedBox(height:20),
        FilledButton.icon(onPressed:()=>_openPractice(qs),icon:const Icon(Icons.school),label:const Text('Vežbaj')),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:()=>_openFormative(qs),icon:const Icon(Icons.fact_check),label:const Text('Formativna provera časa')),
        const SizedBox(height:10),
        FilledButton.tonalIcon(onPressed:()=>_openPractice(qs,count:16),icon:const Icon(Icons.assignment),label:const Text('Test — 16 pitanja')),
        const SizedBox(height:24),const Text('Personalizuj vežbanje',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        ...areas.map((a)=>Card(child:ListTile(title:Text(a),subtitle:const Text('Oblast je dostupna za vežbanje'),trailing:const Icon(Icons.chevron_right),onTap:()=>_openPractice(qs,subdomain:a)))),
        const SizedBox(height:16),
        const Card(child:ListTile(leading:Icon(Icons.lock_outline),title:Text('Kasnije oblasti'),subtitle:Text('Ubrzanje i naredno gradivo ostaju zaključani dok ne budu obrađeni.'))),
      ]);
    })
  );
}

class FormativeLessonScreen extends StatelessWidget{
  const FormativeLessonScreen({super.key,required this.allQuestions});
  final List<AppQuestion> allQuestions;
  @override Widget build(BuildContext context){
    final ids=allQuestions.map((q)=>q.lessonId).toSet().where(lessonNames.containsKey).toList()
      ..sort((a,b)=>(allQuestions.firstWhere((q)=>q.lessonId==a).unlock).compareTo(allQuestions.firstWhere((q)=>q.lessonId==b).unlock));
    return Scaffold(appBar:AppBar(title:const Text('Formativna provera časa')),body:ListView(padding:const EdgeInsets.all(20),children:[
      const Text('Izaberi obrađenu nastavnu celinu',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),const Text('Provera je kratka, daje povratnu informaciju i ne predstavlja brojčanu ocenu.'),
      const SizedBox(height:16),
      ...ids.map((id){final pool=allQuestions.where((q)=>q.lessonId==id).toList();return Card(child:ListTile(
        leading:const Icon(Icons.menu_book),title:Text(lessonNames[id]!),subtitle:const Text('5–8 nasumičnih pitanja'),
        trailing:const Icon(Icons.chevron_right),onTap:(){
          pool.shuffle(Random.secure()); final n=min(8,pool.length);
          Navigator.push(context,MaterialPageRoute(builder:(_)=>FormativeQuizScreen(questions:pool.take(n).toList(),lessonName:lessonNames[id]!)));
        }));})
    ]));
  }
}

class FormativeQuizScreen extends StatefulWidget{
  const FormativeQuizScreen({super.key,required this.questions,required this.lessonName});
  final List<AppQuestion> questions; final String lessonName;
  @override State<FormativeQuizScreen> createState()=>_FormativeQuizScreenState();
}
class _FormativeQuizScreenState extends State<FormativeQuizScreen>{
  int i=0,correct=0; String? selected; bool answered=false;
  final List<AppQuestion> missed=[];
  void answer(String id){if(answered)return;final q=widget.questions[i];setState((){selected=id;answered=true;if(id==q.correct){correct++;}else{missed.add(q);}});}
  void next(){if(i+1>=widget.questions.length){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>FormativeResultScreen(correct:correct,total:widget.questions.length,lessonName:widget.lessonName,missed:missed)));}else{setState((){i++;selected=null;answered=false;});}}
  @override Widget build(BuildContext context){final q=widget.questions[i];return Scaffold(appBar:AppBar(title:Text('Formativna provera • ${i+1}/${widget.questions.length}')),body:ListView(padding:const EdgeInsets.all(20),children:[
    LinearProgressIndicator(value:(i+1)/widget.questions.length),const SizedBox(height:16),Text(widget.lessonName,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:10),Text(q.stem,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
    ...q.options.entries.map((e){final good=e.key==q.correct,sel=e.key==selected;Color? c;if(answered&&good)c=Colors.green.shade100;else if(answered&&sel)c=Colors.red.shade100;return Card(color:c,child:ListTile(title:Text('${e.key}. ${e.value}'),onTap:()=>answer(e.key)));}),
    if(answered)...[const SizedBox(height:12),Text(selected==q.correct?'Tačno.':'Netačno.',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:selected==q.correct?Colors.green:Colors.red)),const SizedBox(height:6),Text(q.explanation),const SizedBox(height:20),FilledButton(onPressed:next,child:Text(i+1==widget.questions.length?'Pregled':'Sledeće pitanje'))]
  ]));}
}

class FormativeResultScreen extends StatelessWidget{
  const FormativeResultScreen({super.key,required this.correct,required this.total,required this.lessonName,required this.missed});
  final int correct,total; final String lessonName; final List<AppQuestion> missed;
  @override Widget build(BuildContext context){final pct=(100*correct/total).round();final msg=pct>=75?'Ključni ishodi ove celine su uglavnom usvojeni.':pct>=60?'Potrebno je kratko utvrđivanje pojedinih pojmova.':'Preporučeno je ciljano obnavljanje ove celine.';
    return Scaffold(appBar:AppBar(title:const Text('Povratna informacija')),body:ListView(padding:const EdgeInsets.all(24),children:[
      Text(lessonName,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),Text('$correct / $total',style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold)),Text('$pct%'),const SizedBox(height:16),Text(msg,style:const TextStyle(fontSize:18)),
      if(missed.isNotEmpty)...[const SizedBox(height:20),const Text('Obnovi:',style:TextStyle(fontWeight:FontWeight.bold)),...missed.map((q)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.refresh),title:Text(q.subdomain)))],
      const SizedBox(height:20),FilledButton.icon(onPressed:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_){final p=missed.isEmpty?const <AppQuestion>[]:missed.toList()..shuffle(Random.secure());return QuizScreen(questions:p.isEmpty?widgetFallback():p);})),icon:const Icon(Icons.replay),label:Text(missed.isEmpty?'Ponovi kasnije':'Vežbaj ovo')),
      TextButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))
    ]));}
  List<AppQuestion> widgetFallback()=>[];
}

class QuizScreen extends StatefulWidget{const QuizScreen({super.key,required this.questions});final List<AppQuestion> questions;@override State<QuizScreen> createState()=>_QuizScreenState();}
class _QuizScreenState extends State<QuizScreen>{
  int i=0,correct=0; String? selected; bool answered=false;
  void answer(String id){if(answered||widget.questions.isEmpty)return;setState((){selected=id;answered=true;if(id==widget.questions[i].correct)correct++;});}
  void next(){if(i+1>=widget.questions.length){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ResultScreen(correct:correct,total:widget.questions.length)));}else{setState((){i++;selected=null;answered=false;});}}
  @override Widget build(BuildContext context){if(widget.questions.isEmpty)return Scaffold(appBar:AppBar(),body:Center(child:FilledButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))));final q=widget.questions[i];return Scaffold(appBar:AppBar(title:Text('Pitanje ${i+1} / ${widget.questions.length}')),body:ListView(padding:const EdgeInsets.all(20),children:[
    LinearProgressIndicator(value:(i+1)/widget.questions.length),const SizedBox(height:20),Text(q.subdomain,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:8),Text(q.stem,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
    ...q.options.entries.map((e){final isCorrect=e.key==q.correct;final isSel=e.key==selected;Color? c;if(answered&&isCorrect)c=Colors.green.shade100;else if(answered&&isSel)c=Colors.red.shade100;return Card(color:c,child:ListTile(title:Text('${e.key}. ${e.value}'),onTap:()=>answer(e.key)));}),
    if(answered)...[const SizedBox(height:12),Text(selected==q.correct?'Tačno.':'Netačno.',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:selected==q.correct?Colors.green:Colors.red)),const SizedBox(height:6),Text(q.explanation),const SizedBox(height:20),FilledButton(onPressed:next,child:Text(i+1==widget.questions.length?'Rezultat':'Sledeće pitanje'))]
  ]));}
}
class ResultScreen extends StatelessWidget{const ResultScreen({super.key,required this.correct,required this.total});final int correct,total;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Rezultat')),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.emoji_events,size:64),Text('$correct / $total',style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold)),Text(total==0?'—':'${(100*correct/total).round()}%'),const SizedBox(height:24),FilledButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))]))));}
