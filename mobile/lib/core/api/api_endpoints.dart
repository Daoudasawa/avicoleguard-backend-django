class ApiEndpoints {
  static const String productionBaseUrl =
      'https://avicoleguard-api.onrender.com/api/v1';

  // Optional override at build/run time:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  static const String environmentBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  // Runtime override if needed, for example from a debug screen.
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    return environmentBaseUrl;
  }

  // --- Authentification ---
  static const String register = '/auth/register/';
  static const String login = '/auth/token/';
  static const String refreshToken = '/auth/token/refresh/';
  static const String logout = '/auth/token/blacklist/';
  static const String me = '/auth/me/';
  static const String passwordReset = '/auth/password-reset/';
  static const String passwordResetConfirm = '/auth/password-reset/confirm/';

  // --- Fermes & Lots ---
  static const String farms = '/farms/';
  static const String flocks = '/flocks/';
  static String closeFlock(String flockId) => '/flocks/$flockId/close/';

  // --- Mortalités ---
  static const String mortalities = '/mortalities/';
  static String flockMortalities(String flockId) => '/flocks/$flockId/mortalities/';
  static String cancelMortality(String flockId, String mortalityId) =>
      '/flocks/$flockId/mortalities/$mortalityId/cancel/';

  // --- Relevés & Observations ---
  static String flockMonitorings(String flockId) => '/flocks/$flockId/daily-monitorings/';
  static String cancelDailyMonitoring(String flockId, String monitoringId) =>
      '/flocks/$flockId/daily-monitorings/$monitoringId/cancel/';
  static String flockObservations(String flockId) => '/flocks/$flockId/observations/';
  static String cancelObservation(String flockId, String observationId) =>
      '/flocks/$flockId/observations/$observationId/cancel/';

  // --- Alertes & Prophylaxie ---
  static String flockAlerts(String flockId) => '/flocks/$flockId/alerts/';
  static String acknowledgeAlert(String alertId) => '/alerts/$alertId/acknowledge/';
  static const String schedules = '/schedules/';

  // --- Support & Base de connaissances ---
  static const String tickets = '/tickets/';
  static const String educationCategories = '/education/categories/';
  static const String educationArticles = '/education/articles/';
  static const String notifications = '/notifications/';

  // --- Synchronisation Offline-First ---
  static const String syncPull = '/sync/pull/';
  static const String syncPush = '/sync/push/';
}
