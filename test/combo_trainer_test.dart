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
        // every punch is a valid 1–6 number
        for (final int p in combo) {
          expect(ComboTrainer.punchNames.containsKey(p), isTrue);
        }
      }
    });

    test('nextDelaySeconds stays within the requested range', () {
      final ComboTrainer t = ComboTrainer(random: Random(7));
      for (int i = 0; i < 200; i++) {
        final int d = t.nextDelaySeconds(min: 8, max: 16);
        expect(d, inInclusiveRange(8, 16));
      }
    });

    test('phraseFor renders numbers by default', () {
      expect(
        ComboTrainer.phraseFor(<int>[1, 2, 3], useNames: false),
        '1 2 3',
      );
    });

    test('phraseFor renders punch names when requested', () {
      expect(
        ComboTrainer.phraseFor(<int>[1, 2, 3], useNames: true),
        'Jab, Cross, Lead Hook',
      );
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
