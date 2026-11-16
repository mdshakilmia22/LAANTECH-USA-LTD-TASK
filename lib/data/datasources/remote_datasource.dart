import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

class RemoteDataSource {
  final Dio dio;

  RemoteDataSource(this.dio);

  Future<(UserModel user, String token)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.token,
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>? ?? data;
        final user = UserModel.fromJson(userJson);
        final token = data['token'] as String? ?? '';
        return (user, token);
      } else {
        throw ServerException(
          response.statusMessage ?? 'Login failed',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map) {
        final map = e.response?.data as Map<String, dynamic>;
        errorMessage = map['error'] as String? ?? map['message'] as String?;
      }
      throw ServerException(
        errorMessage ?? e.message ?? 'Invalid username or password',
        e.response?.statusCode,
      );
    }
  }

  Future<(UserModel user, String token)> register({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>? ?? data;
        final user = UserModel.fromJson(userJson);
        final token = data['token'] as String? ?? '';
        return (user, token);
      } else {
        throw ServerException(
          response.statusMessage ?? 'Registration failed',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map) {
        final map = e.response?.data as Map<String, dynamic>;
        errorMessage = map['error'] as String? ?? map['message'] as String?;
      }
      throw ServerException(
        errorMessage ?? e.message ?? 'Registration failed',
        e.response?.statusCode,
      );
    }
  }

  Future<void> logout(String token) async {
    try {
      await dio.post(
        ApiConstants.logout,
        options: Options(
          headers: {
            ApiConstants.authorization: '${ApiConstants.bearer} $token',
          },
        ),
      );
    } on DioException catch (_) {}
  }
}
