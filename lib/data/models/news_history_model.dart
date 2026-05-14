import 'package:cloud_firestore/cloud_firestore.dart';

class NewsHistory {
  final String id;
  final String eventName;
  final String currency;
  final String impact;
  final DateTime date;
  final double forecast;
  final double actual;
  final double deviation;
  final double priceBefore;
  final double priceAfter15m;
  final double priceAfter1h;
  final String direction;
  final int volatility;
  final int pipsMoved15m;
  final int pipsMoved1h;
  final DateTime? createdAt;

  NewsHistory({
    required this.id,
    required this.eventName,
    required this.currency,
    required this.impact,
    required this.date,
    required this.forecast,
    required this.actual,
    required this.deviation,
    required this.priceBefore,
    required this.priceAfter15m,
    required this.priceAfter1h,
    required this.direction,
    required this.volatility,
    required this.pipsMoved15m,
    required this.pipsMoved1h,
    this.createdAt,
  });

  factory NewsHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NewsHistory(
      id: doc.id,
      eventName: data['event_name'] ?? '',
      currency: data['currency'] ?? '',
      impact: data['impact'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      forecast: (data['forecast'] as num?)?.toDouble() ?? 0.0,
      actual: (data['actual'] as num?)?.toDouble() ?? 0.0,
      deviation: (data['deviation'] as num?)?.toDouble() ?? 0.0,
      priceBefore: (data['price_before'] as num?)?.toDouble() ?? 0.0,
      priceAfter15m: (data['price_after_15m'] as num?)?.toDouble() ?? 0.0,
      priceAfter1h: (data['price_after_1h'] as num?)?.toDouble() ?? 0.0,
      direction: data['direction'] ?? 'neutral',
      volatility: (data['volatility'] as num?)?.toInt() ?? 0,
      pipsMoved15m: (data['pips_moved_15m'] as num?)?.toInt() ?? 0,
      pipsMoved1h: (data['pips_moved_1h'] as num?)?.toInt() ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_name': eventName,
      'currency': currency,
      'impact': impact,
      'date': Timestamp.fromDate(date),
      'forecast': forecast,
      'actual': actual,
      'deviation': deviation,
      'price_before': priceBefore,
      'price_after_15m': priceAfter15m,
      'price_after_1h': priceAfter1h,
      'direction': direction,
      'volatility': volatility,
      'pips_moved_15m': pipsMoved15m,
      'pips_moved_1h': pipsMoved1h,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
