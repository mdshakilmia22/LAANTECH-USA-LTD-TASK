import 'package:flutter_test/flutter_test.dart';
import 'package:laan_tech_usa_technical_task/data/models/remote_file_model.dart';
import 'package:laan_tech_usa_technical_task/data/models/user_model.dart';
import 'package:laan_tech_usa_technical_task/domain/entities/transfer_task.dart';

void main() {
  group('TransferTask Entity', () {
    test('creates TransferTask with initial values correctly', () {
      const task = TransferTask(
        id: 'upload_1',
        fileName: 'catalog.csv',
        filePath: '/tmp/catalog.csv',
        type: TransferType.upload,
        status: TransferStatus.transferring,
        totalBytes: 50000000,
        transferredBytes: 25000000,
        progress: 0.5,
        speedBytesPerSec: 1048576.0,
        notificationId: 101,
      );

      expect(task.id, 'upload_1');
      expect(task.fileName, 'catalog.csv');
      expect(task.type, TransferType.upload);
      expect(task.status, TransferStatus.transferring);
      expect(task.progress, 0.5);
      expect(task.speedBytesPerSec, 1048576.0);
    });

    test('copyWith updates fields correctly', () {
      const task = TransferTask(
        id: 'upload_1',
        fileName: 'catalog.csv',
        filePath: '/tmp/catalog.csv',
        type: TransferType.upload,
        status: TransferStatus.transferring,
        totalBytes: 50000000,
        transferredBytes: 25000000,
        progress: 0.5,
        speedBytesPerSec: 1048576.0,
        notificationId: 101,
      );

      final pausedTask = task.copyWith(
        status: TransferStatus.paused,
        speedBytesPerSec: 0.0,
      );

      expect(pausedTask.status, TransferStatus.paused);
      expect(pausedTask.speedBytesPerSec, 0.0);
      expect(pausedTask.id, 'upload_1');
      expect(pausedTask.progress, 0.5);
    });
  });

  group('RemoteFileModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 42,
        'name': 'test_catalog_1d58de28.csv',
        'original_name': 'test_catalog.csv',
        'size': 52428800,
        'type': 'text/csv',
        'uploaded_at': '2026-11-15T00:00:00+00:00',
        'url': 'http://108.136.142.112:90/get?file=test_catalog_1d58de28.csv',
      };

      final model = RemoteFileModel.fromJson(json);

      expect(model.id, 42);
      expect(model.name, 'test_catalog_1d58de28.csv');
      expect(model.originalName, 'test_catalog.csv');
      expect(model.size, 52428800);
      expect(model.type, 'text/csv');
      expect(model.url, contains('test_catalog_1d58de28.csv'));
    });
  });

  group('UserModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 17,
        'username': 'shakil_pos',
        'created_at': '2026-11-15T00:00:00+00:00',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 17);
      expect(user.name, 'shakil_pos');
    });
  });
}
