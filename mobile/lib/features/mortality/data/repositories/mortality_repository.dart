import 'package:uuid/uuid.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/features/mortality/data/models/mortality_model.dart';

class MortalityRepository {
  final DioClient _dioClient;
  final _uuid = const Uuid();

  MortalityRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<MortalityModel> getCachedMortalities([String? flockId]) {
    final box = LocalStorageService.getMortalitiesBox();
    final list = <MortalityModel>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final m = MortalityModel.fromJson(Map<String, dynamic>.from(data));
        if (flockId == null || m.flockId == flockId) {
          list.add(m);
        }
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<MortalityModel>> fetchMortalities([String? flockId]) async {
    try {
      final url = flockId != null
          ? ApiEndpoints.flockMortalities(flockId)
          : ApiEndpoints.mortalities;

      final response = await _dioClient.dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final box = LocalStorageService.getMortalitiesBox();
        final list = <MortalityModel>[];

        for (var item in raw) {
          final m = MortalityModel.fromJson(Map<String, dynamic>.from(item));
          list.add(m);
          await box.put(m.id, m.toJson());
        }
        return list;
      }
    } catch (_) {
      // Offline
    }
    return getCachedMortalities(flockId);
  }

  Future<MortalityModel> recordMortality({
    required String flockId,
    String? flockReference,
    required DateTime date,
    required int deadCount,
    String presumedCause = '',
    String notes = '',
  }) async {
    // RM1 & RM3 : dead_count > 0
    if (deadCount <= 0) {
      throw ArgumentError('Le nombre de sujets morts doit être supérieur à 0.');
    }

    final clientUuid = _uuid.v4();
    final mortality = MortalityModel(
      id: clientUuid,
      flockId: flockId,
      flockReference: flockReference,
      date: date,
      deadCount: deadCount,
      presumedCause: presumedCause,
      notes: notes,
      clientUuid: clientUuid,
      syncStatus: 'pending',
    );

    // 1. Sauvegarde locale immédiate (Offline-First)
    final box = LocalStorageService.getMortalitiesBox();
    await box.put(mortality.id, mortality.toJson());

    // 2. Ajout dans la file d'attente offline
    await LocalStorageService.getSyncQueueBox().put(clientUuid, {
      'type': 'record_mortality',
      'payload': mortality.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Envoi au serveur si en ligne
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mortalities,
        data: mortality.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverM =
            MortalityModel.fromJson(Map<String, dynamic>.from(response.data));
        await box.put(serverM.id, serverM.toJson());
        await LocalStorageService.getSyncQueueBox().delete(clientUuid);
        return serverM;
      }
    } catch (_) {}

    return mortality;
  }

  /// RM11 — Annulation tracée d'une mortalité (jamais de suppression physique).
  /// Met en file d'attente si offline (sync_status = cancelled_pending).
  Future<MortalityModel?> cancelMortality({
    required String flockId,
    required String mortalityId,
    required String reason,
  }) async {
    final box = LocalStorageService.getMortalitiesBox();
    final cached = box.get(mortalityId);
    MortalityModel? mortality;
    if (cached != null) {
      mortality =
          MortalityModel.fromJson(Map<String, dynamic>.from(cached));
      if (mortality.isCancelled) {
        throw Exception('Cette mortalité est déjà annulée.');
      }
    }

    // Envoi serveur si en ligne
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.cancelMortality(flockId, mortalityId),
        data: {'reason': reason},
      );
      if (response.statusCode == 200 && response.data != null) {
        final serverM = MortalityModel.fromJson(
            Map<String, dynamic>.from(response.data));
        await box.put(serverM.id, serverM.toJson());
        await LocalStorageService.getSyncQueueBox()
            .delete('cancel_$mortalityId');
        return serverM;
      }
    } catch (_) {
      // Offline : annulation locale + file d'attente
      if (mortality != null) {
        final cancelledLocally = MortalityModel(
          id: mortality.id,
          flockId: mortality.flockId,
          flockReference: mortality.flockReference,
          date: mortality.date,
          deadCount: mortality.deadCount,
          presumedCause: mortality.presumedCause,
          notes: mortality.notes,
          clientUuid: mortality.clientUuid,
          syncStatus: 'cancelled_pending',
          cancelledAt: DateTime.now(),
          cancelReason: reason,
        );
        await box.put(mortalityId, cancelledLocally.toJson());
        await LocalStorageService.getSyncQueueBox().put(
          'cancel_$mortalityId',
          {
            'type': 'cancel_mortality',
            'payload': {
              'mortality_id': mortalityId,
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
