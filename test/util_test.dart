import 'package:flutter_test/flutter_test.dart';
import 'package:redivo_app/flutter_flow/flutter_flow_util.dart';

// We can't easily test map_widget.dart private methods without making them public or using a mock.
// But we can test the logic if we extract it or just rely on the fact that toInt() on finite is safe.

void main() {
  group('castToType Tests', () {
    test('castToType handles NaN correctly', () {
      final result = castToType<int>(double.nan);
      expect(result, isNull);
    });

    test('castToType handles Infinity correctly', () {
      final result = castToType<int>(double.infinity);
      expect(result, isNull);
    });

    test('castToType handles normal int correctly', () {
      final result = castToType<int>(10);
      expect(result, 10);
    });

    test('castToType handles normal double correctly', () {
      final result = castToType<double>(10.5);
      expect(result, 10.5);
    });

    test('castToType handles double as int correctly', () {
      final result = castToType<int>(10.0);
      expect(result, 10);
    });
  });

  group('Numeric Safety Tests', () {
    test('toInt on finite numbers works', () {
      expect(10.5.toInt(), 10);
      expect((-5.8).toInt(), -5);
    });

    test('round on finite numbers works', () {
      expect(10.5.round(), 11);
      expect(10.4.round(), 10);
    });

    // The following would throw if not guarded:
    // double.nan.toInt();
    // double.infinity.round();
  });
}
