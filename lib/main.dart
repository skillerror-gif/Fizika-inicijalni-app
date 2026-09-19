import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
void main()=>runApp(const FizikaApp());
class FizikaApp extends StatelessWidget { const FizikaApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Физика — вежбање',theme:ThemeData(useMaterial3:true),home:const HomeScreen()); }