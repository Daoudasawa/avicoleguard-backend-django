import 'package:flutter/foundation.dart';
import 'package:avicoleguard_mobile/features/farms/data/models/farm_model.dart';
import 'package:avicoleguard_mobile/features/flocks/data/models/flock_model.dart';
import 'package:avicoleguard_mobile/features/flocks/data/repositories/farm_flock_repository.dart';

class FarmFlockProvider extends ChangeNotifier {
  final FarmFlockRepository _repo;

  List<FarmModel> _farms = [];
  List<FlockModel> _flocks = [];
  bool _isLoading = false;
  String? _errorMessage;

  FarmFlockProvider(this._repo) {
    loadCached();
  }

  List<FarmModel> get farms => _farms;
  List<FlockModel> get flocks => _flocks;
  List<FlockModel> get activeFlocks =>
      _flocks.where((f) => f.isActive).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalActiveBirds =>
      activeFlocks.fold(0, (sum, f) => sum + f.currentCount);

  int get totalInitialBirds =>
      activeFlocks.fold(0, (sum, f) => sum + f.initialCount);

  double get averageMortalityRate {
    if (totalInitialBirds == 0) return 0.0;
    final dead = totalInitialBirds - totalActiveBirds;
    return (dead / totalInitialBirds) * 100.0;
  }

  void loadCached() {
    _farms = _repo.getCachedFarms();
    _flocks = _repo.getCachedFlocks();
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteFarms = await _repo.fetchFarms();
      final remoteFlocks = await _repo.fetchFlocks();
      _farms = remoteFarms;
      _flocks = remoteFlocks;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données.';
      // Ensure we still have cached data loaded
      loadCached();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FarmModel?> addFarm({
    required String name,
    String locationText = '',
    int? capacity,
  }) async {
    try {
      final farm = await _repo.createFarm(
        name: name,
        locationText: locationText,
        capacity: capacity,
      );
      _farms.insert(0, farm);
      notifyListeners();
      return farm;
    } catch (e) {
      _errorMessage = 'Erreur création de ferme.';
      notifyListeners();
      return null;
    }
  }

  Future<FlockModel?> addFlock({
    required String farmId,
    required String reference,
    required int initialCount,
    String breed = '',
    String sex = 'mixed',
    required DateTime arrivalDate,
  }) async {
    try {
      final flock = await _repo.createFlock(
        farmId: farmId,
        reference: reference,
        initialCount: initialCount,
        breed: breed,
        sex: sex,
        arrivalDate: arrivalDate,
      );
      _flocks.insert(0, flock);
      notifyListeners();
      return flock;
    } catch (e) {
      _errorMessage = 'Erreur création du lot.';
      notifyListeners();
      return null;
    }
  }

  void onMortalityAdded(String flockId, int deadCount) {
    final index = _flocks.indexWhere((f) => f.id == flockId);
    if (index != -1) {
      final current = _flocks[index];
      final newCount = (current.currentCount - deadCount).clamp(0, current.initialCount);
      _flocks[index] = current.copyWith(currentCount: newCount);
      _repo.updateFlockCountLocally(flockId, newCount);
      notifyListeners();
    }
  }

  /// US-FLOCK-002 — Clôture d'un lot. RM7 : plus de saisie possible après clôture.
  Future<bool> closeFlock(String flockId) async {
    try {
      final updated = await _repo.closeFlock(flockId);
      if (updated != null) {
        final idx = _flocks.indexWhere((f) => f.id == flockId);
        if (idx != -1) {
          _flocks[idx] = updated;
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
