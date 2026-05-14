import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/news_event_model.dart';
import '../core/constants/app_constants.dart';

class ForexFactoryService {
  /// Fetches the latest Forex Factory calendar and parses it.
  Future<List<NewsEvent>> fetchWeeklyCalendar() async {
    final response = await http.get(
      Uri.parse(AppConstants.forexFactoryCalendarUrl),
    );

    if (response.statusCode == 200) {
      return _parseForexFactoryEvents(
        response.body,
        AppConstants.countryToCurrency,
      );
    } else {
      throw Exception(
          'Failed to load Forex Factory calendar: ${response.statusCode}');
    }
  }
}

// ---------- Top-level parsing function ----------

List<NewsEvent> _parseForexFactoryEvents(
  String responseBody,
  Map<String, String> currencyMap,
) {
  final List<dynamic> decodedData = jsonDecode(responseBody);
  final List<NewsEvent> events = [];

  for (final item in decodedData) {
    // Normalize impact: "High" → "high"
    final String impact = (item['impact'] ?? 'low').toString().toLowerCase();
    if (impact == 'low') continue; // Skip low-impact events

    final String title   = item['title'] ?? 'Unknown Event';
    final String country = item['country'] ?? '';
    // FF country codes often already are currency codes (USD, EUR, etc.)
    final String currency = currencyMap[country] ?? country;

    DateTime? time;
    try {
      time = DateTime.parse(item['date'] ?? '').toUtc();
    } catch (_) {
      continue; // Skip events with malformed dates
    }

    final String? forecastRaw = item['forecast']?.toString();
    final String? previousRaw = item['previous']?.toString();
    final String? actualRaw   = item['actual']?.toString();

    events.add(NewsEvent(
      id: 'ff_${country}_${title.replaceAll(' ', '_')}_${time.millisecondsSinceEpoch}',
      eventName: title,
      currency: currency,
      impact: impact,
      time: time,
      forecast: _extractDouble(item['forecast']),
      previous: _extractDouble(item['previous']),
      actual: _extractDouble(item['actual']),
      forecastRaw: forecastRaw,
      previousRaw: previousRaw,
      actualRaw: actualRaw,
      status: item['actual'] != null ? NewsStatus.released : NewsStatus.upcoming,
      alertSent: false,
      createdAt: DateTime.now(),
      source: NewsSource.forexFactory,
    ));
  }

  return events;
}

/// Extracts a numeric value from FF strings like "0.3%" or "220K"
double? _extractDouble(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  final String clean = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(clean);
}
