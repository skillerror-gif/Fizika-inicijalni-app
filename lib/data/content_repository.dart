import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'content_update_service.dart';

class ContentRepository{
  static final Uri manifestUri=Uri.parse('https://raw.githubusercontent.com/skillerror-gif/Fizika-inicijalni-app/main/assets/content/manifest.json');
  static Future<String> loadRaw() async{
    final dir=Directory(await getDatabasesPath());final current=File(join(dir.path,'content_current.json'));
    if(await current.exists()){try{final raw=await current.readAsString();final d=jsonDecode(raw);if(d is Map&&d['questions'] is List)return raw;}catch(_){}}
    return rootBundle.loadString('assets/content/g1_fizika_1.3.0_PASS.json');
  }
  static Future<void> refreshSilently() async{
    final client=http.Client();try{await ContentUpdateService(client).installAtomically(manifestUri);}catch(_){/* offline/update failure: keep last valid content */}finally{client.close();}
  }
}
