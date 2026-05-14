import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsStatus { upcoming, released, archived }

// Identifies which API provided this event — useful for debugging and deduplication
enum NewsSource { forexFactory, fmp }

class NewsEvent {
  final String id;
  final String eventName;
  final String currency;
  final String impact;       // 'high', 'medium', 'low'
  final DateTime time;
  final double? forecast;
  final double? previous;
  final double? actual;
  final String? forecastRaw; // Raw display string e.g. "0.3%" or "220K"
  final String? previousRaw;
  final String? actualRaw;
  final NewsStatus status;
  final bool alertSent;
  final DateTime? createdAt;
  final NewsSource source;

  const NewsEvent({
    required this.id,
    required this.eventName,
    required this.currency,
    required this.impact,
    required this.time,
    this.forecast,
    this.previous,
    this.actual,
    this.forecastRaw,
    this.previousRaw,
    this.actualRaw,
    required this.status,
    required this.alertSent,
    this.createdAt,
    this.source = NewsSource.forexFactory,
  });

  // Creates a copy with updated fields — used when actual value arrives
  NewsEvent copyWith({
    String? id,
    String? eventName,
    String? currency,
    String? impact,
    DateTime? time,
    double? forecast,
    double? previous,
    double? actual,
    String? forecastRaw,
    String? previousRaw,
    String? actualRaw,
    NewsStatus? status,
    bool? alertSent,
    DateTime? createdAt,
    NewsSource? source,
  }) {
    return NewsEvent(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      currency: currency ?? this.currency,
      impact: impact ?? this.impact,
      time: time ?? this.time,
      forecast: forecast ?? this.forecast,
      previous: previous ?? this.previous,
      actual: actual ?? this.actual,
      forecastRaw: forecastRaw ?? this.forecastRaw,
      previousRaw: previousRaw ?? this.previousRaw,
      actualRaw: actualRaw ?? this.actualRaw,
      status: status ?? this.status,
      alertSent: alertSent ?? this.alertSent,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
    );
  }

  factory NewsEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NewsEvent(
      id: doc.id,
      eventName: data['event_name'] ?? '',
      currency: data['currency'] ?? '',
      impact: data['impact'] ?? '',
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      forecast: (data['forecast'] as num?)?.toDouble(),
      previous: (data['previous'] as num?)?.toDouble(),
      actual: (data['actual'] as num?)?.toDouble(),
      forecastRaw: data['forecast_raw'],
      previousRaw: data['previous_raw'],
      actualRaw: data['actual_raw'],
      status: NewsStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'upcoming'),
        orElse: () => NewsStatus.upcoming,
      ),
      alertSent: data['alert_sent'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      source: NewsSource.values.firstWhere(
        (e) => e.name == (data['source'] ?? 'forexFactory'),
        orElse: () => NewsSource.forexFactory,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_name': eventName,
      'currency': currency,
      'impact': impact,
      'time': Timestamp.fromDate(time),
      'forecast': forecast,
      'previous': previous,
      'actual': actual,
      'forecast_raw': forecastRaw,
      'previous_raw': previousRaw,
      'actual_raw': actualRaw,
      'status': status.name,
      'alert_sent': alertSent,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'source': source.name,
    };
  }
}
