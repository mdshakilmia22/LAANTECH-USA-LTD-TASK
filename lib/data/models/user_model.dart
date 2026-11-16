import '../../core/helpers/json_value.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final username = parseJsonString(json['username']);
    final name = parseJsonString(json['name']);
    final email = parseJsonString(json['email']);

    return UserModel(
      id: parseJsonInt(json['id']),
      name: name.isNotEmpty
          ? name
          : (username.isNotEmpty ? username : 'POS User'),
      email: email.isNotEmpty
          ? email
          : (username.isNotEmpty ? username : 'user@example.com'),
      avatar: json['avatar'] != null ? parseJsonString(json['avatar']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'avatar': avatar};
  }

  User toEntity() {
    return User(id: id, name: name, email: email, avatar: avatar);
  }
}
