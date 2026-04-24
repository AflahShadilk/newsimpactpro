import 'package:get/get.dart';
import '../data/repositories/news_repository.dart';
import '../data/models/news_event_model.dart';
import '../data/models/news_history_model.dart';
import '../controllers/news_controller.dart';

class SyncService extends GetxService {
  final NewsRepository _newsRepository = NewsRepository();

  Future<void> syncMockData() async {
    try {
      // 1. Create Mock Upcoming Events
      final upcomingEvents = [
        NewsEvent(
          id: 'mock_nfp_may',
          eventName: 'Non-Farm Employment Change',
          currency: 'USD',
          impact: 'high',
          time: DateTime.now().add(const Duration(days: 3, hours: 14)),
          status: NewsStatus.upcoming,
          alertSent: false,
          createdAt: DateTime.now(),
          forecast: 243000,
          previous: 303000,
        ),
        NewsEvent(
          id: 'mock_cpi_may',
          eventName: 'CPI m/m',
          currency: 'USD',
          impact: 'high',
          time: DateTime.now().add(const Duration(days: 5, hours: 12)),
          status: NewsStatus.upcoming,
          alertSent: false,
          createdAt: DateTime.now(),
          forecast: 0.003,
          previous: 0.004,
        ),
        NewsEvent(
          id: 'mock_boe_rate',
          eventName: 'Official Bank Rate',
          currency: 'GBP',
          impact: 'high',
          time: DateTime.now().add(const Duration(days: 1, hours: 11)),
          status: NewsStatus.upcoming,
          alertSent: false,
          createdAt: DateTime.now(),
          forecast: 0.0525,
          previous: 0.0525,
        ),
      ];

      for (var event in upcomingEvents) {
        await _newsRepository.saveNewsEvent(event);
      }

      // 2. Create Mock History Data for NFP
      final nfpHistory = [
        NewsHistory(
          id: 'h_nfp_apr',
          eventName: 'Non-Farm Employment Change',
          currency: 'USD',
          impact: 'high',
          date: DateTime.now().subtract(const Duration(days: 30)),
          forecast: 212000,
          actual: 303000,
          deviation: 91000,
          priceBefore: 1.0820,
          priceAfter15m: 1.0760,
          priceAfter1h: 1.0740,
          direction: 'bullish',
          volatility: 85,
          pipsMoved15m: 60,
          pipsMoved1h: 80,
        ),
        NewsHistory(
          id: 'h_nfp_mar',
          eventName: 'Non-Farm Employment Change',
          currency: 'USD',
          impact: 'high',
          date: DateTime.now().subtract(const Duration(days: 60)),
          forecast: 200000,
          actual: 275000,
          deviation: 75000,
          priceBefore: 1.0900,
          priceAfter15m: 1.0840,
          priceAfter1h: 1.0830,
          direction: 'bullish',
          volatility: 70,
          pipsMoved15m: 60,
          pipsMoved1h: 70,
        ),
      ];

      for (var history in nfpHistory) {
        await _newsRepository.saveNewsHistory(history);
      }

      // 3. Trigger refresh in NewsController
      if (Get.isRegistered<NewsController>()) {
        Get.find<NewsController>().fetchNews();
        Get.find<NewsController>().fetchHistory();
      }

      Get.snackbar('Sync Successful', 'Mock data has been populated in Firestore.');
    } catch (e) {
      Get.snackbar('Sync Failed', e.toString());
    }
  }
}
