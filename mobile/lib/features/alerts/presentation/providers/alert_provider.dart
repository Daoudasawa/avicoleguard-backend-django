import 'package:flutter/foundation.dart';
import 'package:avicoleguard_mobile/features/alerts/data/models/alert_model.dart';
import 'package:avicoleguard_mobile/features/alerts/data/repositories/alert_repository.dart';

class AlertProvider extends ChangeNotifier {
  final AlertRepository _repo;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;

  AlertProvider(this._repo) {
    loadCached();
  }

  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get openAlerts => _alerts.where((a) => a.isOpen).toList();
  int get openAlertsCount => openAlerts.length;
  bool get isLoading => _isLoading;

  void loadCached() {
    _alerts = _repo.getCachedAlerts();
    notifyListeners();
  }

  Future<void> refresh([String? flockId]) async {
    _isLoading = true;
    notifyListeners();
    try {
      _alerts = await _repo.fetchAlerts(flockId);
    } catch (_) {
      loadCached();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// US-ALERT-002 — Acquitter une alerte (open → acknowledged).
  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      final updated = await _repo.acknowledgeAlert(alertId);
      if (updated != null) {
        final idx = _alerts.indexWhere((a) => a.id == alertId);
        if (idx != -1) {
          _alerts[idx] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
