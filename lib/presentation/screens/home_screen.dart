import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppQuestion {
  AppQuestion(this.id,this.subdomain,this.stem,this.options,this.correct,this.explanation,this.unlock);
  final String id,subdomain,stem,correct,explanation;
  final Map<String,String> options;
  final int unlock;
  factory AppQuestion.fromJson(Map<String,dynamic> j) {
    final opts=<String,String>{};
    for(final o in (j['options'] as List? ?? const [])){opts[o['option_id'].toString()]=o['text'].toString();}
    return AppQuestion(j['id'].toString(),j['subdomain_name'].toString(),j['stem'].toString(),opts,j['correct_option_id'].toString(),j['explanation'].toString(),j['unlock_order'] as int);
  }
}

Future<List<AppQuestion>> loadQuestions() async {
  final raw=await rootBundle.loadString('assets/content/g1_kinematika_1.1.0.json');
  final data=jsonDecode(raw) as Map<String,dynamic>;
  return (data['questions'] as List).map((e)=>AppQuestion.fromJson(e)).where((q)=>q.unlock<=35).toList();
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen>{
  late Future<List<AppQuestion>> _questions;
  @override void initState(){super.initState();_questions=loadQuestions();}
  void _openPractice(List<AppQuestion> all,{String? subdomain,int count=10}){
    var pool=all.where((q)=>subdomain==null||q.subdomain==subdomain).toList()..shuffle(Random.secure());
    Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizScreen(questions:pool.take(count.clamp(1,pool.length)).toList())));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Fizika za I razred gimnazije')),
    body:FutureBuilder<List<AppQuestion>>(future:_questions,builder:(context,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Greška pri učitavanju baze: ${s.error}')));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final qs=s.data!; final areas=qs.map((q)=>q.subdomain).toSet().toList();
      return ListView(padding:const EdgeInsets.all(20),children:[
        const Text('Vežbanje kinematike',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),Text('Dostupno: ${qs.length} pitanja iz obrađenog gradiva do 7. časa.'),
        const SizedBox(height:20),
        FilledButton.icon(onPressed:()=>_openPractice(qs),icon:const Icon(Icons.shuffle),label:const Text('Brzi kviz — nasumična pitanja')),
        const SizedBox(height:10),
        FilledButton.tonalIcon(onPressed:()=>_openPractice(qs,count:16),icon:const Icon(Icons.assignment),label:const Text('Test — 16 pitanja')),
        const SizedBox(height:24),const Text('Izaberi oblast',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        ...areas.map((a)=>Card(child:ListTile(title:Text(a),subtitle:Text('${qs.where((q)=>q.subdomain==a).length} pitanja'),trailing:const Icon(Icons.chevron_right),onTap:()=>_openPractice(qs,subdomain:a)))),
        const SizedBox(height:16),
        const Card(child:ListTile(leading:Icon(Icons.lock_outline),title:Text('Kasnije oblasti'),subtitle:Text('Ubrzanje i naredno gradivo ostaju zaključani dok ne budu obrađeni.'))),
      ]);
    })
  );
}

class QuizScreen extends StatefulWidget{const QuizScreen({super.key,required this.questions});final List<AppQuestion> questions;@override State<QuizScreen> createState()=>_QuizScreenState();}
class _QuizScreenState extends State<QuizScreen>{
  int i=0,correct=0; String? selected; bool answered=false;
  void answer(String id){if(answered)return;setState((){selected=id;answered=true;if(id==widget.questions[i].correct)correct++;});}
  void next(){if(i+1>=widget.questions.length){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ResultScreen(correct:correct,total:widget.questions.length)));}else{setState((){i++;selected=null;answered=false;});}}
  @override Widget build(BuildContext context){final q=widget.questions[i];return Scaffold(appBar:AppBar(title:Text('Pitanje ${i+1} / ${widget.questions.length}')),body:ListView(padding:const EdgeInsets.all(20),children:[
    LinearProgressIndicator(value:(i+1)/widget.questions.length),const SizedBox(height:20),Text(q.subdomain,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:8),Text(q.stem,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
    ...q.options.entries.map((e){final isCorrect=e.key==q.correct;final isSel=e.key==selected;Color? c;if(answered&&isCorrect)c=Colors.green.shade100;else if(answered&&isSel)c=Colors.red.shade100;return Card(color:c,child:ListTile(title:Text('${e.key}. ${e.value}'),onTap:()=>answer(e.key)));}),
    if(answered)...[const SizedBox(height:12),Text(selected==q.correct?'Tačno.':'Netačno.',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:selected==q.correct?Colors.green:Colors.red)),const SizedBox(height:6),Text(q.explanation),const SizedBox(height:20),FilledButton(onPressed:next,child:Text(i+1==widget.questions.length?'Rezultat':'Sledeće pitanje'))]
  ]));}
}
class ResultScreen extends StatelessWidget{const ResultScreen({super.key,required this.correct,required this.total});final int correct,total;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Rezultat')),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.emoji_events,size:64),Text('$correct / $total',style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold)),Text('${(100*correct/total).round()}%'),const SizedBox(height:24),FilledButton(onPressed:()=>Navigator.popUntil(context,(r)=>r.isFirst),child:const Text('Početni ekran'))]))));}
