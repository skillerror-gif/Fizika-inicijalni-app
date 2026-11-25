import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ContentPackageRef {
  const ContentPackageRef({
    required this.file,
    required this.sha256,
    required this.questionCount,
  });
  final String file, sha256;
  final int questionCount;
  factory ContentPackageRef.fromJson(Map<String, dynamic> j) =>
      ContentPackageRef(
        file: j['file'] as String,
        sha256: j['sha256'] as String,
        questionCount: (j['question_count'] ?? 0) as int,
      );
}

class ContentManifest {
  const ContentManifest({
    required this.contentVersion,
    required this.minimumAppVersion,
    required this.schemaVersion,
    required this.packages,
  });
  final String contentVersion, minimumAppVersion;
  final int schemaVersion;
  final List<ContentPackageRef> packages;
  factory ContentManifest.fromJson(Map<String, dynamic> j) => ContentManifest(
        contentVersion: j['content_version'] as String,
        minimumAppVersion: (j['minimum_app_version'] ?? '0.0.0').toString(),
        schemaVersion: j['schema_version'] as int,
        packages: (j['packages'] as List)
            .map((x) => ContentPackageRef.fromJson(x as Map<String, dynamic>))
            .toList(),
      );
}

class ContentUpdateService {
  ContentUpdateService(this.client, {this.appVersion = '0.1.1'});
  final http.Client client;
  final String appVersion;
  static List<int> _version(String v) {
    final core = v.split('+').first.split('-').first;
    final parts = core.split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0,
    );
  }

  static bool _olderThan(String current, String minimum) {
    final a = _version(current), b = _version(minimum);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] < b[i];
    }
    return false;
  }

  Future<ContentManifest> fetchManifest(Uri uri) async {
    final r = await client.get(uri).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) throw HttpException('Manifest ${r.statusCode}');
    return ContentManifest.fromJson(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }

  Future<List<int>> verifiedPackage(Uri base, ContentPackageRef p) async {
    final r = await client.get(base.resolve(p.file)).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) throw HttpException('Package ${r.statusCode}');
    final digest = await Sha256().hash(r.bodyBytes);
    final actual =
        digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (actual.toLowerCase() != p.sha256.toLowerCase())
      throw const FormatException('SHA-256 mismatch');
    _validateJson(utf8.decode(r.bodyBytes), p.questionCount);
    return r.bodyBytes;
  }

  void _validateJson(String raw, int expected) {
    final d = jsonDecode(raw);
    if (d is! Map<String, dynamic> || d['schema_version'] != 1 || d['questions'] is! List)
      throw const FormatException('Neispravna struktura baze');
    final q = d['questions'] as List;
    if (expected > 0 && q.length != expected)
      throw const FormatException('Broj pitanja ne odgovara manifestu');
    final ids = <String>{};
    for (final x in q) {
      if (x is! Map<String, dynamic>)
        throw const FormatException('Neispravan zapis');
      final id = x['id']?.toString() ?? '';
      if (id.isEmpty || !ids.add(id))
        throw const FormatException('Nedostaje ili se ponavlja ID');
      if (x['status'] == 'published' &&
          x['scientific_status']?.toString().toLowerCase() != 'pass')
        throw const FormatException('Objavljeno pitanje bez naučnog PASS-a');
      if (x['options'] is! List ||
          x['correct_option_id'] == null ||
          x['unlock_order'] == null)
        throw const FormatException('Nepotpun zapis pitanja');
    }
  }

  Future<File> installAtomically(Uri manifestUri, {
    String contentPrefix = 'content',
    int? expectedGrade,
    String? expectedDatabaseId,
    String? minimumContentVersion,
    Directory? directory,
  }) async {
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(contentPrefix)) {
      throw const FormatException('Invalid content cache name');
    }
    final manifest = await fetchManifest(manifestUri);
    if (_olderThan(appVersion, manifest.minimumAppVersion))
      throw FormatException(
        'Baza zahteva aplikaciju ${manifest.minimumAppVersion} ili noviju',
      );
    if (manifest.schemaVersion != 1)
      throw const FormatException('Nepodržana schema_version');
    if (manifest.packages.length != 1)
      throw const FormatException('Očekuje se jedan paket');
    if (minimumContentVersion != null &&
        _olderThan(manifest.contentVersion, minimumContentVersion)) {
      throw const FormatException('Content downgrade rejected');
    }
    final bytes = await verifiedPackage(
      manifestUri.resolve('.'),
      manifest.packages.first,
    );
    final dir = directory ?? Directory(await getDatabasesPath());
    final package = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if ((expectedGrade != null && package['grade'] != expectedGrade) ||
        (expectedDatabaseId != null && package['database_id'] != expectedDatabaseId) ||
        package['content_version'] != manifest.contentVersion) {
      throw const FormatException('Wrong grade, database or content version');
    }
    final current = File(join(dir.path, '${contentPrefix}_current.json'));
    final temp = File(join(dir.path, '${contentPrefix}_next.tmp'));
    final backup = File(join(dir.path, '${contentPrefix}_previous.json'));
    if (await current.exists()) {
      try {
        final installed = jsonDecode(await current.readAsString());
        if (installed is Map && installed['content_version'] is String &&
            !_olderThan(installed['content_version'] as String, manifest.contentVersion)) {
          return current;
        }
      } catch (_) { /* replace a corrupt cache with verified content */ }
    }
    await temp.writeAsBytes(
      bytes,
      flush: true,
    ); // validacija i SHA su završeni pre zamene
    if (await current.exists()) {
      if (await backup.exists()) await backup.delete();
      await current.rename(backup.path);
    }
    try {
      await temp.rename(current.path);
    } catch (e) {
      if (await backup.exists() && !await current.exists())
        await backup.rename(current.path);
      rethrow;
    }
    return current;
  }
}
