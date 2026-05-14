import 'package:flutter_test/flutter_test.dart';
import 'package:newsimpactpro/controllers/analysis_controller.dart';
import 'package:newsimpactpro/data/models/news_event_model.dart';
import 'package:newsimpactpro/data/models/news_history_model.dart';
import 'package:newsimpactpro/data/models/user_model.dart';

void main() {
  group('AnalysisController Tests', () {
    late AnalysisController controller;

    setUp(() {
      controller = AnalysisController();
    });

    test('Bias Calculation - Standard Logic (Positive Deviation)', () {
      final event = NewsEvent(
        id: '1',
        eventName: 'CPI m/m',
        currency: 'USD',
        impact: 'high',
        time: DateTime.now(),
        forecast: 0.2,
        actual: 0.4,
        source: NewsSource.fmp,
      );

      final bias = controller.calculateBias(event);
      expect(bias, Bias.bullish);
    });

    test('Bias Calculation - Inverse Logic (Unemployment Rate)', () {
      final event = NewsEvent(
        id: '2',
        eventName: 'Unemployment Rate',
        currency: 'USD',
        impact: 'high',
        time: DateTime.now(),
        forecast: 3.8,
        actual: 4.0, // Higher unemployment is bad (Bearish)
        source: NewsSource.fmp,
      );

      final bias = controller.calculateBias(event);
      expect(bias, Bias.bearish);
    });

    test('Average Volatility Calculation', () {
      final history = [
        _mockHistory(pips: 10),
        _mockHistory(pips: 20),
        _mockHistory(pips: 30),
      ];

      final avg = controller.calculateAverageVolatility(history);
      expect(avg, 20);
    });

    test('Confidence Score Calculation', () {
      final history = [
        _mockHistory(pips: 10), // Match for Bullish
        _mockHistory(pips: 5),  // Match for Bullish
        _mockHistory(pips: -5), // No match
      ];

      final confidence = controller.calculateConfidence(history, Bias.bullish);
      expect(confidence, 67); // (2/3) * 100
    });
  });

  group('UserModel Serialization Tests', () {
    test('fromMap should handle missing fields gracefully', () {
      final data = {
        'email': 'test@example.com',
        // 'currencies' is missing
      };
      final user = UserModel.fromMap(data, 'uid123');

      expect(user.uid, 'uid123');
      expect(user.email, 'test@example.com');
      expect(user.currencies, isNotEmpty); // Uses default
      expect(user.alertTime, 15); // Uses default
    });

    test('toFirestore should preserve types', () {
      final user = UserModel(
        uid: 'uid123',
        email: 'test@example.com',
        displayName: 'Trader',
        photoUrl: '',
        fcmToken: '',
        currencies: ['USD'],
        impact: ['high'],
        alertTime: 30,
        focusMode: false,
        timezone: 'UTC',
        notificationsEnabled: true,
      );

      final map = user.toFirestore();
      expect(map['email'], 'test@example.com');
      expect(map['alert_time'], 30);
    });
  });
}

NewsHistory _mockHistory({required int pips}) {
  return NewsHistory(
    id: 'test',
    eventName: 'Test',
    currency: 'USD',
    impact: 'high',
    date: DateTime.now(),
    forecast: 0.0,
    actual: 0.0,
    deviation: 0.0,
    priceBefore: 1.0,
    priceAfter15m: 1.0,
    priceAfter1h: 1.0,
    direction: 'up',
    volatility: 10,
    pipsMoved15m: pips,
    pipsMoved1h: pips,
  );
}
