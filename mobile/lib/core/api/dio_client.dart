import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  DioClient({
    Dio? dio,
    SecureStorageService? secureStorage,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        _secureStorage = secureStorage ?? SecureStorageService() {
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Injection automatique du token JWT d'accès si disponible
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Gestion du rafraîchissement automatique en cas de 401 (token expiré)
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/token/')) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Re-tentative de la requête initiale avec le nouveau token
              final newToken = await _secureStorage.getAccessToken();
              final opts = Options(
                method: error.requestOptions.method,
                headers: {
                  ...error.requestOptions.headers,
                  'Authorization': 'Bearer $newToken',
                },
              );
              try {
                final response = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              // Échec du refresh -> nettoyage de session
              await _secureStorage.clearAll();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final tokenDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await tokenDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccess = response.data['access'] as String?;
        if (newAccess != null) {
          await _secureStorage.updateAccessToken(newAccess);
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
