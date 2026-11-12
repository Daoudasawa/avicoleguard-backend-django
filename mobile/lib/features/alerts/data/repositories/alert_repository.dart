import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/features/alerts/data/models/alert_model.dart';

class AlertRepository {
  final DioClient _dioClient;

  AlertRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<AlertModel> getCachedAlerts() {
    final box = LocalStorageService.getSettingsBox();
    final rawList = box.get('cached_alerts');
    if (rawList != null && rawList is List) {
      return rawList
          .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<List<AlertModel>> fetchAlerts([String? flockId]) async {
    try {
      final url = flockId != null ? ApiEndpoints.flockAlerts(flockId) : '/alerts/';
      final response = await _dioClient.dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final alerts = list
            .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final box = LocalStorageService.getSettingsBox();
        await box.put('cached_alerts', alerts.map((a) => a.toJson()).toList());
        return alerts;
      }
    } catch (_) {}

    return getCachedAlerts();
  }

  /// US-ALERT-002 — Acquittement d'une alerte.
  Future<AlertModel?> acknowledgeAlert(String alertId) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiEndpoints.acknowledgeAlert(alertId),
      );
      if (response.statusCode == 200 && response.data != null) {
        final alert = AlertModel.fromJson(
            Map<String, dynamic>.from(response.data));
        // Mise à jour du cache local
        final cached = getCachedAlerts();
        final updated = cached.map((a) => a.id == alertId ? alert : a).toList();
        final box = LocalStorageService.getSettingsBox();
        await box.put('cached_alerts', updated.map((a) => a.toJson()).toList());
        return alert;
      }
    } catch (_) {}
    return null;
  }
}
