import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_event_model.dart';
import '../models/news_history_model.dart';
import '../../core/constants/app_constants.dart';

class NewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- One-time reads ----------

  Future<List<NewsEvent>> getUpcomingNews() async {
    // Filter by time >= now so we always see future events,
    // regardless of whether status field was updated by a Cloud Function.
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    final snapshot = await _firestore
        .collection(AppConstants.newsEventsCollection)
        .where('time', isGreaterThanOrEqualTo: now)
        .orderBy('time', descending: false)
        .limit(60)
        .get();

    return snapshot.docs.map((doc) => NewsEvent.fromFirestore(doc)).toList();
  }

  Future<List<NewsHistory>> getNewsHistory() async {
    final snapshot = await _firestore
        .collection(AppConstants.newsHistoryCollection)
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => NewsHistory.fromFirestore(doc)).toList();
  }

  Future<List<NewsHistory>> getEventHistory(String eventName) async {
    final snapshot = await _firestore
        .collection(AppConstants.newsHistoryCollection)
        .where('event_name', isEqualTo: eventName)
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => NewsHistory.fromFirestore(doc)).toList();
  }

  // ---------- Real-time stream ----------

  /// Streams upcoming events in real-time — UI rebuilds automatically
  /// when Firestore data changes (e.g. after Cloud Function writes actual value).
  Stream<List<NewsEvent>> streamUpcomingNews() {
    // Use time-based filter so the stream reflects real upcoming events.
    // A 5-minute buffer is subtracted so events stay visible right at release time.
    final now = Timestamp.fromDate(
      DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
    );
    return _firestore
        .collection(AppConstants.newsEventsCollection)
        .where('time', isGreaterThanOrEqualTo: now)
        .orderBy('time', descending: false)
        .limit(60)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NewsEvent.fromFirestore(doc)).toList());
  }

  // ---------- Writes ----------

  /// Saves a single event — uses merge so existing data is not overwritten
  Future<void> saveNewsEvent(NewsEvent event) async {
    await _firestore
        .collection(AppConstants.newsEventsCollection)
        .doc(event.id.isEmpty ? null : event.id)
        .set(event.toFirestore(), SetOptions(merge: true));
  }

  /// Batch-saves a list of events in a single Firestore round-trip (max 500)
  Future<void> batchSaveNewsEvents(List<NewsEvent> events) async {
    // Chunk into batches of 400 to stay safely under the 500-op limit
    const int chunkSize = 400;
    for (int i = 0; i < events.length; i += chunkSize) {
      final chunk = events.sublist(
          i, i + chunkSize > events.length ? events.length : i + chunkSize);

      final WriteBatch batch = _firestore.batch();
      for (final event in chunk) {
        final docRef = _firestore
            .collection(AppConstants.newsEventsCollection)
            .doc(event.id.isEmpty ? null : event.id);
        batch.set(docRef, event.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Future<void> saveNewsHistory(NewsHistory history) async {
    await _firestore
        .collection(AppConstants.newsHistoryCollection)
        .doc(history.id.isEmpty ? null : history.id)
        .set(history.toFirestore(), SetOptions(merge: true));
  }
}
