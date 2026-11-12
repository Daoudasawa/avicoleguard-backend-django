import 'package:uuid/uuid.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/features/farms/data/models/farm_model.dart';
import 'package:avicoleguard_mobile/features/flocks/data/models/flock_model.dart';

class FarmFlockRepository {
  final DioClient _dioClient;
  final _uuid = const Uuid();

  FarmFlockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  // --- FERMES ---
  List<FarmModel> getCachedFarms() {
    final box = LocalStorageService.getFarmsBox();
    final farms = <FarmModel>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        farms.add(FarmModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return farms;
  }

  Future<List<FarmModel>> fetchFarms() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.farms);
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final box = LocalStorageService.getFarmsBox();
        final farms = <FarmModel>[];

        for (var item in list) {
          final farm = FarmModel.fromJson(Map<String, dynamic>.from(item));
          farms.add(farm);
          await box.put(farm.id, farm.toJson());
        }
        return farms;
      }
    } catch (_) {
      // Offline fallback
    }
    return getCachedFarms();
  }

  Future<FarmModel> createFarm({
    required String name,
    String locationText = '',
    int? capacity,
  }) async {
    final clientUuid = _uuid.v4();
    final tempId = clientUuid;

    final farm = FarmModel(
      id: tempId,
      name: name,
      locationText: locationText,
      capacity: capacity,
      clientUuid: clientUuid,
      syncStatus: 'pending',
    );

    // 1. Sauvegarde locale d'abord (Offline-first)
    final box = LocalStorageService.getFarmsBox();
    await box.put(farm.id, farm.toJson());

    // 2. Mise en file d'attente
    await LocalStorageService.getSyncQueueBox().put(clientUuid, {
      'type': 'create_farm',
      'payload': farm.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Tentative d'envoi réseau si connecté
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.farms,
        data: farm.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverFarm =
            FarmModel.fromJson(Map<String, dynamic>.from(response.data));
        await box.put(serverFarm.id, serverFarm.toJson());
        await LocalStorageService.getSyncQueueBox().delete(clientUuid);
        return serverFarm;
      }
    } catch (_) {}

    return farm;
  }

  // --- LOTS (FLOCKS) ---
  List<FlockModel> getCachedFlocks() {
    final box = LocalStorageService.getFlocksBox();
    final flocks = <FlockModel>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        flocks.add(FlockModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return flocks;
  }

  Future<List<FlockModel>> fetchFlocks() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.flocks);
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final box = LocalStorageService.getFlocksBox();
        final flocks = <FlockModel>[];

        for (var item in list) {
          final flock = FlockModel.fromJson(Map<String, dynamic>.from(item));
          flocks.add(flock);
          await box.put(flock.id, flock.toJson());
        }
        return flocks;
      }
    } catch (_) {
      // Offline fallback
    }
    return getCachedFlocks();
  }

  Future<FlockModel> createFlock({
    required String farmId,
    required String reference,
    required int initialCount,
    String breed = '',
    String sex = 'mixed',
    required DateTime arrivalDate,
  }) async {
    final clientUuid = _uuid.v4();
    final tempId = clientUuid;

    final flock = FlockModel(
      id: tempId,
      farmId: farmId,
      reference: reference,
      breed: breed,
      sex: sex,
      initialCount: initialCount,
      currentCount: initialCount,
      arrivalDate: arrivalDate,
      status: 'active',
      clientUuid: clientUuid,
      syncStatus: 'pending',
    );

    // 1. Sauvegarde locale d'abord
    final box = LocalStorageService.getFlocksBox();
    await box.put(flock.id, flock.toJson());

    // 2. Queue sync
    await LocalStorageService.getSyncQueueBox().put(clientUuid, {
      'type': 'create_flock',
      'payload': flock.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Tentative d'envoi réseau
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.flocks,
        data: flock.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverFlock =
            FlockModel.fromJson(Map<String, dynamic>.from(response.data));
        await box.put(serverFlock.id, serverFlock.toJson());
        await LocalStorageService.getSyncQueueBox().delete(clientUuid);
        return serverFlock;
      }
    } catch (_) {}

    return flock;
  }

  Future<void> updateFlockCountLocally(String flockId, int newCount) async {
    final box = LocalStorageService.getFlocksBox();
    final data = box.get(flockId);
    if (data != null) {
      final flock = FlockModel.fromJson(Map<String, dynamic>.from(data));
      final updated = flock.copyWith(currentCount: newCount);
      await box.put(flockId, updated.toJson());
    }
  }

  /// US-FLOCK-002 — Clôture d'un lot (status → 'closed').
  /// RM7 : une fois clôturé, plus aucune saisie n'est acceptée.
  Future<FlockModel?> closeFlock(String flockId) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.closeFlock(flockId),
      );
      if (response.statusCode == 200 && response.data != null) {
        final updated = FlockModel.fromJson(
            Map<String, dynamic>.from(response.data));
        final box = LocalStorageService.getFlocksBox();
        await box.put(updated.id, updated.toJson());
        return updated;
      }
    } catch (_) {
      // Offline : mise à jour locale uniquement
      final box = LocalStorageService.getFlocksBox();
      final data = box.get(flockId);
      if (data != null) {
        final flock = FlockModel.fromJson(Map<String, dynamic>.from(data));
        final closed = flock.copyWith(status: 'closed');
        await box.put(flockId, closed.toJson());
        return closed;
      }
    }
    return null;
  }
}
