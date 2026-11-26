/// One of the three supported machines (Diseño §12.1, `exercise`).
enum Exercise {
  legPress45('LEG_PRESS_45'),
  latPulldown('LAT_PULLDOWN'),
  legExtension('LEG_EXTENSION');

  const Exercise(this.code);

  /// The value used in routes, the native channel, the database and the API.
  final String code;

  /// The exercise with [code], or null if no exercise has it.
  static Exercise? fromCode(String code) {
    for (final exercise in values) {
      if (exercise.code == code) return exercise;
    }
    return null;
  }
}
