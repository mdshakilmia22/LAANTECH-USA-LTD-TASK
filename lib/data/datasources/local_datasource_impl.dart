import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'local_datasource.dart';

class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences sharedPreferences;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  LocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> saveToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await sharedPreferences.remove(_tokenKey);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await sharedPreferences.setString(_userKey, jsonStr);
  }

  @override
  Future<UserModel?> getUser() async {
    final jsonStr = sharedPreferences.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await sharedPreferences.remove(_userKey);
  }

  @override
  Future<void> clearAll() async {
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_userKey);
  }
}
