// Port of iOS TimerSessionEngineTests.swift, extended with cases for
// warmup == 0, skip semantics, wall-clock pause/resume, and finished state.

import 'package:flutter_test/flutter_test.dart';

import 'package:boxing_timer_flutter/core/models.dart';
import 'package:boxing_timer_flutter/core/timer_session_engine.dart';

void main() {
  final start = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime at(num seconds) =>
      start.add(Duration(milliseconds: (seconds * 1000).round()));

  FightPreset preset({
    int warmupSeconds = 5,
    int rounds = 2,
    int roundSeconds = 10,
    int restSeconds = 3,
  }) =>
      FightPreset(
        id: 'test',
        name: 'Test',
        warmupSeconds: warmupSeconds,
        rounds: rounds,
        roundSeconds: roundSeconds,
        restSeconds: restSeconds,
      );

  group('TimerSessionEngine (iOS test parity)', () {
    test('fight timer phase boundaries are exact', () {
      // warmup 5 | round1 10 | rest 3 | round2 10  => total 28
      final engine = TimerSessionEngine.fight(preset());
      engine.start(start);

      expect(engine.snapshot(start).phase, TimerPhase.warmup);
      expect(engine.snapshot(start).timeRemaining, 5);

      final firstRound = engine.snapshot(at(5));
      expect(firstRound.phase, TimerPhase.round);
      expect(firstRound.currentStep, 1);
      expect(firstRound.timeRemaining, 10);

      final rest = engine.snapshot(at(15));
      expect(rest.phase, TimerPhase.rest);
      expect(rest.timeRemaining, 3);

      final secondRound = engine.snapshot(at(18));
      expect(secondRound.phase, TimerPhase.round);
      expect(secondRound.currentStep, 2);
      expect(secondRound.timeRemaining, 10);

      final finished = engine.snapshot(at(28));
      expect(finished.phase, TimerPhase.finished);
      expect(finished.timeRemaining, 0);
      expect(finished.isFinished, isTrue);
    });

    test('pause and resume preserve remaining time', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 30, restSeconds: 0));
      engine.start(start);
      engine.pause(at(8));

      // While paused, wall-clock time must not affect the snapshot.
      expect(engine.snapshot(at(100)).timeRemaining, 22);

      engine.start(at(100));
      expect(engine.snapshot(at(105)).timeRemaining, 17);
    });

    test('interval timer skips zero-length warmup/rest/cooldown segments', () {
      const workout = IntervalWorkout(
        device: IntervalDevice.bagWork,
        level: IntervalLevel.intermediate,
        warmupSeconds: 0,
        intervals: 1,
        workSeconds: 20,
        restSeconds: 0,
        cooldownSeconds: 0,
      );
      final engine = TimerSessionEngine.interval(workout);
      engine.start(start);

      expect(engine.snapshot(start).phase, TimerPhase.round);
      expect(engine.snapshot(start).timeRemaining, 20);
      expect(engine.snapshot(at(20)).phase, TimerPhase.finished);
    });
  });

  group('warmup == 0', () {
    test('fight session starts directly with round 1', () {
      final engine = TimerSessionEngine.fight(preset(warmupSeconds: 0));
      engine.start(start);

      final snap = engine.snapshot(start);
      expect(snap.phase, TimerPhase.round);
      expect(snap.currentStep, 1);
      expect(snap.timeRemaining, 10);
      expect(snap.segmentIndex, 0);
    });

    test('interval session starts with work and keeps cooldown at the end', () {
      const workout = IntervalWorkout(
        device: IntervalDevice.airBike,
        level: IntervalLevel.beginner,
        warmupSeconds: 0,
        intervals: 2,
        workSeconds: 10,
        restSeconds: 5,
        cooldownSeconds: 7,
      );
      // work1 10 | rest 5 | work2 10 | cooldown 7 => total 32
      final engine = TimerSessionEngine.interval(workout);
      engine.start(start);

      expect(engine.snapshot(start).phase, TimerPhase.round);
      expect(engine.snapshot(start).currentStep, 1);
      expect(engine.snapshot(at(10)).phase, TimerPhase.rest);
      expect(engine.snapshot(at(15)).phase, TimerPhase.round);
      expect(engine.snapshot(at(15)).currentStep, 2);

      final cooldown = engine.snapshot(at(25));
      expect(cooldown.phase, TimerPhase.cooldown);
      expect(cooldown.timeRemaining, 7);
      expect(cooldown.currentStep, 2);

      expect(engine.snapshot(at(32)).isFinished, isTrue);
      expect(engine.totalDuration, 32);
    });
  });

  group('skip', () {
    test('skip jumps to the start of the next segment while running', () {
      // warmup 5 | round1 10 | rest 3 | round2 10
      final engine = TimerSessionEngine.fight(preset());
      engine.start(start);

      engine.skip(at(2)); // in warmup -> jump to round 1
      final round1 = engine.snapshot(at(2));
      expect(round1.phase, TimerPhase.round);
      expect(round1.currentStep, 1);
      // Wall-clock anchor is re-based: full round remains at the skip moment.
      expect(round1.timeRemaining, 10);
      expect(round1.elapsedSeconds, 5);

      engine.skip(at(4)); // 2s into round 1 -> jump to rest
      final rest = engine.snapshot(at(4));
      expect(rest.phase, TimerPhase.rest);
      expect(rest.timeRemaining, 3);

      engine.skip(at(4)); // rest -> round 2
      expect(engine.snapshot(at(4)).phase, TimerPhase.round);
      expect(engine.snapshot(at(4)).currentStep, 2);

      engine.skip(at(4)); // last segment -> finished
      final finished = engine.snapshot(at(4));
      expect(finished.isFinished, isTrue);
      expect(finished.phase, TimerPhase.finished);
    });

    test('skip while finished stays finished', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 5, restSeconds: 0));
      engine.start(start);
      expect(engine.snapshot(at(5)).isFinished, isTrue);

      engine.skip(at(6));
      expect(engine.snapshot(at(6)).isFinished, isTrue);
      expect(engine.snapshot(at(6)).timeRemaining, 0);
    });

    test('skip while paused advances without starting the clock', () {
      final engine = TimerSessionEngine.fight(preset());
      engine.start(start);
      engine.pause(at(2)); // paused 2s into warmup

      engine.skip(at(50)); // -> boundary of round 1
      final snap = engine.snapshot(at(500));
      expect(snap.phase, TimerPhase.round);
      expect(snap.currentStep, 1);
      expect(snap.timeRemaining, 10);
      expect(engine.isRunning, isFalse);
    });

    test('skip while idle (never started) advances to the next segment', () {
      final engine = TimerSessionEngine.fight(preset());
      engine.skip(start);

      final snap = engine.snapshot(at(999));
      expect(snap.phase, TimerPhase.round);
      expect(snap.timeRemaining, 10);
      expect(engine.isRunning, isFalse);
    });
  });

  group('pause / resume wall-clock correctness', () {
    test('start is a no-op while already running', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 30, restSeconds: 0));
      engine.start(start);
      engine.start(at(10)); // must NOT re-anchor the clock
      expect(engine.snapshot(at(12)).timeRemaining, 18);
    });

    test('fractional elapsed time is preserved across pause/resume', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 30, restSeconds: 0));
      engine.start(start);
      engine.pause(at(8.4)); // elapsedBeforeRun = 8.4s -> floor 8

      expect(engine.snapshot(at(100)).timeRemaining, 22);

      engine.start(at(100));
      // 8.4 + 0.7 = 9.1 -> floor 9 -> remaining 21
      expect(engine.snapshot(at(100.7)).timeRemaining, 21);
      // 8.4 + 5 = 13.4 -> floor 13 -> remaining 17
      expect(engine.snapshot(at(105)).timeRemaining, 17);
    });

    test('multiple pause/resume cycles accumulate correctly', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 60, restSeconds: 0));
      engine.start(start);
      engine.pause(at(10)); // elapsed 10
      engine.start(at(30));
      engine.pause(at(35)); // elapsed 15
      engine.start(at(1000));
      expect(engine.snapshot(at(1005)).timeRemaining, 40); // elapsed 20
      expect(engine.snapshot(at(1005)).elapsedSeconds, 20);
    });

    test('snapshot before the start anchor clamps to zero elapsed', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 30, restSeconds: 0));
      engine.start(at(10));
      final snap = engine.snapshot(at(5)); // clock earlier than anchor
      expect(snap.timeRemaining, 30);
      expect(snap.elapsedSeconds, 0);
    });

    test('reset returns to the initial state', () {
      final engine = TimerSessionEngine.fight(preset());
      engine.start(start);
      engine.pause(at(12));
      engine.reset();

      final snap = engine.snapshot(at(999));
      expect(snap.phase, TimerPhase.warmup);
      expect(snap.timeRemaining, 5);
      expect(snap.elapsedSeconds, 0);
      expect(engine.isRunning, isFalse);
    });
  });

  group('finished state', () {
    test('finished snapshot fields and clamping past the end', () {
      final engine = TimerSessionEngine.fight(preset()); // total 28
      engine.start(start);

      for (final t in [28, 29, 10000]) {
        final snap = engine.snapshot(at(t));
        expect(snap.phase, TimerPhase.finished);
        expect(snap.isFinished, isTrue);
        expect(snap.timeRemaining, 0);
        expect(snap.elapsedSeconds, 28);
        expect(snap.progress, 1);
        expect(snap.currentStep, 2);
        expect(snap.totalSteps, 2);
        expect(snap.segmentIndex, 4); // one past the last segment
      }
    });

    test('progress runs 0 -> 1 inside a segment', () {
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 0, rounds: 1, roundSeconds: 10, restSeconds: 0));
      engine.start(start);
      expect(engine.snapshot(start).progress, 0);
      expect(engine.snapshot(at(5)).progress, closeTo(0.5, 1e-9));
      expect(engine.snapshot(at(9)).progress, closeTo(0.9, 1e-9));
      expect(engine.snapshot(at(10)).progress, 1);
    });

    test('single round without rest has no rest segment', () {
      // BJJ-style preset: warmup 10, 1 round, rest 0.
      final engine = TimerSessionEngine.fight(
          preset(warmupSeconds: 10, rounds: 1, roundSeconds: 300, restSeconds: 0));
      engine.start(start);
      expect(engine.totalDuration, 310);
      expect(engine.snapshot(at(9)).phase, TimerPhase.warmup);
      expect(engine.snapshot(at(10)).phase, TimerPhase.round);
      expect(engine.snapshot(at(310)).isFinished, isTrue);
    });
  });

  group('model parity with iOS', () {
    test('default fight presets match ModelsAndStubs.swift exactly', () {
      final p = FightPreset.defaultPresets;
      expect(p.length, 8);

      List<int> v(FightPreset x) =>
          [x.warmupSeconds, x.rounds, x.roundSeconds, x.restSeconds];

      expect(p[0].name, '🥊 Boxen');
      expect(v(p[0]), [5, 12, 180, 60]);
      expect(p[1].name, '🥋 MMA');
      expect(v(p[1]), [5, 3, 300, 60]);
      expect(p[2].name, '🦵 K1');
      expect(v(p[2]), [5, 3, 180, 60]);
      expect(p[3].name, '🇹🇭 Muay Thai');
      expect(v(p[3]), [5, 5, 180, 120]);
      expect(p[4].name, '🤼 BJJ');
      expect(v(p[4]), [10, 1, 300, 0]);
      expect(p[5].name, '🥋 Judo');
      expect(v(p[5]), [10, 1, 240, 0]);
      expect(p[6].name, '🤼 Ringen');
      expect(v(p[6]), [10, 3, 120, 30]);
      expect(p[7].name, '🥋 Taekwondo');
      expect(v(p[7]), [5, 3, 120, 60]);
    });

    test('interval workout matrix matches ModelsAndStubs.swift exactly', () {
      List<int> v(IntervalDevice d, IntervalLevel l) {
        final w = IntervalWorkout.workoutFor(d, l);
        return [
          w.warmupSeconds,
          w.intervals,
          w.workSeconds,
          w.restSeconds,
          w.cooldownSeconds,
        ];
      }

      const running = IntervalDevice.running;
      const treadmill = IntervalDevice.treadmill;
      const airBike = IntervalDevice.airBike;
      const bagWork = IntervalDevice.bagWork;
      const beginner = IntervalLevel.beginner;
      const intermediate = IntervalLevel.intermediate;
      const advanced = IntervalLevel.advanced;

      expect(v(running, beginner), [300, 8, 30, 60, 180]);
      expect(v(running, intermediate), [300, 10, 45, 60, 180]);
      expect(v(running, advanced), [360, 12, 60, 60, 240]);

      expect(v(treadmill, beginner), [300, 8, 30, 60, 180]);
      expect(v(treadmill, intermediate), [300, 10, 45, 60, 180]);
      expect(v(treadmill, advanced), [360, 15, 60, 60, 240]);

      expect(v(airBike, beginner), [180, 6, 20, 60, 120]);
      expect(v(airBike, intermediate), [240, 10, 30, 60, 180]);
      expect(v(airBike, advanced), [300, 15, 40, 50, 240]);

      expect(v(bagWork, beginner), [180, 6, 30, 60, 120]);
      expect(v(bagWork, intermediate), [240, 10, 45, 50, 180]);
      expect(v(bagWork, advanced), [300, 15, 90, 40, 240]);
    });
  });
}
