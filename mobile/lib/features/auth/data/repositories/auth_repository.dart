import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/core/storage/secure_storage_service.dart';
import 'package:avicoleguard_mobile/features/auth/data/models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;

  AuthRepository({
    DioClient? dioClient,
    SecureStorageService? secureStorage,
  })  : _dioClient = dioClient ?? DioClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final access = response.data['access'] as String?;
        final refresh = response.data['refresh'] as String?;

        if (access != null && refresh != null) {
          await _secureStorage.saveTokens(
            accessToken: access,
            refreshToken: refresh,
          );
        }

        // Fetch user profile from /auth/me/
        return await fetchCurrentUser();
      }
    } on DioException catch (e) {
      // In case server is offline or connection fails, check if we have local cached user
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = getCachedUser();
        if (cached != null) {
          _currentUser = cached;
          return cached;
        }
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
    return null;
  }

  Future<UserModel?> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.register,
      data: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'phone': phone ?? '',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Auto-login after successful registration
      return await login(username, password);
    }
    return null;
  }

  Future<UserModel?> fetchCurrentUser() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.me);
      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        _currentUser = user;
        // Cache user in settings box
        await LocalStorageService.getSettingsBox()
            .put('cached_user', jsonEncode(user.toJson()));
        return user;
      }
    } catch (_) {
      // Return cached user if network failed
      final cached = getCachedUser();
      if (cached != null) {
        _currentUser = cached;
        return cached;
      }
    }
    return null;
  }

  UserModel? getCachedUser() {
    try {
      final data =
          LocalStorageService.getSettingsBox().get('cached_user') as String?;
      if (data != null) {
        return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> logout() async {
    try {
      final refresh = await _secureStorage.getRefreshToken();
      if (refresh != null) {
        await _dioClient.dio.post(
          ApiEndpoints.logout,
          data: {'refresh': refresh},
        );
      }
    } catch (_) {}
    await _secureStorage.clearAll();
    await LocalStorageService.getSettingsBox().delete('cached_user');
    _currentUser = null;
  }

  Future<bool> isAuthenticated() async {
    final hasToken = await _secureStorage.hasValidToken();
    if (hasToken) {
      _currentUser = getCachedUser();
    }
    return hasToken;
  }
}
