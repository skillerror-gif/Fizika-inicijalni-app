import 'dart:math';

enum MasterLevel { basic, intermediate, advanced }

class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.unlockOrder,
    required this.level,
    required this.nature,
    required this.representation,
    required this.subdomainId,
    required this.correctOptionId,
    required this.equivalenceGroup,
    required this.published,
    required this.scientificPass,
  });
  final String id,
      nature,
      representation,
      subdomainId,
      correctOptionId,
      equivalenceGroup;
  final int unlockOrder;
  final MasterLevel level;
  final bool published, scientificPass;
}

class TestGenerationException implements Exception {
  TestGenerationException(this.reasons);
  final List<String> reasons;
  @override
  String toString() => 'Nedovoljan fond: ${reasons.join('; ')}';
}

class MasterTestGenerator {
  MasterTestGenerator({Random? random}) : _random = random ?? Random.secure();
  final Random _random;
  List<TestQuestion> _eligible(Iterable<TestQuestion> all, int unlock) => all
      .where((q) => q.published && q.scientificPass && q.unlockOrder <= unlock)
      .toList();
  List<String> auditPool(Iterable<TestQuestion> all, int unlock) {
    final q = _eligible(all, unlock), r = <String>[];
    int n(MasterLevel l) => q.where((x) => x.level == l).length;
    if (n(MasterLevel.basic) < 8) r.add('manje od 8 osnovnih');
    if (n(MasterLevel.intermediate) < 5) r.add('manje od 5 srednjih');
    if (n(MasterLevel.advanced) < 3) r.add('manje od 3 napredna');
    if (q.where((x) => x.nature == 'theory').length < 7)
      r.add('manje od 7 teorijskih');
    if (q.where((x) => x.nature == 'calculation').length < 7)
      r.add('manje od 7 računskih');
    if (q.where((x) => x.representation == 'graph').length < 2)
      r.add('manje od 2 grafička');
    if (q.where((x) => x.representation == 'table').isEmpty)
      r.add('nema tabelarnog');
    if (q.where((x) => x.representation == 'scheme').isEmpty)
      r.add('nema šematskog');
    return r;
  }

  List<TestQuestion> generate(Iterable<TestQuestion> all, int unlock) {
    final audit = auditPool(all, unlock);
    if (audit.isNotEmpty) throw TestGenerationException(audit);
    final eligible = _eligible(all, unlock);
    TestGenerationException? last;
    for (var attempt = 0; attempt < 250; attempt++) {
      final pool = [...eligible]..shuffle(_random);
      final chosen = <TestQuestion>[];
      for (final e in const {
        MasterLevel.basic: 8,
        MasterLevel.intermediate: 5,
        MasterLevel.advanced: 3,
      }.entries) {
        final c = pool
            .where(
              (q) => q.level == e.key && !chosen.any((x) => x.id == q.id),
            )
            .toList()
          ..shuffle(_random);
        chosen.addAll(c.take(e.value));
      }
      if (chosen.length != 16) {
        last = TestGenerationException(['nije moguće sastaviti 8+5+3']);
        continue;
      }
      try {
        _repairNature(chosen, pool);
        _repairVisuals(chosen, pool);
        _repairAnswers(chosen, pool);
        _repairCoverage(chosen, pool);
        return _antiPattern(chosen);
      } on TestGenerationException catch (e) {
        last = e;
      }
    }
    throw TestGenerationException([
      'nije pronađena validna MASTER kombinacija posle 250 pokušaja',
      ...?last?.reasons,
    ]);
  }

