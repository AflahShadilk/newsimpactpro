import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String fcmToken;
  final List<String> currencies;
  final List<String> impact;
  final int alertTime;
  final bool focusMode;
  final String timezone;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? lastActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.fcmToken,
    required this.currencies,
    required this.impact,
    required this.alertTime,
    required this.focusMode,
    required this.timezone,
    required this.notificationsEnabled,
    this.createdAt,
    this.lastActive,
  });

  factory UserModel.empty() => UserModel(
        uid: '',
        email: '',
        displayName: '',
        photoUrl: '',
        fcmToken: '',
        currencies: ['USD', 'EUR', 'GBP'],
        impact: ['high', 'medium'],
        alertTime: 15,
        focusMode: false,
        timezone: 'UTC',
        notificationsEnabled: true,
      );

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: data['uid'] ?? id,
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? '',
      photoUrl: data['photo_url'] ?? '',
      fcmToken: data['fcm_token'] ?? '',
      currencies: List<String>.from(data['currencies'] ?? ['USD', 'EUR', 'GBP']),
      impact: List<String>.from(data['impact'] ?? ['high', 'medium']),
      alertTime: (data['alert_time'] as num?)?.toInt() ?? 15,
      focusMode: data['focus_mode'] ?? false,
      timezone: data['timezone'] ?? 'UTC',
      notificationsEnabled: data['notifications_enabled'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      lastActive: (data['last_active'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'fcm_token': fcmToken,
      'currencies': currencies,
      'impact': impact,
      'alert_time': alertTime,
      'focus_mode': focusMode,
      'timezone': timezone,
      'notifications_enabled': notificationsEnabled,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'last_active': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? fcmToken,
    List<String>? currencies,
    List<String>? impact,
    int? alertTime,
    bool? focusMode,
    String? timezone,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      currencies: currencies ?? this.currencies,
      impact: impact ?? this.impact,
      alertTime: alertTime ?? this.alertTime,
      focusMode: focusMode ?? this.focusMode,
      timezone: timezone ?? this.timezone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
