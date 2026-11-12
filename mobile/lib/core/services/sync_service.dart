import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DioClient _dioClient = DioClient();
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  int get pendingQueueCount => LocalStorageService.getSyncQueueBox().length;

  /// Démarre le worker de synchronisation automatique périodique (toutes les 5 minutes)
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) => syncAll());
  }

  /// Arrête le worker automatique
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Traitement de la file d'attente (push offline-first) avec retry et backoff
  Future<int> flushSyncQueue() async {
    final queueBox = LocalStorageService.getSyncQueueBox();
    final keys = List.from(queueBox.keys);
    int successCount = 0;

    for (final key in keys) {
      final raw = queueBox.get(key);
      if (raw == null) continue;
      final item = Map<String, dynamic>.from(raw);
      final type = item['type'];
      final payload = Map<String, dynamic>.from(item['payload'] ?? {});

      bool success = false;
      int attempts = item['retry_count'] ?? 0;

      try {
        if (type == 'record_mortality') {
          final res = await _dioClient.dio.post(
            ApiEndpoints.mortalities,
            data: payload,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (type == 'cancel_mortality') {
          final flockId = payload['flock_id'];
          final mortalityId = payload['mortality_id'];
          final reason = payload['reason'];
          final res = await _dioClient.dio.post(
            ApiEndpoints.cancelMortality(flockId, mortalityId),
            data: {'reason': reason},
          );
          success = res.statusCode == 200;
        } else if (type == 'add_observation') {
          final flockId = payload['flock'];
          final res = await _dioClient.dio.post(
            ApiEndpoints.flockObservations(flockId),
            data: payload,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (type == 'create_ticket') {
          final res = await _dioClient.dio.post(
            ApiEndpoints.tickets,
            data: payload,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (type == 'record_monitoring') {
          final flockId = payload['flock']?.toString() ?? '';
          final res = await _dioClient.dio.post(
            ApiEndpoints.flockMonitorings(flockId),
            data: payload,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (type == 'cancel_observation') {
          final flockId = payload['flock_id']?.toString() ?? '';
          final observationId = payload['observation_id']?.toString() ?? '';
          final reason = payload['reason'];
          final res = await _dioClient.dio.patch(
            ApiEndpoints.cancelObservation(flockId, observationId),
            data: {'reason': reason},
          );
          success = res.statusCode == 200;
        } else if (type == 'create_flock') {
          final res = await _dioClient.dio.post(
            ApiEndpoints.flocks,
            data: payload,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (type == 'create_farm') {
          final res = await _dioClient.dio.post(
            ApiEndpoints.farms,
            data: payload,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        }

        if (success) {
          await queueBox.delete(key);
          successCount++;
        } else {
          attempts++;
          item['retry_count'] = attempts;
          await queueBox.put(key, item);
        }
      } catch (e) {
        attempts++;
        item['retry_count'] = attempts;
        item['last_error'] = e.toString();
        await queueBox.put(key, item);
      }
    }

    notifyListeners();
    return successCount;
  }

  /// Synchronisation complète : flush de la queue + timestamp
  Future<bool> syncAll() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await flushSyncQueue();
      await LocalStorageService.saveLastSyncTimestamp(
        DateTime.now().toIso8601String(),
      );
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
}
