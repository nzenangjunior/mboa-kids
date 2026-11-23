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
}
