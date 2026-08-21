import 'dart:math';

/// Generates random boxing punch combinations for the Combo Trainer feature.
///
/// Pure logic with no Flutter/plugin dependencies, and deterministic when
/// given a seeded [Random] — so it is unit-testable. The controller feeds the
/// spoken phrase to `SoundManager.speakCombo`.
class ComboTrainer {
  ComboTrainer({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Standard boxing punch numbering (1–6) → English names.
  static const Map<int, String> punchNames = <int, String>{
    1: 'Jab',
    2: 'Cross',
    3: 'Lead Hook',
    4: 'Rear Hook',
    5: 'Lead Uppercut',
    6: 'Rear Uppercut',
  };

  /// Common combinations expressed as punch numbers.
  static const List<List<int>> combos = <List<int>>[
    <int>[1, 2],
    <int>[1, 1, 2],
    <int>[1, 2, 3],
    <int>[1, 2, 3, 2],
    <int>[2, 3, 2],
    <int>[1, 6],
    <int>[3, 2],
    <int>[1, 2, 5, 2],
    <int>[1, 1],
    <int>[1, 2, 3, 6],
    <int>[6, 3, 2],
    <int>[1, 4],
  ];

  /// A random combination as a list of punch numbers.
  List<int> nextCombo() => combos[_random.nextInt(combos.length)];

  /// Seconds to wait before the next combo, randomized within [min, max].
  int nextDelaySeconds({int min = 8, int max = 16}) =>
      min + _random.nextInt(max - min + 1);

  /// Spoken phrase for [combo]. [useNames] picks "Jab, Cross, Lead Hook" over
  /// the numeric "1 2 3". Always English, matching the round announcements.
  static String phraseFor(List<int> combo, {required bool useNames}) {
    if (useNames) {
      return combo.map((int n) => punchNames[n] ?? '$n').join(', ');
    }
    return combo.join(' ');
  }
}
