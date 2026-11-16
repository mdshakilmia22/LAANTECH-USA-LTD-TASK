import '../../core/helpers/json_value.dart';
import '../../domain/entities/remote_file.dart';

class RemoteFileModel extends RemoteFile {
  const RemoteFileModel({
    required super.id,
    required super.name,
    required super.originalName,
    required super.size,
    required super.type,
    required super.uploadedAt,
    required super.url,
  });

  factory RemoteFileModel.fromJson(Map<String, dynamic> json) {
    return RemoteFileModel(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      originalName: parseJsonString(json['original_name'] ?? json['name']),
      size: parseJsonInt(json['size']),
      type: parseJsonString(json['type']),
      uploadedAt: parseJsonString(json['uploaded_at']),
      url: parseJsonString(json['url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_name': originalName,
      'size': size,
      'type': type,
      'uploaded_at': uploadedAt,
      'url': url,
    };
  }

  RemoteFile toEntity() {
    return RemoteFile(
      id: id,
      name: name,
      originalName: originalName,
      size: size,
      type: type,
      uploadedAt: uploadedAt,
      url: url,
    );
  }
}
