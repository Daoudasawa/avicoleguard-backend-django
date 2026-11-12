import 'package:flutter/foundation.dart';
import 'package:avicoleguard_mobile/features/observations/data/models/observation_model.dart';
import 'package:avicoleguard_mobile/features/observations/data/repositories/observation_repository.dart';

class ObservationProvider extends ChangeNotifier {
  final ObservationRepository _repo;

  List<ObservationModel> _observations = [];
  bool _isLoading = false;
  String? _errorMessage;

  ObservationProvider(this._repo);

  List<ObservationModel> get observations => _observations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ObservationModel> forFlock(String flockId) =>
      _observations.where((o) => o.flockId == flockId).toList();

  Future<void> refresh(String flockId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _observations = await _repo.fetchObservations(flockId);
    } catch (e) {
      _errorMessage = 'Erreur chargement observations.';
      _observations = _repo.getCachedObservations(flockId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ObservationModel?> addObservation({
    required String flockId,
    required DateTime date,
    required String type,
    String description = '',
  }) async {
    try {
      final obs = await _repo.addObservation(
        flockId: flockId,
        date: date,
        type: type,
        description: description,
      );
      _observations.insert(0, obs);
      notifyListeners();
      return obs;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// RM11 — Annulation tracée d'une observation. Met à jour l'état local.
  Future<bool> cancelObservation({
    required String flockId,
    required String observationId,
    required String reason,
  }) async {
    try {
      final updated = await _repo.cancelObservation(
        flockId: flockId,
        observationId: observationId,
        reason: reason,
      );
      if (updated != null) {
        final idx = _observations.indexWhere((o) => o.id == observationId);
        if (idx != -1) {
          _observations[idx] = updated;
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
