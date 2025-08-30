// lib/string_calculator.dart
typedef AddOccurred = void Function(String input, int result);

class StringCalculator {
  int _calledCount = 0;
  final List<AddOccurred> _listeners = [];

  void addListener(AddOccurred listener) => _listeners.add(listener);
  void removeListener(AddOccurred listener) => _listeners.remove(listener);

  int getCalledCount() => _calledCount;

  int add(String numbers) {
    _calledCount++;

    if (numbers.isEmpty) {
      _notify(numbers, 0);
      return 0;
    }

    final parseResult = _parse(numbers);
    final tokens = parseResult.$1;
    final values = <int>[];
    final negatives = <int>[];

    for (final t in tokens) {
      if (t.isEmpty) continue;
      final n = int.parse(t);
      if (n < 0) {
        negatives.add(n);
      } else if (n <= 1000) {
        values.add(n);
      }
    }

    if (negatives.isNotEmpty) {
      throw ArgumentError('negatives not allowed: ${negatives.join(', ')}');
    }

    final sum = values.fold(0, (a, b) => a + b);
    _notify(numbers, sum);
    return sum;
  }

  // Returns (tokens, usedDelimiters)
  (List<String>, List<Pattern>) _parse(String input) {
    List<Pattern> delimiters = [',', '\n'];

    String payload = input;

    if (input.startsWith('//')) {
      final newlineIdx = input.indexOf('\n');
      final header = input.substring(2, newlineIdx);
      payload = input.substring(newlineIdx + 1);

      // Multiple delimiters with brackets //[*][%]
      if (header.startsWith('[') && header.endsWith(']')) {
        final patterns = <String>[];
        final buffer = StringBuffer();
        bool inBracket = false;

        for (int i = 0; i < header.length; i++) {
          final ch = header[i];
          if (ch == '[') {
            inBracket = true;
            buffer.clear();
          } else if (ch == ']') {
            inBracket = false;
            patterns.add(buffer.toString());
          } else if (inBracket) {
            buffer.write(ch);
          }
        }
        delimiters = patterns.map(_escapeForRegex).toList();
      } else {
        // Single delimiter form //;
        delimiters = [_escapeForRegex(header)];
      }
    }

    // Build a regex that splits on any delimiter alternative
    final regexPattern = delimiters.map((p) => p is RegExp ? p.pattern : p.toString()).join('|');
    final splitter = RegExp(regexPattern);
    final tokens = payload.split(splitter);
    return (tokens, delimiters);
  }

  Pattern _escapeForRegex(String raw) {
    // Treat raw as literal delimiter; escape for regex
    final escaped = RegExp.escape(raw);
    return RegExp(escaped);
  }

  void _notify(String input, int result) {
    for (final l in List<AddOccurred>.from(_listeners)) {
      l(input, result);
    }
  }
}
