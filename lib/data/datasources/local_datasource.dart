import '../models/user_model.dart';

abstract class LocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();

  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearUser();

  Future<void> clearAll();
}
