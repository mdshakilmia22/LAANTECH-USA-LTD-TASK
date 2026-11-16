import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/remote_file_model.dart';

class TransferRemoteDataSource {
  final Dio dio;

  TransferRemoteDataSource(this.dio);

  Future<List<RemoteFileModel>> getFiles(String token) async {
    try {
      final response = await dio.get(
        ApiConstants.getFiles,
        options: Options(
          headers: {
            ApiConstants.authorization: '${ApiConstants.bearer} $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final fileList = data['files'] as List<dynamic>? ?? [];
        return fileList
            .map((e) => RemoteFileModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          response.statusMessage ?? 'Failed to get files',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ServerException(
          'Network connection error while connecting to server. Please check your internet connection.',
          e.response?.statusCode,
        );
      }
      throw ServerException(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.message ??
            'Network error',
        e.response?.statusCode,
      );
    }
  }

  Future<RemoteFileModel> uploadFile({
    required String token,
    required String filePath,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ServerException('Local file not found at $filePath');
      }

      final fileName = file.path.split(RegExp(r'[/\\]')).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await dio.post(
        ApiConstants.upload,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            ApiConstants.authorization: '${ApiConstants.bearer} $token',
          },
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final fileJson = data['file'] as Map<String, dynamic>;
        return RemoteFileModel.fromJson(fileJson);
      } else {
        throw ServerException(
          response.statusMessage ?? 'Upload failed',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw ServerException('Upload paused by user', 499);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ServerException(
          'Network connection interrupted during upload. Please check connection and retry.',
          e.response?.statusCode,
        );
      }
      throw ServerException(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.message ??
            'Upload failed',
        e.response?.statusCode,
      );
    }
  }

  Future<String> downloadFile({
    required String token,
    required String fileName,
    required String savePath,
    required int startBytes,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    IOSink? sink;
    try {
      final headers = <String, dynamic>{
        ApiConstants.authorization: '${ApiConstants.bearer} $token',
      };

      if (startBytes > 0) {
        headers['Range'] = 'bytes=$startBytes-';
      }

      // Handle whether fileName is a query param name or full url
      final String requestUrl;
      final Map<String, dynamic>? queryParams;
      if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
        requestUrl = fileName;
        queryParams = null;
      } else {
        requestUrl = ApiConstants.getFiles;
        queryParams = {'file': fileName};
      }

      final response = await dio.get<ResponseBody>(
        requestUrl,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(headers: headers, responseType: ResponseType.stream),
      );

      final statusCode = response.statusCode ?? 500;
      if (statusCode == 200 || statusCode == 206) {
        final file = File(savePath);
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }

        // If server returned 206, resume appending from startBytes.
        // If server returned 200, it didn't support Range, so write from beginning.
        final isPartial = statusCode == 206;
        final actualStart = isPartial ? startBytes : 0;

        sink = file.openWrite(
          mode: actualStart > 0 ? FileMode.append : FileMode.write,
        );

        final contentLengthHeader = response.headers.value(
          HttpHeaders.contentLengthHeader,
        );
        final totalContentLength =
            int.tryParse(contentLengthHeader ?? '0') ?? 0;
        final totalBytes = actualStart + totalContentLength;

        int receivedBytes = actualStart;

        final stream = response.data!.stream;
        await for (final chunk in stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          onProgress(
            receivedBytes,
            totalBytes > receivedBytes ? totalBytes : receivedBytes,
          );
        }

        await sink.flush();
        return savePath;
      } else {
        throw ServerException(
          response.statusMessage ?? 'Download failed with status $statusCode',
          statusCode,
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw ServerException('Download paused by user', 499);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ServerException(
          'Network connection interrupted during download. You can resume anytime.',
          e.response?.statusCode,
        );
      }
      throw ServerException(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.message ??
            'Download failed',
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    } finally {
      await sink?.close();
    }
  }

  Future<bool> deleteFile({
    required String token,
    required String fileName,
  }) async {
    try {
      final response = await dio.delete(
        ApiConstants.delete,
        queryParameters: {'file': fileName},
        options: Options(
          headers: {
            ApiConstants.authorization: '${ApiConstants.bearer} $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          response.statusMessage ?? 'Delete failed',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.message ??
            'Delete failed',
        e.response?.statusCode,
      );
    }
  }
}
