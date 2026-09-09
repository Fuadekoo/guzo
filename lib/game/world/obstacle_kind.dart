import '../../utils/constants.dart';

/// The obstacle types GUZO can place on the road.
///
/// Each kind is defined purely by its hitbox, and the *only* thing that makes
/// an obstacle jumpable or slideable is the geometry in [ObstacleSpec]. There
/// is no per-kind special case anywhere in the collision code.
enum ObstacleKind {
  /// Low and solid — hop over it, or step around it.
  rock,

  /// Wider than a rock but lower; easy to clear.
  log,

  /// Full height. No jump clears this, the runner has to change lane.
  barrier,

  /// Floats above the road with a gap underneath — slide through.
  hurdle,

  /// A pit in the road. Only clearable while airborne.
  hole,

  /// A barrier that patrols sideways as the runner approaches.
  movingBarrier,
}

/// The physical box an [ObstacleKind] occupies, in metres.
///
/// `bottom`/`top` are heights above the road, so a hurdle simply starts above
/// the runner's slide height and a hole simply extends below the surface.
class ObstacleSpec {
  const ObstacleSpec({
    required this.bottom,
    required this.top,
    required this.halfWidth,
    required this.halfDepth,
  });

  final double bottom;
  final double top;
  final double halfWidth;
  final double halfDepth;

  /// Whether a running jump can carry the runner over this box.
  bool get clearableByJump => bottom <= 0.01 && top < GuzoWorld.jumpPeakHeight;

  /// Whether sliding fits the runner under this box.
  bool get clearableBySlide => bottom >= GuzoWorld.slideHeight;
}

/// Lookup of every obstacle's geometry.
///
/// Sizing rule: `halfWidth + playerHalfWidth` must stay below [
/// GuzoWorld.laneWidth] so that stepping into the neighbouring lane is always
/// a clean escape. The widest box here is 0.9 m, and 0.9 + 0.45 = 1.35 < 2.0.
abstract final class ObstacleSpecs {
  static const Map<ObstacleKind, ObstacleSpec>
  _specs = <ObstacleKind, ObstacleSpec>{
    ObstacleKind.rock: ObstacleSpec(
      bottom: 0,
      top: 0.85,
      halfWidth: 0.7,
      halfDepth: 0.5,
    ),
    ObstacleKind.log: ObstacleSpec(
      bottom: 0,
      top: 0.6,
      halfWidth: 0.9,
      halfDepth: 0.4,
    ),
    ObstacleKind.barrier: ObstacleSpec(
      bottom: 0,
      top: 2.6,
      halfWidth: 0.75,
      halfDepth: 0.3,
    ),
    ObstacleKind.hurdle: ObstacleSpec(
      bottom: 1.0,
      top: 3.0,
      halfWidth: 0.9,
      halfDepth: 0.3,
    ),
    // Sits just proud of the surface so a runner with both feet down overlaps
    // it, while any airborne runner passes cleanly above.
    ObstacleKind.hole: ObstacleSpec(
      bottom: -3.0,
      top: 0.06,
      halfWidth: 0.85,
      halfDepth: 1.0,
    ),
    ObstacleKind.movingBarrier: ObstacleSpec(
      bottom: 0,
      top: 1.9,
      halfWidth: 0.6,
      halfDepth: 0.3,
    ),
  };

  static ObstacleSpec of(ObstacleKind kind) => _specs[kind]!;

  /// Kinds that only ever appear once the run has warmed up.
  static const List<ObstacleKind> easy = <ObstacleKind>[
    ObstacleKind.rock,
    ObstacleKind.log,
  ];

  static const List<ObstacleKind> medium = <ObstacleKind>[
    ObstacleKind.rock,
    ObstacleKind.log,
    ObstacleKind.barrier,
    ObstacleKind.hurdle,
  ];

  static const List<ObstacleKind> hard = <ObstacleKind>[
    ObstacleKind.rock,
    ObstacleKind.log,
    ObstacleKind.barrier,
    ObstacleKind.hurdle,
    ObstacleKind.hole,
    ObstacleKind.movingBarrier,
  ];
}

/// Decorative items placed beside the road. Never collidable.
enum SceneryKind { tree, bush, boulder, signpost }
