class AppConstants {
  static const String appName = 'NewsImpact Pro';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String newsEventsCollection = 'news_events';
  static const String newsHistoryCollection = 'news_history';
  static const String notificationsLogCollection = 'notifications_log';

  // Layout Constants
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 16.0;
  static const double cardRadius = 16.0;

  // Forex Factory — Public JSON export (no key required, max 2 req/5min, updates hourly)
  static const String forexFactoryCalendarUrl =
      'https://nfs.faireconomy.media/ff_calendar_thisweek.json';

  // Financial Modeling Prep — Economic Calendar (250 req/day free)
  // ⚠️ Move this to Cloud Functions env vars before Play Store release
  static const String fmpApiKey = 'kbWmWYFE8htBY0kJLO2p2AOToRZJBWCD';
  static const String fmpBaseUrl = 'https://financialmodelingprep.com/api/v3';

  // Maps FMP country codes → forex currency codes
  static const Map<String, String> countryToCurrency = {
    'US': 'USD',
    'EU': 'EUR',
    'GB': 'GBP',
    'JP': 'JPY',
    'AU': 'AUD',
    'CA': 'CAD',
    'CH': 'CHF',
    'NZ': 'NZD',
    'CN': 'CNY',
    'DE': 'EUR',
    'FR': 'EUR',
    'IT': 'EUR',
    'ES': 'EUR',
  };
}
