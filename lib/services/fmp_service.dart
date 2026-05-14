import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/news_event_model.dart';
import '../core/constants/app_constants.dart';

class FmpService {
  /// Fetches the economic calendar from FMP for a date range.
  /// Parses JSON using compute-style top-level function.
  Future<List<NewsEvent>> fetchCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    final String fromStr = _formatDate(from);
    final String toStr = _formatDate(to);

    final Uri uri = Uri.parse(
      '${AppConstants.fmpBaseUrl}/economic_calendar'
      '?from=$fromStr&to=$toStr&apikey=${AppConstants.fmpApiKey}',
    );

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      // Parse on the same thread — JSON parsing is fast enough for calendar data
      // (typically < 200 events per week). Isolate.run would need top-level functions
      // and can't share const Maps across isolate boundaries without serialization.
      return _parseFmpEvents(response.body, AppConstants.countryToCurrency);
    } else {
      throw Exception('FMP API error: ${response.statusCode}');
    }
  }

  /// Convenience method — fetches the current week (Mon → Sun)
  Future<List<NewsEvent>> fetchThisWeek() {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final to = from.add(const Duration(days: 6));               // Sunday
    return fetchCalendar(from: from, to: to);
  }
}

// ---------- Top-level parsing functions (isolate-safe if needed later) ----------

List<NewsEvent> _parseFmpEvents(
  String body,
  Map<String, String> currencyMap,
) {
  final List<dynamic> raw = jsonDecode(body);
  final List<NewsEvent> events = [];

  for (final item in raw) {
    // FMP impact: "High", "Medium", "Low" → normalise to lowercase
    final String impact = (item['impact'] ?? 'low').toString().toLowerCase();
    if (impact == 'low') continue; // Skip low-impact — traders don't need them

    final String country = item['country'] ?? '';
    final String currency = currencyMap[country] ?? country;

    final DateTime? time = _parseFmpDate(item['date']);
    if (time == null) continue; // Skip malformed dates

    final double? forecast = _toDouble(item['estimate']);
    final double? previous = _toDouble(item['previous']);
    final double? actual   = _toDouble(item['actual']);

    final NewsStatus status =
        actual != null ? NewsStatus.released : NewsStatus.upcoming;

    events.add(NewsEvent(
      id: 'fmp_${country}_${(item['event'] ?? '').toString().replaceAll(' ', '_')}_${time.millisecondsSinceEpoch}',
      eventName: item['event'] ?? 'Unknown Event',
      currency: currency,
      impact: impact,
      time: time,
      forecast: forecast,
      previous: previous,
      actual: actual,
      forecastRaw: item['estimate']?.toString(),
      previousRaw: item['previous']?.toString(),
      actualRaw: item['actual']?.toString(),
      status: status,
      alertSent: false,
      createdAt: DateTime.now(),
      source: NewsSource.fmp,
    ));
  }

  return events;
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses FMP date format "2025-05-14 12:30:00" (space separator, UTC)
DateTime? _parseFmpDate(dynamic raw) {
  if (raw == null) return null;
  try {
    return DateTime.parse(raw.toString().replaceFirst(' ', 'T')).toUtc();
  } catch (_) {
    return null;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
