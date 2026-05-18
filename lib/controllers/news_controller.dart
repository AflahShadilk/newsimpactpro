import 'dart:async';
import 'package:get/get.dart';
import '../data/models/news_event_model.dart';
import '../data/models/news_history_model.dart';
import '../data/repositories/news_repository.dart';
import '../services/sync_service.dart';

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

  // Resubscribes every 10 min so the time-based Firestore cutoff stays fresh
  Timer? _streamRefreshTimer;

  @override
  void onInit() {
    super.onInit();
    // Subscribe to Firestore real-time stream — no polling required
    _subscribeToEvents();
    // Refresh stream every 10 min so the time >= now filter stays accurate
    _streamRefreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _resubscribeToEvents(),
    );
    // Trigger an auto-sync if Firestore has no data yet
    _triggerSyncIfEmpty();
    // History is fetched once (not streamed — it's historical, rarely changes)
    fetchHistory();
  }

  @override
  void onClose() {
    _eventsSubscription?.cancel();
    _streamRefreshTimer?.cancel();
    super.onClose();
  }

  /// Listens to Firestore upcoming events in real-time.
  void _subscribeToEvents() {
    isLoading.value = true;
    _eventsSubscription = _newsRepository.streamUpcomingNews().listen(
      (incoming) {
        events.value = incoming;
        isLoading.value = false;
        // If Firestore returned empty, kick off a fresh sync from the API
        if (incoming.isEmpty) _triggerSyncIfEmpty();
      },
      onError: (e) {
        Get.log('Stream error: $e');
        isLoading.value = false;
        fetchNews(); // Fallback to one-time fetch
      },
    );
  }

  /// Cancels and recreates the stream so the time >= now cutoff is recalculated.
  void _resubscribeToEvents() {
    _eventsSubscription?.cancel();
    _subscribeToEvents();
  }

  /// Triggers a background sync the first time Firestore returns empty results.
  void _triggerSyncIfEmpty() {
    if (!Get.isRegistered<SyncService>()) return;
    final sync = Get.find<SyncService>();
    if (!sync.isSyncing.value) {
      Get.log('NewsController: Firestore empty — triggering auto-sync');
      sync.syncLiveNewsData(force: true);
    }
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
    final now = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    return events.where((event) {
      // Client-side safety net: never show events more than 5 min in the past
      if (event.time.toUtc().isBefore(now)) return false;
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
