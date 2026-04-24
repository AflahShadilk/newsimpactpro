import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsStatus { upcoming, released, archived }

class NewsEvent {
  final String id;
  final String eventName;
  final String currency;
  final String impact;
  final DateTime time;
  final double? forecast;
  final double? previous;
  final double? actual;
  final NewsStatus status;
  final bool alertSent;
  final DateTime? createdAt;

  NewsEvent({
    required this.id,
    required this.eventName,
    required this.currency,
    required this.impact,
    required this.time,
    this.forecast,
    this.previous,
    this.actual,
    required this.status,
    required this.alertSent,
    this.createdAt,
  });

  factory NewsEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsEvent(
      id: doc.id,
      eventName: data['event_name'] ?? '',
      currency: data['currency'] ?? '',
      impact: data['impact'] ?? '',
      time: (data['time'] as Timestamp).toDate(),
      forecast: (data['forecast'] as num?)?.toDouble(),
      previous: (data['previous'] as num?)?.toDouble(),
      actual: (data['actual'] as num?)?.toDouble(),
      status: NewsStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
        orElse: () => NewsStatus.upcoming,
      ),
      alertSent: data['alert_sent'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
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
      'status': status.toString().split('.').last,
      'alert_sent': alertSent,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
