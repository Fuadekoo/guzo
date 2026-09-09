/// Builders for numeric sequences.
///
/// These are functions rather than constant lists because the brief asks for
/// configurable lengths (1–10, 1–20, 1–50, 1–100) and leaves room for
/// skip-counting, countdowns and times tables later. Every builder returns a
/// plain `List<String>`, which is all [SequenceDefinition] needs — so a new
/// number mode never touches the game loop.
abstract final class NumberSequences {
  /// Counting from [from] to [to] inclusive, in steps of [step].
  ///
  /// Counts downward when [to] is below [from], which is what makes
  /// [countdown] a one-line call rather than a special case.
  static List<String> range(int from, int to, {int step = 1}) {
    assert(step > 0, 'step must be positive; pass to < from to count down');

    final List<String> items = <String>[];
    if (to >= from) {
      for (int n = from; n <= to; n += step) {
        items.add('$n');
      }
    } else {
      for (int n = from; n >= to; n -= step) {
        items.add('$n');
      }
    }
    return items;
  }

  /// 2, 4, 6, … up to and including [upTo].
  static List<String> evens(int upTo) => range(2, upTo, step: 2);

  /// 1, 3, 5, … up to and including [upTo].
  static List<String> odds(int upTo) => range(1, upTo, step: 2);

  /// [from] down to [to], e.g. 20 → 19 → 18 …
  static List<String> countdown({required int from, int to = 1}) =>
      range(from, to);

  /// The times table of [of]: `of`, `2 × of`, … [count] terms in all.
  static List<String> multiples({required int of, required int count}) =>
      <String>[for (int n = 1; n <= count; n++) '${of * n}'];
}
