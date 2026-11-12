import 'package:flutter/foundation.dart';
import 'package:avicoleguard_mobile/features/mortality/data/models/mortality_model.dart';
import 'package:avicoleguard_mobile/features/mortality/data/repositories/mortality_repository.dart';

class MortalityProvider extends ChangeNotifier {
  final MortalityRepository _repo;

  List<MortalityModel> _mortalities = [];
  bool _isLoading = false;
  String? _errorMessage;

  MortalityProvider(this._repo) {
    loadCached();
  }

  List<MortalityModel> get mortalities => _mortalities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get todayDeadCount {
    final now = DateTime.now();
    return _mortalities
        .where((m) =>
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.date.day == now.day &&
            !m.isCancelled)
        .fold(0, (sum, m) => sum + m.deadCount);
  }

  void loadCached([String? flockId]) {
    _mortalities = _repo.getCachedMortalities(flockId);
    notifyListeners();
  }

  Future<void> refresh([String? flockId]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mortalities = await _repo.fetchMortalities(flockId);
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des mortalités.';
      loadCached(flockId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MortalityModel?> addMortality({
    required String flockId,
    String? flockReference,
    required DateTime date,
    required int deadCount,
    String presumedCause = '',
    String notes = '',
  }) async {
    try {
      final m = await _repo.recordMortality(
        flockId: flockId,
        flockReference: flockReference,
        date: date,
        deadCount: deadCount,
        presumedCause: presumedCause,
        notes: notes,
      );
      _mortalities.insert(0, m);
      notifyListeners();
      return m;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// RM11 — Annulation tracée d'une mortalité. Met à jour l'état local immédiatement.
  Future<bool> cancelMortality({
    required String flockId,
    required String mortalityId,
    required String reason,
  }) async {
    try {
      final updated = await _repo.cancelMortality(
        flockId: flockId,
        mortalityId: mortalityId,
        reason: reason,
      );
      if (updated != null) {
        final idx = _mortalities.indexWhere((m) => m.id == mortalityId);
        if (idx != -1) {
          _mortalities[idx] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
