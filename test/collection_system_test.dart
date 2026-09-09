import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/education/sequence_definition.dart';
import 'package:guzo/education/sequence_tracker.dart';
import 'package:guzo/game/player/player_controller.dart';
import 'package:guzo/game/systems/collection_system.dart';
import 'package:guzo/game/world/collectible.dart';
import 'package:guzo/utils/constants.dart';

const double _playerZ = 100.0;

SequenceDefinition _abc([List<String>? items]) => SequenceDefinition(
  id: 'test',
  name: 'Test',
  shortName: 'T',
  category: SequenceCategory.englishLetters,
  items: items ?? const <String>['A', 'B', 'C', 'D', 'E'],
);

Collectible _tile(
  CollectibleRole role, {
  int lane = 0,
  int id = 1,
  double? height,
  int decoySeed = 0,
  double? worldZ,
}) => Collectible(
  id: id,
  worldZ: worldZ ?? _playerZ,
  lane: lane,
  role: role,
  height: height ?? GuzoCollectibles.lowHeight,
  decoySeed: decoySeed,
);

void _advance(PlayerController player, double seconds) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    player.update(step, 0);
  }
}

void main() {
  late CollectionSystem collection;
  late PlayerController player;
  late SequenceTracker tracker;

  setUp(() {
    collection = CollectionSystem();
    player = PlayerController();
    tracker = SequenceTracker(_abc());
  });

  List<CollectionEvent> collect(List<Collectible> tiles) =>
      collection.collect(player, tiles, tracker, _playerZ);

  group('Role resolution', () {
    test('a target tile shows what the player needs right now', () {
      expect(_tile(CollectibleRole.target).valueFor(tracker), 'A');

      tracker.offer('A');
      expect(_tile(CollectibleRole.target).valueFor(tracker), 'B');
    });

    test('an ahead tile shows the next item — the brief\'s D-for-C trap', () {
      tracker
        ..offer('A')
        ..offer('B');
      expect(tracker.currentTarget, 'C');

      expect(_tile(CollectibleRole.ahead).valueFor(tracker), 'D');
    });

    test('a decoy never resolves to the current target', () {
      // A decoy that showed the target would be a free pickup dressed as a
      // trap, so every seed must miss.
      for (int seed = 0; seed < 400; seed++) {
        final SequenceTracker fresh = SequenceTracker(_abc());
        for (int collected = 0; collected < 4; collected++) {
          final String? value = _tile(
            CollectibleRole.decoy,
            decoySeed: seed,
          ).valueFor(fresh);

          expect(value, isNotNull);
          expect(
            value,
            isNot(fresh.currentTarget),
            reason: 'seed $seed at index $collected showed the target',
          );

          fresh.offer(fresh.currentTarget!);
        }
      }
    });

    test('a decoy always shows a real item from the sequence', () {
      final SequenceDefinition definition = _abc();
      for (int seed = 0; seed < 100; seed++) {
        expect(
          definition.items,
          contains(
            _tile(CollectibleRole.decoy, decoySeed: seed).valueFor(tracker),
          ),
        );
      }
    });

    test('every tile stops showing anything once the sequence is done', () {
      final SequenceTracker done =
          SequenceTracker(_abc(const <String>['A', 'B']))
            ..offer('A')
            ..offer('B');

      for (final CollectibleRole role in CollectibleRole.values) {
        expect(_tile(role).valueFor(done), isNull);
      }
    });
  });

  group('Picking up', () {
    test('touching the target advances the sequence', () {
      final List<CollectionEvent> events = collect(<Collectible>[
        _tile(CollectibleRole.target),
      ]);

      expect(events, hasLength(1));
      expect(events.single.value, 'A');
      expect(events.single.isCorrect, isTrue);
      expect(tracker.currentTarget, 'B');
    });

    test('touching a wrong tile reports it and changes nothing', () {
      final List<CollectionEvent> events = collect(<Collectible>[
        _tile(CollectibleRole.ahead),
      ]);

      expect(events, hasLength(1));
      expect(events.single.value, 'B');
      expect(events.single.isCorrect, isFalse);
      expect(tracker.currentTarget, 'A');
      expect(tracker.collectedCount, 0);
    });

    test('a tile in another lane is missed', () {
      player
        ..moveLeft()
        ..update(0.5, 0);

      expect(collect(<Collectible>[_tile(CollectibleRole.target)]), isEmpty);
      expect(tracker.currentTarget, 'A');
    });

    test('a tile far down the track is not yet reachable', () {
      expect(
        collect(<Collectible>[
          _tile(CollectibleRole.target, worldZ: _playerZ + 20),
        ]),
        isEmpty,
      );
    });

    test('the same tile cannot be collected twice', () {
      final List<Collectible> tiles = <Collectible>[
        _tile(CollectibleRole.target),
      ];

      expect(collect(tiles), hasLength(1));
      expect(collect(tiles), isEmpty);
      expect(tracker.collectedCount, 1);
    });

    test('a consumed tile reports itself so the painter can drop it', () {
      final Collectible tile = _tile(CollectibleRole.target);
      expect(collection.isConsumed(tile), isFalse);

      collect(<Collectible>[tile]);
      expect(collection.isConsumed(tile), isTrue);
    });
  });

  group('Height', () {
    test('a raised tile is out of reach on foot', () {
      final Collectible high = _tile(
        CollectibleRole.target,
        height: GuzoCollectibles.highHeight,
      );
      expect(high.requiresJump, isTrue);

      expect(collect(<Collectible>[high]), isEmpty);
    });

    test('a jump reaches a raised tile', () {
      player.jump();
      _advance(player, 0.15);

      expect(
        collect(<Collectible>[
          _tile(CollectibleRole.target, height: GuzoCollectibles.highHeight),
        ]),
        hasLength(1),
      );
    });

    test('a low tile is reachable while sliding', () {
      player.slide();

      expect(
        collect(<Collectible>[_tile(CollectibleRole.target)]),
        hasLength(1),
      );
    });
  });

  group('Completion', () {
    test('the last item reports the sequence finished', () {
      final SequenceTracker shortRun = SequenceTracker(
        _abc(const <String>['A', 'B']),
      )..offer('A');

      final List<CollectionEvent> events = collection.collect(
        player,
        <Collectible>[_tile(CollectibleRole.target)],
        shortRun,
        _playerZ,
      );

      expect(events.single.finishedSequence, isTrue);
      expect(shortRun.isComplete, isTrue);
    });

    test('a completed run collects nothing more', () {
      final SequenceTracker done =
          SequenceTracker(_abc(const <String>['A', 'B']))
            ..offer('A')
            ..offer('B');

      expect(
        collection.collect(
          player,
          <Collectible>[_tile(CollectibleRole.target)],
          done,
          _playerZ,
        ),
        isEmpty,
      );
    });

    test('two tiles in one frame stop at the one that finishes the run', () {
      final SequenceTracker shortRun = SequenceTracker(
        _abc(const <String>['A', 'B']),
      )..offer('A');

      final List<CollectionEvent> events = collection.collect(
        player,
        <Collectible>[
          _tile(CollectibleRole.target, id: 1),
          _tile(CollectibleRole.decoy, id: 2),
        ],
        shortRun,
        _playerZ,
      );

      expect(events, hasLength(1));
      expect(events.single.finishedSequence, isTrue);
    });
  });

  group('Reset', () {
    test('clears the consumed set so tiles can be collected again', () {
      final List<Collectible> tiles = <Collectible>[
        _tile(CollectibleRole.target),
      ];
      collect(tiles);

      collection.reset();
      tracker.reset();

      expect(collect(tiles), hasLength(1));
      expect(collection.consumedCount, 1);
    });
  });
}