  List<TestQuestion> generateConfigured(
    Iterable<TestQuestion> all,
    int unlock, {
    required int count,
    String focus = 'mixed',
  }) {
    if (count < 5 || count > 20) {
      throw TestGenerationException(['broj pitanja mora biti od 5 do 20']);
    }
    var eligible = _eligible(all, unlock);
    if (focus != 'mixed') {
      eligible = eligible.where((q) => q.nature == focus).toList();
    }
    if (eligible.length < count) {
      throw TestGenerationException(['nedovoljan broj pitanja za izabrane kriterijume']);
    }

    final basicTarget = (count * 0.5).round();
    final advancedTarget = (count * 0.1875).round();
    final intermediateTarget = count - basicTarget - advancedTarget;
    final targets = <MasterLevel, int>{
      MasterLevel.basic: basicTarget,
      MasterLevel.intermediate: intermediateTarget,
      MasterLevel.advanced: advancedTarget,
    };

    for (final entry in targets.entries) {
      if (eligible.where((q) => q.level == entry.key).length < entry.value) {
        throw TestGenerationException([
          'nedovoljan fond za MASTER raspodelu nivoa',
        ]);
      }
    }

    for (var attempt = 0; attempt < 250; attempt++) {
      final pool = [...eligible]..shuffle(_random);
      final chosen = <TestQuestion>[];
      for (final entry in targets.entries) {
        chosen.addAll(
          pool
              .where(
                (q) =>
                    q.level == entry.key &&
                    !chosen.any((selected) => selected.id == q.id),
              )
              .take(entry.value),
        );
      }
      if (chosen.length != count) continue;
      if (focus == 'mixed') {
        final theory = chosen.where((q) => q.nature == 'theory').length;
        final lower = (count * 0.45).floor();
        final upper = (count * 0.55).ceil();
        if (theory < lower || theory > upper) continue;
      }
      try {
        return _antiPattern(chosen);
      } on TestGenerationException {
        continue;
      }
    }
    throw TestGenerationException([
      'nije pronađena validna MASTER kombinacija za izabrane kriterijume',
    ]);
  }

  bool _validNature(List<TestQuestion> q) {
    final t = q.where((x) => x.nature == 'theory').length,
        c = q.where((x) => x.nature == 'calculation').length;
    return t >= 7 && t <= 9 && c >= 7 && c <= 9;
  }

  void _repairNature(List<TestQuestion> q, List<TestQuestion> pool) {
    for (var g = 0; g < 100 && !_validNature(q); g++) {
      final t = q.where((x) => x.nature == 'theory').length;
      final need = t < 7 ? 'theory' : 'calculation',
          ex = need == 'theory' ? 'calculation' : 'theory';
      final incoming = pool
          .where((x) => x.nature == need && !q.any((c) => c.id == x.id))
          .toList()
        ..shuffle(_random);
      var ok = false;
      for (final x in incoming) {
        final i = q.indexWhere((c) => c.nature == ex && c.level == x.level);
        if (i >= 0) {
          q[i] = x;
          ok = true;
          break;
        }
      }
      if (!ok) break;
    }
    if (!_validNature(q))
      throw TestGenerationException([
        'nije moguće postići dozvoljeni odnos teorija/račun 45:55–55:45',
      ]);
  }

  void _repairVisuals(List<TestQuestion> q, List<TestQuestion> pool) {
    for (final e in const {'graph': 2, 'table': 1, 'scheme': 1}.entries) {
      while (q.where((x) => x.representation == e.key).length < e.value) {
        final inc = pool
            .where(
              (x) => x.representation == e.key && !q.any((c) => c.id == x.id),
            )
            .toList()
          ..shuffle(_random);
        if (inc.isEmpty)
          throw TestGenerationException(['nedovoljan fond za ${e.key}']);
        final x = inc.first;
        final i = q.indexWhere(
          (c) =>
              c.level == x.level &&
              c.nature == x.nature &&
              !const {'graph', 'table', 'scheme'}.contains(c.representation),
        );
        if (i < 0)
          throw TestGenerationException([
            'vizuelni zahtev se ne može uklopiti',
          ]);
        q[i] = x;
      }
    }
  }

