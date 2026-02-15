/// Chord transposition utility for music key changes.
/// Handles standard chromatic scale: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
class ChordTransposer {
  static const List<String> _sharpNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const List<String> _flatNotes = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  // Map flat notes to sharp equivalents for normalization
  static const Map<String, String> _flatToSharp = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  /// All valid key names (both sharp and flat)
  static const List<String> allKeys = [
    'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F',
    'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B'
  ];

  /// Standard keys commonly used in worship music
  static const List<String> commonKeys = [
    'C', 'D', 'E', 'F', 'G', 'A', 'B',
    'Db', 'Eb', 'Gb', 'Ab', 'Bb',
  ];

  /// Calculate the number of semitones between two keys.
  static int getSemitoneDistance(String fromKey, String toKey) {
    final fromIndex = _getNoteIndex(fromKey);
    final toIndex = _getNoteIndex(toKey);
    if (fromIndex == -1 || toIndex == -1) return 0;
    return (toIndex - fromIndex + 12) % 12;
  }

  /// Transpose a single chord by a number of semitones.
  /// Handles: major (C), minor (Am), 7th (G7), major 7 (Cmaj7),
  /// sus (Dsus4), slash chords (C/E), etc.
  static String transposeChord(String chord, int semitones) {
    if (chord.trim().isEmpty) return chord;
    if (semitones == 0) return chord;

    // Handle slash chords (e.g., C/E)
    final slashParts = chord.split('/');
    if (slashParts.length == 2) {
      final root = _transposeRoot(slashParts[0], semitones);
      final bass = _transposeRoot(slashParts[1], semitones);
      return '$root/$bass';
    }

    return _transposeRoot(chord, semitones);
  }

  /// Transpose a chord string that may contain multiple chords.
  /// Chords can be separated by spaces, dashes, pipes, or other delimiters.
  static String transposeLine(String line, int semitones) {
    if (semitones == 0) return line;

    // Match chord patterns: optional root note + optional quality suffix
    // Pattern matches: C, C#, Cb, Cm, C#m, Cmaj7, Csus4, C/E, C#m7/B, etc.
    final chordPattern = RegExp(
      r'([A-G][#b]?)(m(?:aj|in)?|dim|aug|sus[24]?|add)?(\d+)?(/[A-G][#b]?)?',
    );

    return line.replaceAllMapped(chordPattern, (match) {
      final fullMatch = match.group(0)!;
      if (fullMatch.isEmpty) return fullMatch;

      final rootNote = match.group(1)!;
      final quality = match.group(2) ?? '';
      final extension = match.group(3) ?? '';
      final slashBass = match.group(4);

      final transposedRoot = _transposeSingleNote(rootNote, semitones);
      var result = '$transposedRoot$quality$extension';

      if (slashBass != null && slashBass.length > 1) {
        final bassNote = slashBass.substring(1); // Remove leading '/'
        final transposedBass = _transposeSingleNote(bassNote, semitones);
        result = '$result/$transposedBass';
      }

      return result;
    });
  }

  /// Transpose all chord lines in a full chord chart text.
  static String transposeChordChart(String chart, String fromKey, String toKey) {
    final semitones = getSemitoneDistance(fromKey, toKey);
    if (semitones == 0) return chart;

    final lines = chart.split('\n');
    return lines.map((line) => transposeLine(line, semitones)).join('\n');
  }

  /// Calculate capo position to play in a target key using open chord shapes
  /// of a simpler key.
  /// Returns the capo fret number (0 = no capo).
  static int getCapoPosition(String targetKey, String openKey) {
    return getSemitoneDistance(openKey, targetKey);
  }

  /// Given a target key, suggest the best capo position and corresponding
  /// open chord key for easier playing.
  /// Prefers common open chord keys: C, G, D, A, E.
  static ({int capo, String openKey}) suggestCapo(String targetKey) {
    const preferredKeys = ['G', 'C', 'D', 'A', 'E'];
    int bestCapo = 0;
    String bestKey = targetKey;

    for (final openKey in preferredKeys) {
      final capo = getCapoPosition(targetKey, openKey);
      if (capo == 0) {
        return (capo: 0, openKey: targetKey);
      }
      if (capo <= 5 && (bestCapo == 0 || capo < bestCapo)) {
        bestCapo = capo;
        bestKey = openKey;
      }
    }

    return (capo: bestCapo, openKey: bestKey);
  }

  // Internal helpers

  static String _transposeRoot(String chordWithQuality, int semitones) {
    if (chordWithQuality.isEmpty) return chordWithQuality;

    // Extract root note (1 or 2 chars)
    String rootNote;
    String suffix;

    if (chordWithQuality.length > 1 &&
        (chordWithQuality[1] == '#' || chordWithQuality[1] == 'b')) {
      rootNote = chordWithQuality.substring(0, 2);
      suffix = chordWithQuality.substring(2);
    } else {
      rootNote = chordWithQuality.substring(0, 1);
      suffix = chordWithQuality.substring(1);
    }

    final transposed = _transposeSingleNote(rootNote, semitones);
    return '$transposed$suffix';
  }

  static String _transposeSingleNote(String note, int semitones) {
    final index = _getNoteIndex(note);
    if (index == -1) return note;

    final newIndex = (index + semitones + 12) % 12;

    // Preserve sharp/flat preference
    final usesFlats = note.contains('b');
    return usesFlats ? _flatNotes[newIndex] : _sharpNotes[newIndex];
  }

  static int _getNoteIndex(String note) {
    // Try sharp notes first
    final sharpIndex = _sharpNotes.indexOf(note);
    if (sharpIndex >= 0) return sharpIndex;

    // Try flat notes
    final flatIndex = _flatNotes.indexOf(note);
    if (flatIndex >= 0) return flatIndex;

    // Try flat-to-sharp conversion
    final sharp = _flatToSharp[note];
    if (sharp != null) return _sharpNotes.indexOf(sharp);

    return -1;
  }
}
