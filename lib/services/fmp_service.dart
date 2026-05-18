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

  /// Fetches today + next 7 days — rolling window, always fresh
  Future<List<NewsEvent>> fetchThisWeek() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day); // today at midnight
    final to = from.add(const Duration(days: 7));        // 7 days forward
    return fetchCalendar(from: from, to: to);
  }

  /// Fetches the following 7 days (days 8–14 from today)
  Future<List<NewsEvent>> fetchNextWeek() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).add(const Duration(days: 8));
    final to = from.add(const Duration(days: 6));
    return fetchCalendar(from: from, to: to);
  }

  /// Merges this week + next week into one list (deduped by id)
  Future<List<NewsEvent>> fetchUpcoming() async {
    final results = await Future.wait([fetchThisWeek(), fetchNextWeek()]);
    final seen = <String>{};
    final merged = <NewsEvent>[];
    for (final list in results) {
      for (final e in list) {
        if (seen.add(e.id)) merged.add(e);
      }
    }
    // Sort chronologically
    merged.sort((a, b) => a.time.compareTo(b.time));
    return merged;
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

    final String rawEventName = (item['event'] ?? '').toString();
    final String sanitizedEventName = rawEventName.replaceAll(RegExp(r'[ /\\?#%*+:|"<>]'), '_');

    events.add(NewsEvent(
      id: 'fmp_${country}_${sanitizedEventName}_${time.millisecondsSinceEpoch}',
      eventName: rawEventName.isEmpty ? 'Unknown Event' : rawEventName,
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
