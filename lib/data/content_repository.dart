import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'content_update_service.dart';

class ContentRepository {
  static final Uri manifestUri = Uri.parse(
    'https://raw.githubusercontent.com/skillerror-gif/Fizika-inicijalni-app/main/assets/content/manifest.json',
  );
  static final Uri grade3ManifestUri = manifestUri.resolve('manifest_g3.json');

  static Future<String> loadRaw() async {
    final dir = Directory(await getDatabasesPath());
    final current = File(join(dir.path, 'content_current.json'));
    if (await current.exists()) {
      try {
        final raw = await current.readAsString();
        final d = jsonDecode(raw);
        if (d is Map && d['questions'] is List) return raw;
      } catch (_) {}
    }
    return rootBundle.loadString('assets/content/g1_fizika_1.3.0_PASS.json');
  }

  static Future<String> loadRawForGrade(int grade) async {
    if (grade == 3) {
      final dir = Directory(await getDatabasesPath());
      final current = File(join(dir.path, 'content_g3_current.json'));
      if (await current.exists()) {
        try {
          final raw = await current.readAsString();
          final data = jsonDecode(raw);
          if (data is Map && data['grade'] == 3 &&
              data['database_id'] == 'fizika-app-g3-mag' &&
              data['questions'] is List) return raw;
        } catch (_) { /* keep bundled offline content */ }
      }
      return rootBundle.loadString('assets/content/g3_fizika_3.2.0.json');
    }
    return loadRaw();
  }

  static Future<void> refreshSilently({int grade = 1}) async {
    final client = http.Client();
    try {
      if (grade == 3) {
        await ContentUpdateService(client, appVersion: '0.1.2').installAtomically(
          grade3ManifestUri,
          contentPrefix: 'content_g3',
          expectedGrade: 3,
          expectedDatabaseId: 'fizika-app-g3-mag',
          minimumContentVersion: '3.2.0',
        );
      } else {
        await ContentUpdateService(client).installAtomically(manifestUri);
      }
    } catch (_) {
      /* offline/update failure: keep last valid content */
    } finally {
      client.close();
    }
  }
}
