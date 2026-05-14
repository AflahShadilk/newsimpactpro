import 'dart:async';
import 'package:get/get.dart';
import '../data/models/news_event_model.dart';
import '../data/models/news_history_model.dart';
import '../data/repositories/news_repository.dart';

class NewsController extends GetxController {
  final NewsRepository _newsRepository = NewsRepository();

  final RxList<NewsEvent> events = <NewsEvent>[].obs;
  final RxList<NewsHistory> historyEvents = <NewsHistory>[].obs;
  final RxList<NewsHistory> specificEventHistory = <NewsHistory>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isHistoryLoading = false.obs;

  // Active currency + impact filters
  final RxList<String> selectedCurrencies = <String>['USD', 'EUR', 'GBP'].obs;
  final RxList<String> selectedImpacts = <String>['high', 'medium'].obs;

  StreamSubscription<List<NewsEvent>>? _eventsSubscription;

  @override
  void onInit() {
    super.onInit();
    // Subscribe to Firestore real-time stream — no polling required
    _subscribeToEvents();
    // History is fetched once (not streamed — it's historical, rarely changes)
    fetchHistory();
  }

  @override
  void onClose() {
    // Always cancel stream subscriptions to prevent memory leaks
    _eventsSubscription?.cancel();
    super.onClose();
  }

  /// Listens to Firestore upcoming events in real-time.
  /// Events list updates automatically when Cloud Function writes new data.
  void _subscribeToEvents() {
    isLoading.value = true;
    _eventsSubscription = _newsRepository.streamUpcomingNews().listen(
      (incoming) {
        events.value = incoming;
        isLoading.value = false;
      },
      onError: (e) {
        Get.log('Stream error: $e');
        isLoading.value = false;
        // Fallback to one-time fetch if stream fails
        fetchNews();
      },
    );
  }

  /// Manual one-time refresh — used as fallback if stream fails
  Future<void> fetchNews() async {
    try {
      isLoading.value = true;
      events.value = await _newsRepository.getUpcomingNews();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch news: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHistory() async {
    try {
      isHistoryLoading.value = true;
      historyEvents.value = await _newsRepository.getNewsHistory();
    } catch (e) {
      if (historyEvents.isEmpty) {
        Get.snackbar('History Error', e.toString());
      }
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> fetchEventHistory(String eventName) async {
    try {
      specificEventHistory.clear();
      specificEventHistory.value =
          await _newsRepository.getEventHistory(eventName);
    } catch (e) {
      Get.log('Error fetching event history: $e');
    }
  }

  // ---------- Computed filtered lists ----------

  List<NewsEvent> get filteredEvents {
    return events.where((event) {
      final currencyMatch = selectedCurrencies.contains(event.currency);
      final impactMatch = selectedImpacts.contains(event.impact);
      return currencyMatch && impactMatch;
    }).toList();
  }

  List<NewsHistory> get filteredHistory {
    return historyEvents.where((event) {
      final currencyMatch = selectedCurrencies.contains(event.currency);
      final impactMatch = selectedImpacts.contains(event.impact);
      return currencyMatch && impactMatch;
    }).toList();
  }

  // ---------- Filter toggle methods ----------

  void toggleCurrency(String currency) {
    if (selectedCurrencies.contains(currency)) {
      if (selectedCurrencies.length > 1) {
        // Prevent deselecting all currencies
        selectedCurrencies.remove(currency);
      }
    } else {
      selectedCurrencies.add(currency);
    }
  }

  void toggleImpact(String impact) {
    if (selectedImpacts.contains(impact)) {
      if (selectedImpacts.length > 1) {
        // Prevent deselecting all impact levels
        selectedImpacts.remove(impact);
      }
    } else {
      selectedImpacts.add(impact);
    }
  }

  /// Sync selected currencies from user settings into the filter
  void syncFiltersFromUser({
    required List<String> currencies,
    required List<String> impacts,
  }) {
    selectedCurrencies.value = currencies;
    selectedImpacts.value = impacts;
  }
}
