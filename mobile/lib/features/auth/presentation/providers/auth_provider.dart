import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/features/auth/data/models/user_model.dart';
import 'package:avicoleguard_mobile/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _repo.currentUser;

  AuthProvider(this._repo);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _formatDioError(DioException e, String defaultMessage) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        final buffer = StringBuffer();
        data.forEach((key, value) {
          String fieldName = key.toString();
          if (fieldName == 'username') fieldName = "Nom d'utilisateur";
          if (fieldName == 'email') fieldName = "Email";
          if (fieldName == 'password') fieldName = "Mot de passe";
          if (fieldName == 'password_confirm') fieldName = "Confirmation";
          if (fieldName == 'detail') fieldName = "Détail";

          if (value is List && value.isNotEmpty) {
            buffer.writeln('$fieldName : ${value.join(" ")}');
          } else {
            buffer.writeln('$fieldName : $value');
          }
        });
        final formatted = buffer.toString().trim();
        if (formatted.isNotEmpty) return formatted;
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Impossible de joindre le serveur Django (${ApiEndpoints.baseUrl}).\nAssurez-vous que le backend est lancé.';
    }

    return e.message != null && e.message!.isNotEmpty
        ? 'Erreur réseau : ${e.message}'
        : defaultMessage;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repo.login(username, password);
      _isAuthenticated = user != null;
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _formatDioError(e, 'Identifiants invalides ou compte inactif.');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Une erreur inattendue est survenue : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      _isAuthenticated = user != null;
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _formatDioError(e, "Erreur lors de l'inscription.");
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur inattendue : $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _repo.logout();
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _isAuthenticated = await _repo.isAuthenticated();
    if (_isAuthenticated) {
      await _repo.fetchCurrentUser();
    }
    notifyListeners();
  }
}
