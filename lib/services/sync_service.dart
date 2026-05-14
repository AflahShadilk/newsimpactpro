import 'package:get/get.dart';
import '../data/repositories/news_repository.dart';
import '../data/models/news_event_model.dart';
import '../controllers/news_controller.dart';
import 'fmp_service.dart';
import 'forex_factory_service.dart';

class SyncService extends GetxService {
  final NewsRepository _newsRepository = NewsRepository();
  final FmpService _fmpService = FmpService();
  final ForexFactoryService _ffService = ForexFactoryService();

  // Cache guard — track last successful sync time
  DateTime? _lastSyncTime;
  static const Duration _minSyncInterval = Duration(hours: 1);

  final RxBool isSyncing = false.obs;

  /// Primary sync — uses FMP as main source, Forex Factory as fallback.
  Future<void> syncLiveNewsData({bool force = false}) async {
    // Respect rate limit — skip if synced recently, unless forced
    if (!force && _lastSyncTime != null) {
      final elapsed = DateTime.now().difference(_lastSyncTime!);
      if (elapsed < _minSyncInterval) {
        final remaining = _minSyncInterval - elapsed;
        Get.snackbar(
          'Already Up-to-Date',
          'Next sync available in ${remaining.inMinutes}m ${remaining.inSeconds % 60}s',
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    try {
      isSyncing.value = true;
      List<NewsEvent> events = [];

      // --- Primary: FMP (has actual values, High+Medium impact, reliable) ---
      try {
        events = await _fmpService.fetchThisWeek();
      } catch (fmpError) {
        // --- Fallback: Forex Factory (free, no key, hourly updates) ---
        Get.log('FMP failed, falling back to Forex Factory: $fmpError');
        events = await _ffService.fetchWeeklyCalendar();
      }

      if (events.isEmpty) {
        Get.snackbar('Sync', 'No events returned from API.');
        return;
      }

      // Write all events to Firestore in a single batch round-trip
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final eventsToSave = events
          .where((e) => e.time.isAfter(cutoff))
          .toList();

      await _newsRepository.batchSaveNewsEvents(eventsToSave);
      final int saved = eventsToSave.length;

      // Record sync time
      _lastSyncTime = DateTime.now();

      // Refresh NewsController list in UI
      if (Get.isRegistered<NewsController>()) {
        Get.find<NewsController>().fetchNews();
      }

      Get.snackbar(
        'Sync Complete ✓',
        'Loaded $saved events (High & Medium impact)',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Sync Failed', e.toString());
    } finally {
      isSyncing.value = false;
    }
  }

  /// Force-refresh ignoring cache — use sparingly
  Future<void> forceSync() => syncLiveNewsData(force: true);

  // Deprecated — keeping stub so nothing breaks
  Future<void> syncMockData() async {
    Get.snackbar('Deprecated', 'Use syncLiveNewsData() instead.');
  }
}
