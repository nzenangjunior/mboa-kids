import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/rewards/star_rating.dart';

void main() {
  group('starsForFirstTryCorrect', () {
    test('5 out of 5 first-try correct gives 3 stars', () {
      expect(starsForFirstTryCorrect(5), 3);
    });

    test('3 or 4 first-try correct gives 2 stars', () {
      expect(starsForFirstTryCorrect(3), 2);
      expect(starsForFirstTryCorrect(4), 2);
    });

    test('0, 1 or 2 first-try correct gives 1 star (never 0)', () {
      expect(starsForFirstTryCorrect(0), 1);
      expect(starsForFirstTryCorrect(1), 1);
      expect(starsForFirstTryCorrect(2), 1);
    });
  });

  group('starsForTracingFirstTry', () {
    test('80% or more first-try gives 3 stars', () {
      expect(starsForTracingFirstTry(8, 10), 3);
      expect(starsForTracingFirstTry(4, 5), 3);
    });

    test('40% to 79% first-try gives 2 stars', () {
      expect(starsForTracingFirstTry(4, 10), 2);
      expect(starsForTracingFirstTry(2, 5), 2);
    });

    test('under 40% first-try gives 1 star (never 0)', () {
      expect(starsForTracingFirstTry(0, 10), 1);
      expect(starsForTracingFirstTry(1, 5), 1);
    });

    test('an empty activity never gives 0 stars', () {
      expect(starsForTracingFirstTry(0, 0), 1);
    });
  });
}
