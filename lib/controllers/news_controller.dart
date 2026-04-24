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
  
  // Filters
  final RxList<String> selectedCurrencies = <String>['USD', 'EUR', 'GBP'].obs;
  final RxList<String> selectedImpacts = <String>['high', 'medium'].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNews();
    fetchHistory();
  }

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
      specificEventHistory.value = await _newsRepository.getEventHistory(eventName);
    } catch (e) {
      print('Error fetching event history: $e');
    }
  }

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

  void toggleCurrency(String currency) {
    if (selectedCurrencies.contains(currency)) {
      selectedCurrencies.remove(currency);
    } else {
      selectedCurrencies.add(currency);
    }
  }

  void toggleImpact(String impact) {
    if (selectedImpacts.contains(impact)) {
      selectedImpacts.remove(impact);
    } else {
      selectedImpacts.add(impact);
    }
  }
}
