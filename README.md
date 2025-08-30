# String Calculator (TDD, Dart)

A minimal Dart library that implements the classic String Calculator kata using strict Test-Driven Development. It demonstrates incremental design, small commits, and red–green–refactor loops with a clean test suite.

## Features

- Sum numbers from a string with default delimiters (comma and newline).
- Custom delimiter header: `//;` and bracketed forms like `//[***]`.
- Multiple delimiters and delimiters of any length.
- Ignore numbers greater than 1000.
- Throw on negatives with a message listing all negatives.
- Call counter for `add()` invocations.
- Dart-idiomatic event via `addListener`/`removeListener` callbacks.

## Project structure

```
string_calculator/
├─ lib/
│  └─ string_calculator.dart
├─ test/
│  └─ string_calculator_test.dart
├─ bin/
│  └─ main.dart         # optional runner
├─ pubspec.yaml
└─ README.md
```

## Getting started

Prerequisites:
- Dart SDK (or Flutter SDK) installed and on PATH.
- Verify:
  - `dart --version`
  - `flutter --version` (if using Flutter SDK)

Create & install:
```
dart create -t console string_calculator
cd string_calculator
dart pub add --dev test
dart pub get
```

Run tests:
```
dart test
```

Optional runner:
```
dart run
```

## Usage

Basic usage:
```
import 'package:string_calculator/string_calculator.dart';

void main() {
  final sc = StringCalculator();
  final result = sc.add('1,2,3'); // 6
  print(result);
}
```

Custom delimiters:
```
final sc = StringCalculator();
sc.add('//;\n1;2');                // 3
sc.add('//[***]\n1***2***3');      // 6
sc.add('//[*][%]\n1*2%3');         // 6
sc.add('//[**][%%]\n1**2%%3');     // 6
```

Negatives:
```
try {
  sc.add('1,-2,-5');
} on ArgumentError catch (e) {
  print(e.message); // negatives not allowed: -2, -5
}
```

Call count and event:
```
final sc = StringCalculator();

print(sc.getCalledCount()); // 0
sc.add('1,2');              // 3
print(sc.getCalledCount()); // 1

final listener = (String input, int result) {
  print('Added: $input = $result');
};
sc.addListener(listener);
sc.add('2,3'); // Triggers listener
sc.removeListener(listener);
```

## Implementation (lib/string_calculator.dart)

```
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
    final regexPattern = delimiters
        .map((p) => p is RegExp ? p.pattern : p.toString())
        .join('|');
    final splitter = RegExp(regexPattern);
    final tokens = payload.split(splitter);
    return (tokens, delimiters);
  }

  Pattern _escapeForRegex(String raw) {
    final escaped = RegExp.escape(raw);
    return RegExp(escaped);
  }

  void _notify(String input, int result) {
    for (final l in List<AddOccurred>.from(_listeners)) {
      l(input, result);
    }
  }
}
```

## Tests (test/string_calculator_test.dart)

```
import 'package:test/test.dart';
import 'package:string_calculator/string_calculator.dart';

void main() {
  group('StringCalculator - base cases', () {
    test('empty string returns 0', () {
      final sc = StringCalculator();
      expect(sc.add(''), 0);
    });

    test('single number returns its value', () {
      final sc = StringCalculator();
      expect(sc.add('1'), 1);
      expect(sc.add('7'), 7);
    });

    test('two numbers comma-separated are summed', () {
      final sc = StringCalculator();
      expect(sc.add('1,2'), 3);
      expect(sc.add('10,20'), 30);
    });
  });

  group('StringCalculator - many numbers', () {
    test('unknown amount of numbers', () {
      final sc = StringCalculator();
      expect(sc.add('1,2,3,4,5'), 15);
    });
  });

  group('StringCalculator - newlines as delimiters', () {
    test('mix commas and newlines', () {
      final sc = StringCalculator();
      expect(sc.add('1\n2,3'), 6);
    });
  });

  group('StringCalculator - custom delimiter', () {
    test('single char delimiter', () {
      final sc = StringCalculator();
      expect(sc.add('//;\n1;2'), 3);
    });

    test('delimiter of any length', () {
      final sc = StringCalculator();
      expect(sc.add('//[***]\n1***2***3'), 6);
    });

    test('multiple delimiters', () {
      final sc = StringCalculator();
      expect(sc.add('//[*][%]\n1*2%3'), 6);
    });

    test('multiple delimiters with length > 1', () {
      final sc = StringCalculator();
      expect(sc.add('//[**][%%]\n1**2%%3'), 6);
    });
  });

  group('StringCalculator - negatives and >1000', () {
    test('throws with single negative', () {
      final sc = StringCalculator();
      expect(
        () => sc.add('1,-2,3'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('negatives not allowed: -2'),
        )),
      );
    });

    test('throws listing all negatives', () {
      final sc = StringCalculator();
      expect(
        () => sc.add('-1,2,-3,-4'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          allOf(contains('-1'), contains('-3'), contains('-4')),
        )),
      );
    });

    test('ignores numbers greater than 1000', () {
      final sc = StringCalculator();
      expect(sc.add('2,1001'), 2);
      expect(sc.add('1000,1'), 1001);
      expect(sc.add('1000,1001,2'), 1002);
    });
  });

  group('StringCalculator - call count and event', () {
    test('GetCalledCount increases per add call', () {
      final sc = StringCalculator();
      expect(sc.getCalledCount(), 0);
      sc.add('');
      sc.add('1');
      sc.add('1,2');
      expect(sc.getCalledCount(), 3);
    });

    test('listener is triggered with input and result', () {
      final sc = StringCalculator();
      String? capturedInput;
      int? capturedResult;

      final listener = (String input, int result) {
        capturedInput = input;
        capturedResult = result;
      };
      sc.addListener(listener);

      final res = sc.add('1,2,3');
      expect(res, 6);
      expect(capturedInput, '1,2,3');
      expect(capturedResult, 6);

      sc.removeListener(listener);
      capturedInput = null;
      capturedResult = null;

      sc.add('2,2');
      expect(capturedInput, isNull);
      expect(capturedResult, isNull);
    });
  });
}
```

## Optional runner (bin/main.dart)

```
import 'package:string_calculator/string_calculator.dart';

void main(List<String> args) {
  final sc = StringCalculator();
  sc.addListener((input, result) {
    print('Add called with "$input" => $result');
  });

  final samples = <String>[
    '',
    '1',
    '1,2,3',
    '1\n2,3',
    '//;\n1;2',
    '//[***]\n1***2***3',
    '//[*][%]\n1*2%3',
    '//[**][%%]\n1**2%%3',
    '1000,1001,2',
    '-1,2,-3'
  ];

  for (final s in samples) {
    try {
      final r = sc.add(s);
      print('Result: $r (called ${sc.getCalledCount()} times)');
    } on ArgumentError catch (e) {
      print('Error: ${e.message}');
    }
  }
}
```

## TDD approach

Follow the kata’s incremental steps:
1. Empty => 0; then one number; then two numbers.
2. Unknown count.
3. Newline delimiters.
4. Custom delimiter header.
5. Throw on negatives (list all).
6. Ignore > 1000.
7. Call counter and callback.
8. Multiple delimiters and any-length delimiters.

Commit discipline:
- Red: write one small failing test.
- Green: minimal code to pass.
- Refactor: remove duplication; keep tests green.

## Scripts and commands

- Install deps: `dart pub get`
- Run tests: `dart test`
- Run demo: `dart run`
