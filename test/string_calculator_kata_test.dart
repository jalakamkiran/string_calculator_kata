// test/string_calculator_test.dart
import 'package:string_calculator_kata/string_calculator_kata.dart';
import 'package:test/test.dart';

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
      expect(() => sc.add('1,-2,3'), throwsA(isA<ArgumentError>().having(
            (e) => e.message,
        'message',
        contains('negatives not allowed: -2'),
      )));
    });

    test('throws listing all negatives', () {
      final sc = StringCalculator();
      expect(() => sc.add('-1,2,-3,-4'), throwsA(isA<ArgumentError>().having(
            (e) => e.message,
        'message',
        allOf(contains('-1'), contains('-3'), contains('-4')),
      )));
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

    test('AddOccurred-like event is triggered with input and result', () {
      final sc = StringCalculator();
      String? capturedInput;
      int? capturedResult;

      listener(String input, int result) {
        capturedInput = input;
        capturedResult = result;
      }
      sc.addListener(listener);

      final res = sc.add('1,2,3');
      expect(res, 6);
      expect(capturedInput, '1,2,3');
      expect(capturedResult, 6);

      sc.removeListener(listener);
      capturedInput = null;
      capturedResult = null;

      // After removal, no capture should occur.
      sc.add('2,2');
      expect(capturedInput, isNull);
      expect(capturedResult, isNull);
    });
  });
}
