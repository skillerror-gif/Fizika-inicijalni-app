import 'dart:math';

enum MasterLevel { basic, intermediate, advanced }

class TestQuestion {
  const TestQuestion({required this.id, required this.unlockOrder, required this.level, required this.nature, required this.representation, required this.subdomainId, required this.correctOptionId, required this.equivalenceGroup, required this.published, required this.scientificPass});
  final String id, nature, representation, subdomainId, correctOptionId, equivalenceGroup;
  final int unlockOrder;
  final MasterLevel level;
  final bool published, scientificPass;
}

class TestGenerationException implements Exception {
  TestGenerationException(this.reasons);
  final List<String> reasons;
  @override String toString() => 'Nedovoljan fond: ${reasons.join('; ')}';
}

class MasterTestGenerator {
  MasterTestGenerator({Random? random}) : _random = random ?? Random.secure();
  final Random _random;

  List<String> auditPool(Iterable<TestQuestion> all, int unlockOrder) {
    final q = _eligible(all, unlockOrder);
    final reasons = <String>[];
    int count(MasterLevel l) => q.where((x) => x.level == l).length;
    if (count(MasterLevel.basic) < 8) reasons.add('manje od 8 osnovnih');
    if (count(MasterLevel.intermediate) < 5) reasons.add('manje od 5 srednjih');
    if (count(MasterLevel.advanced) < 3) reasons.add('manje od 3 napredna');
    if (q.where((x) => x.nature == 'theory').length < 8) reasons.add('manje od 8 teorijskih');
    if (q.where((x) => x.nature == 'calculation').length < 8) reasons.add('manje od 8 računskih');
    if (q.where((x) => x.representation == 'graph').length < 2) reasons.add('manje od 2 grafička');
    if (q.where((x) => x.representation == 'table').isEmpty) reasons.add('nema tabelarnog');
    if (q.where((x) => x.representation == 'scheme').isEmpty) reasons.add('nema šematskog/eksperimentalnog');
    return reasons;
  }

  List<TestQuestion> generate(Iterable<TestQuestion> all, int unlockOrder) {
    final reasons = auditPool(all, unlockOrder);
    if (reasons.isNotEmpty) throw TestGenerationException(reasons);
    final pool = _eligible(all, unlockOrder)..shuffle(_random);
    const targets = {MasterLevel.basic: 8, MasterLevel.intermediate: 5, MasterLevel.advanced: 3};
    final chosen = <TestQuestion>[];
    for (final e in targets.entries) {
      final candidates = pool.where((q) => q.level == e.key && !chosen.any((c) => c.id == q.id)).toList()..shuffle(_random);
      chosen.addAll(candidates.take(e.value));
    }
    if (chosen.length != 16) throw TestGenerationException(['nije moguće sastaviti strukturu 8+5+3']);
    _repairNature(chosen, pool);
    _repairVisuals(chosen, pool);
    return _antiPatternOrder(chosen);
  }

  List<TestQuestion> _eligible(Iterable<TestQuestion> all, int unlockOrder) =>
      all.where((q) => q.published && q.scientificPass && q.unlockOrder <= unlockOrder).toList();

  void _repairNature(List<TestQuestion> chosen, List<TestQuestion> pool) {
    int theories() => chosen.where((q) => q.nature == 'theory').length;
    int calcs() => chosen.where((q) => q.nature == 'calculation').length;
    for (var guard = 0; guard < 100 && (theories() != 8 || calcs() != 8); guard++) {
      final need = theories() < 8 ? 'theory' : 'calculation';
      final excess = need == 'theory' ? 'calculation' : 'theory';
      final incoming = pool.where((q) => q.nature == need && !chosen.any((c) => c.id == q.id)).toList()..shuffle(_random);
      var changed = false;
      for (final x in incoming) {
        final i = chosen.indexWhere((c) => c.nature == excess && c.level == x.level);
        if (i >= 0) { chosen[i] = x; changed = true; break; }
      }
      if (!changed) break;
    }
    if (theories() != 8 || calcs() != 8) throw TestGenerationException(['nije moguće postići odnos 8 teorijskih : 8 računskih uz 8+5+3']);
  }

  void _repairVisuals(List<TestQuestion> chosen, List<TestQuestion> pool) {
    const needs = <String, int>{'graph': 2, 'table': 1, 'scheme': 1};
    for (final e in needs.entries) {
      while (chosen.where((q) => q.representation == e.key).length < e.value) {
        final incoming = pool.where((q) => q.representation == e.key && !chosen.any((c) => c.id == q.id)).toList()..shuffle(_random);
        if (incoming.isEmpty) throw TestGenerationException(['nedovoljan fond za ${e.key}']);
        final x = incoming.first;
        final i = chosen.indexWhere((c) => c.level == x.level && c.nature == x.nature && !needs.containsKey(c.representation));
        if (i < 0) throw TestGenerationException(['vizuelni zahtev nije moguće uklopiti bez kršenja 8+5+3 i 8:8']);
        chosen[i] = x;
      }
    }
  }

  List<TestQuestion> _antiPatternOrder(List<TestQuestion> source) {
    final remaining = [...source]..shuffle(_random);
    final out = <TestQuestion>[];
    while (remaining.isNotEmpty) {
      final valid = remaining.where((q) {
        if (out.length >= 2 && out[out.length - 1].subdomainId == q.subdomainId && out[out.length - 2].subdomainId == q.subdomainId) return false;
        if (out.length >= 2 && out[out.length - 1].correctOptionId == q.correctOptionId && out[out.length - 2].correctOptionId == q.correctOptionId) return false;
        if (out.isNotEmpty && out.last.equivalenceGroup == q.equivalenceGroup) return false;
        return true;
      }).toList();
      final candidates = valid.isNotEmpty ? valid : remaining;
      final pick = candidates[_random.nextInt(candidates.length)];
      out.add(pick);
      remaining.remove(pick);
    }
    return out;
  }
}