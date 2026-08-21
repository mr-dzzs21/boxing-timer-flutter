import 'dart:math';

import 'package:boxing_timer_flutter/core/combo_trainer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComboTrainer', () {
    test('nextCombo only returns known, non-empty combos', () {
      final ComboTrainer t = ComboTrainer(random: Random(1));
      for (int i = 0; i < 200; i++) {
        final List<int> combo = t.nextCombo();
        expect(combo, isNotEmpty);
        expect(ComboTrainer.combos, contains(combo));
        for (final int p in combo) {
          expect(ComboTrainer.punchNames.containsKey(p), isTrue);
        }
      }
    });

    test('nextDelaySeconds stays at or just above the chosen base', () {
      final ComboTrainer t = ComboTrainer(random: Random(7));
      for (int i = 0; i < 200; i++) {
        final int d = t.nextDelaySeconds(12);
        expect(d, inInclusiveRange(12, 14)); // base + 0..2 jitter
      }
    });

    test('phraseFor renders punch names, never numbers', () {
      expect(ComboTrainer.phraseFor(<int>[1, 2, 3]), 'Jab, Cross, Lead Hook');
      expect(ComboTrainer.phraseFor(<int>[1, 6]), 'Jab, Rear Uppercut');
    });

    test('a seeded Random makes the sequence deterministic', () {
      final ComboTrainer a = ComboTrainer(random: Random(42));
      final ComboTrainer b = ComboTrainer(random: Random(42));
      for (int i = 0; i < 20; i++) {
        expect(a.nextCombo(), b.nextCombo());
      }
    });
  });
}
