import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_event_model.dart';
import '../models/news_history_model.dart';
import '../../core/constants/app_constants.dart';

class NewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<NewsEvent>> getUpcomingNews() async {
    final snapshot = await _firestore
        .collection(AppConstants.newsEventsCollection)
        .where('status', isEqualTo: 'upcoming')
        .orderBy('time', descending: false)
        .limit(50)
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
        .limit(5)
        .get();

    return snapshot.docs.map((doc) => NewsHistory.fromFirestore(doc)).toList();
  }

  Future<void> saveNewsEvent(NewsEvent event) async {
    await _firestore
        .collection(AppConstants.newsEventsCollection)
        .doc(event.id.isEmpty ? null : event.id)
        .set(event.toFirestore(), SetOptions(merge: true));
  }

  Future<void> saveNewsHistory(NewsHistory history) async {
    await _firestore
        .collection(AppConstants.newsHistoryCollection)
        .doc(history.id.isEmpty ? null : history.id)
        .set(history.toFirestore(), SetOptions(merge: true));
  }
}
