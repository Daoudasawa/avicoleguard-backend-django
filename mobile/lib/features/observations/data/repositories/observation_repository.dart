import 'package:uuid/uuid.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/features/observations/data/models/observation_model.dart';

class ObservationRepository {
  final DioClient _dioClient;
  final _uuid = const Uuid();

  ObservationRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<ObservationModel> getCachedObservations([String? flockId]) {
    final box = LocalStorageService.getObservationsBox();
    final list = <ObservationModel>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final obs = ObservationModel.fromJson(Map<String, dynamic>.from(data));
        if (flockId == null || obs.flockId == flockId) {
          list.add(obs);
        }
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<ObservationModel>> fetchObservations(String flockId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.flockObservations(flockId),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final box = LocalStorageService.getObservationsBox();
        final list = <ObservationModel>[];
        for (var item in raw) {
          final obs = ObservationModel.fromJson(Map<String, dynamic>.from(item));
          list.add(obs);
          await box.put(obs.id, obs.toJson());
        }
        return list;
      }
    } catch (_) {}
    return getCachedObservations(flockId);
  }

  Future<ObservationModel> addObservation({
    required String flockId,
    required DateTime date,
    required String type,
    String description = '',
  }) async {
    final clientUuid = _uuid.v4();
    final obs = ObservationModel(
      id: clientUuid,
      flockId: flockId,
      date: date,
      type: type,
      description: description,
      clientUuid: clientUuid,
      syncStatus: 'pending',
    );

    // 1. Sauvegarde locale
    final box = LocalStorageService.getObservationsBox();
    await box.put(obs.id, obs.toJson());

    // 2. File d'attente sync
    await LocalStorageService.getSyncQueueBox().put(clientUuid, {
      'type': 'add_observation',
      'payload': obs.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Envoi serveur si en ligne
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.flockObservations(flockId),
        data: obs.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverObs = ObservationModel.fromJson(
            Map<String, dynamic>.from(response.data));
        await box.put(serverObs.id, serverObs.toJson());
        await LocalStorageService.getSyncQueueBox().delete(clientUuid);
        return serverObs;
      }
    } catch (_) {}

    return obs;
  }

  /// RM11 — Annulation tracée d'une observation (jamais de suppression physique).
  /// Supporte le mode offline via sync_status = 'cancelled_pending'.
  Future<ObservationModel?> cancelObservation({
    required String flockId,
    required String observationId,
    required String reason,
  }) async {
    final box = LocalStorageService.getObservationsBox();
    final cached = box.get(observationId);
    ObservationModel? observation;
    if (cached != null) {
      observation = ObservationModel.fromJson(Map<String, dynamic>.from(cached));
      if (observation.isCancelled) {
        throw Exception('Cette observation est déjà annulée.');
      }
    }

    // Tentative d'envoi serveur si en ligne
    try {
      final response = await _dioClient.dio.patch(
        ApiEndpoints.cancelObservation(flockId, observationId),
        data: {'reason': reason},
      );
      if (response.statusCode == 200 && response.data != null) {
        final serverObs = ObservationModel.fromJson(
            Map<String, dynamic>.from(response.data));
        await box.put(serverObs.id, serverObs.toJson());
        await LocalStorageService.getSyncQueueBox()
            .delete('cancel_obs_$observationId');
        return serverObs;
      }
    } catch (_) {
      // Offline : annulation locale + file d'attente (sync_status = cancelled_pending)
      if (observation != null) {
        final cancelledLocally = ObservationModel(
          id: observation.id,
          flockId: observation.flockId,
          date: observation.date,
          type: observation.type,
          description: observation.description,
          clientUuid: observation.clientUuid,
          syncStatus: 'cancelled_pending',
          cancelledAt: DateTime.now(),
          cancelReason: reason,
        );
        await box.put(observationId, cancelledLocally.toJson());
        await LocalStorageService.getSyncQueueBox().put(
          'cancel_obs_$observationId',
          {
            'type': 'cancel_observation',
            'payload': {
              'observation_id': observationId,
              'flock_id': flockId,
              'reason': reason,
            },
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        return cancelledLocally;
      }
    }
    return null;
  }
}
