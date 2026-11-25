import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fizika_adaptivno_vezbanje/data/content_update_service.dart';

void main() {
  late Directory dir;
  setUp(() async { dir = await Directory.systemTemp.createTemp('fizika-g3-test-'); });
  tearDown(() async { await dir.delete(recursive: true); });
  Future<ContentUpdateService> service({bool tamper = false, int grade = 3, String version = '3.2.0'}) async {
    final package = jsonDecode(File('assets/content/g3_fizika_3.2.0.json').readAsStringSync()) as Map<String, dynamic>;
    package['grade'] = grade; package['content_version'] = version;
    final bytes = utf8.encode(jsonEncode(package));
    final hash = (await Sha256().hash(bytes)).bytes.map((b) => b.toRadixString(16).padLeft(2,'0')).join();
    final manifest = jsonEncode({'content_version': version, 'schema_version':1, 'minimum_app_version':'0.1.2','packages':[{'file':'g3.json','sha256':hash,'question_count':156}]});
    return ContentUpdateService(MockClient((uri) async => http.Response.bytes(
      uri.url.path.endsWith('manifest.json') ? utf8.encode(manifest) : (tamper ? [...bytes,32] : bytes), 200,
      headers: {'content-type':'application/json; charset=utf-8'},
    )), appVersion:'0.1.2');
  }
  final manifestUri = Uri.parse('https://example.test/manifest.json');
  Future<File> install(ContentUpdateService s) => s.installAtomically(manifestUri, directory:dir, contentPrefix:'content_g3',expectedGrade:3,expectedDatabaseId:'fizika-app-g3-mag',minimumContentVersion:'3.2.0');
  test('grade III update preserves grade I cache and progress files', () async {
    final old = File('${dir.path}/content_current.json'); await old.writeAsString('grade I');
    final progress = File('${dir.path}/fizika_progress_v1.db'); await progress.writeAsString('progress sentinel');
    final installed = await install(await service());
    expect((jsonDecode(await installed.readAsString()) as Map)['questions'].length, 156);
    expect(await old.readAsString(),'grade I');
    expect(await progress.readAsString(),'progress sentinel');
  });
  test('tampered package and wrong grade cannot replace last valid cache', () async {
    final valid = await install(await service()); final before = await valid.readAsString();
    await expectLater(install(await service(tamper:true)),throwsFormatException);
    expect(await valid.readAsString(),before);
    await expectLater(install(await service(grade:1)),throwsFormatException);
    expect(await valid.readAsString(),before);
  });
  test('remote downgrade cannot replace valid content', () async {
    final valid = await install(await service()); final before = await valid.readAsString();
    await expectLater(install(await service(version:'3.1.0')),throwsFormatException);
    expect(await valid.readAsString(),before);
  });
}
