/// A body joint named without its side (ADR-0012), as the rules file and the `framing` event
/// name it. Mirrors Kotlin's `Joint`.
enum Joint {
  shoulder('shoulder'),
  elbow('elbow'),
  wrist('wrist'),
  hip('hip'),
  knee('knee'),
  ankle('ankle');

  const Joint(this.code);

  /// The name in the rules file and the native channel.
  final String code;

  static Joint? fromCode(String code) {
    for (final joint in values) {
      if (joint.code == code) return joint;
    }
    return null;
  }
}

/// A side of the body, from the user's point of view; the measured side is one of them.
enum Side {
  left('left'),
  right('right');

  const Side(this.code);

  final String code;

  static Side? fromCode(String? code) {
    for (final side in values) {
      if (side.code == code) return side;
    }
    return null;
  }
}