  void _repairAnswers(List<TestQuestion> q, List<TestQuestion> pool) {
    int cnt(String a) => q.where((x) => x.correctOptionId == a).length;
    final letters = ['A', 'B', 'V', 'G'];
    bool acceptable() => letters.every((a) => cnt(a) >= 2 && cnt(a) <= 6);
    for (var g = 0; g < 200 && !acceptable(); g++) {
      final over = letters.where((a) => cnt(a) > 6).toList(),
          under = letters.where((a) => cnt(a) < 2).toList();
      final want = under.isNotEmpty
          ? under.first
          : letters.reduce((a, b) => cnt(a) <= cnt(b) ? a : b);
      final inc = pool
          .where(
            (x) => x.correctOptionId == want && !q.any((c) => c.id == x.id),
          )
          .toList()
        ..shuffle(_random);
      var changed = false;
      for (final x in inc) {
        final i = q.indexWhere(
          (c) =>
              (over.isEmpty || over.contains(c.correctOptionId)) &&
              c.level == x.level &&
              c.nature == x.nature &&
              c.representation == x.representation,
        );
        if (i >= 0) {
          q[i] = x;
          changed = true;
          break;
        }
      }
      if (!changed) break;
    }
    if (!acceptable())
      throw TestGenerationException([
        'nije moguće sprečiti izrazitu dominaciju jednog ponuđenog odgovora bez kršenja ostalih uslova',
      ]);
  }

  void _repairCoverage(List<TestQuestion> q, List<TestQuestion> pool) {
    final domains = pool.map((x) => x.subdomainId).toSet();
    for (final d in domains) {
      if (q.any((x) => x.subdomainId == d)) continue;
      final inc = pool
          .where((x) => x.subdomainId == d && !q.any((c) => c.id == x.id))
          .toList()
        ..shuffle(_random);
      var changed = false;
      for (final x in inc) {
        final counts = <String, int>{};
        for (final z in q) {
          counts[z.subdomainId] = (counts[z.subdomainId] ?? 0) + 1;
        }
        final i = q.indexWhere(
          (c) =>
              (counts[c.subdomainId] ?? 0) > 1 &&
              c.level == x.level &&
              c.nature == x.nature &&
              c.representation == x.representation &&
              c.correctOptionId == x.correctOptionId,
        );
        if (i >= 0) {
          q[i] = x;
          changed = true;
          break;
        }
      }
      if (!changed)
        throw TestGenerationException([
          'nije moguće reprezentativno pokriti sve izabrane oblasti',
        ]);
    }
  }

  List<TestQuestion> _antiPattern(List<TestQuestion> src) {
    for (var attempt = 0; attempt < 50; attempt++) {
      final rem = [...src]..shuffle(_random), out = <TestQuestion>[];
      while (rem.isNotEmpty) {
        final n = out.length;
        final valid = rem
            .where(
              (q) =>
                  !(n >= 2 &&
                      out[n - 1].subdomainId == q.subdomainId &&
                      out[n - 2].subdomainId == q.subdomainId) &&
                  !(n >= 2 &&
                      out[n - 1].correctOptionId == q.correctOptionId &&
                      out[n - 2].correctOptionId == q.correctOptionId) &&
                  !(n >= 4 &&
                      out[n - 4].correctOptionId == q.correctOptionId &&
                      out[n - 2].correctOptionId == q.correctOptionId &&
                      out[n - 3].correctOptionId ==
                          out[n - 1].correctOptionId) &&
                  !(out.isNotEmpty &&
                      out.last.equivalenceGroup.isNotEmpty &&
                      out.last.equivalenceGroup == q.equivalenceGroup),
            )
            .toList();
        if (valid.isEmpty) break;
        final p = valid[_random.nextInt(valid.length)];
        out.add(p);
        rem.remove(p);
      }
      if (rem.isEmpty) return out;
    }
    throw TestGenerationException([
      'nije moguće poređati zadatke bez ponavljajućeg obrasca odgovora',
    ]);
  }
}
