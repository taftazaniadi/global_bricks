import 'package:test/test.dart';

import '../post_gen.dart';

void main() {
  group('normalizeFeaturePath', () {
    test('normalizes whitespace and nested paths', () {
      expect(normalizeFeaturePath(' auth / checkout/payment '),
          equals('auth/checkout/payment'));
    });

    test('converts spaces to snake_case and removes empty segments', () {
      expect(normalizeFeaturePath('  User Profile / Checkout  '),
          equals('user_profile/checkout'));
    });
  });

  group('normalizeFeatureName', () {
    test('returns the last segment of a normalized path', () {
      expect(normalizeFeatureName('balance/fund_transfer'),
          equals('fund_transfer'));
    });
  });

  group('normalizeSubfeatures', () {
    test('splits comma-separated values and normalizes them', () {
      expect(normalizeSubfeatures(' login, register, forgot password '),
          equals(['login', 'register', 'forgot_password']));
    });

    test('returns empty list for empty input', () {
      expect(normalizeSubfeatures('   '), isEmpty);
    });
  });

  group('buildDefaultFeatureDirs', () {
    test('returns the expected clean architecture folders', () {
      expect(buildDefaultFeatureDirs(), containsAll([
        'data/repositories',
        'domain/usecases',
        'presentation/bloc',
      ]));
    });
  });
}
