import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/news_event_model.dart';
import '../data/models/news_history_model.dart';
import '../core/constants/app_constants.dart';

class NewsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      
      final snapshot = await _firestore
          .collection(AppConstants.newsEventsCollection)
          .where('status', isEqualTo: 'upcoming')
          .orderBy('time', descending: false)
          .limit(50)
          .get();

      events.value = snapshot.docs.map((doc) => NewsEvent.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch news: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHistory() async {
    try {
      isHistoryLoading.value = true;
      
      final snapshot = await _firestore
          .collection(AppConstants.newsHistoryCollection)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      historyEvents.value = snapshot.docs.map((doc) => NewsHistory.fromFirestore(doc)).toList();
    } catch (e) {
      if (historyEvents.isEmpty) {
        // Only show snackbar if we have no data at all
        Get.snackbar('History Error', e.toString());
      }
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> fetchEventHistory(String eventName) async {
    try {
      specificEventHistory.clear();
      final snapshot = await _firestore
          .collection(AppConstants.newsHistoryCollection)
          .where('event_name', isEqualTo: eventName)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      specificEventHistory.value = snapshot.docs.map((doc) => NewsHistory.fromFirestore(doc)).toList();
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
