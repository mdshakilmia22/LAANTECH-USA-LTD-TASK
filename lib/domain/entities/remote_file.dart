import 'package:equatable/equatable.dart';

class RemoteFile extends Equatable {
  final int id;
  final String name;
  final String originalName;
  final int size;
  final String type;
  final String uploadedAt;
  final String url;

  const RemoteFile({
    required this.id,
    required this.name,
    required this.originalName,
    required this.size,
    required this.type,
    required this.uploadedAt,
    required this.url,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    originalName,
    size,
    type,
    uploadedAt,
    url,
  ];
}
