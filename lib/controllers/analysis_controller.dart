import 'package:get/get.dart';
import '../data/models/news_event_model.dart';
import '../data/models/news_history_model.dart';

enum Bias { bullish, bearish, neutral }

class AnalysisController extends GetxController {
  /// Calculates the trading bias based on the deviation and historical data.
  /// Standard Economic Logic:
  /// - Inflation (CPI) ↑ : Bullish for Currency
  /// - Employment (NFP) ↑ : Bullish for Currency
  /// - Interest Rates ↑ : Bullish for Currency
  /// - Growth (GDP) ↑ : Bullish for Currency
  Bias calculateBias(NewsEvent event) {
    if (event.actual == null || event.forecast == null) return Bias.neutral;

    final double deviation = event.actual! - event.forecast!;
    if (deviation.abs() < 0.0001) return Bias.neutral;

    // Determine if the event is "Inverse" (where higher is bad, e.g., Unemployment)
    bool isInverse = _isInverseEvent(event.eventName);

    if (deviation > 0) {
      return isInverse ? Bias.bearish : Bias.bullish;
    } else {
      return isInverse ? Bias.bullish : Bias.bearish;
    }
  }

  /// Calculates the average pip movement for a specific event from history.
  int calculateAverageVolatility(List<NewsHistory> history) {
    if (history.isEmpty) return 0;
    
    int totalPips = 0;
    for (var h in history) {
      totalPips += h.pipsMoved15m.abs();
    }
    return (totalPips / history.length).round();
  }

  /// Determines if an event name typically follows inverse logic (Higher = Bearish)
  bool _isInverseEvent(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.contains('unemployment') || 
           lowerName.contains('jobless claims') ||
           lowerName.contains('claimant count');
  }

  /// Generates a confidence score (0-100) based on historical consistency
  int calculateConfidence(List<NewsHistory> history, Bias currentBias) {
    if (history.isEmpty) return 0;
    
    int matches = 0;
    for (var h in history) {
      // Check if historical direction matches the projected bias
      if (currentBias == Bias.bullish && h.pipsMoved15m > 0) matches++;
      if (currentBias == Bias.bearish && h.pipsMoved15m < 0) matches++;
    }
    
    return ((matches / history.length) * 100).round();
  }
}
