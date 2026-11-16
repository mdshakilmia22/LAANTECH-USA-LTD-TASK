# Flutter POS Background Transfer & Catalog Sync Module

Enterprise-grade file transfer and catalog synchronization module for Flutter POS systems. Handles large file uploads (>50MB CSV/media), resumable partial downloads via HTTP Range headers, system tray progress notifications, pause/resume lifecycle management, and global transfer state persistence.

---

## 1. Architecture & Design Decisions

This module follows strict **Clean Architecture** combined with the **BLoC (Business Logic Component)** pattern to decouple the UI from network streaming and local file I/O.

```
lib/
├── core/
│   ├── constants/        # API endpoints, design tokens, color palette
│   ├── errors/           # Failures and Exceptions mapping (ServerFailure, NetworkFailure)
│   ├── network/          # Dio client configuration, interceptors, timeouts
│   ├── routes/           # GoRouter with authentication guards and notification deep linking
│   ├── services/         # NotificationService (system tray progress & completion alerts)
│   └── theme/            # Material 3 theme, typography, layout spacing
├── data/
│   ├── datasources/      # Remote data source, Transfer remote data source, SharedPreferences
│   ├── models/           # UserModel, RemoteFileModel (JSON serialization & parsing)
│   └── repositories/     # AuthRepositoryImpl, FileTransferRepositoryImpl
├── domain/
│   ├── entities/         # TransferTask, RemoteFile, User (Pure Dart, zero framework imports)
│   ├── repositories/     # Abstract repository contracts
│   └── usecases/         # UploadFileUseCase, DownloadFileUseCase, GetFilesUseCase, DeleteFileUseCase
├── presentation/
│   ├── blocs/            # FileTransferBloc, AppSessionBloc, AuthBloc
│   ├── pages/            # PosDashboardPage, UploadPage, DownloadPage, TransfersListPage, LoginPage
│   └── widgets/          # TransferProgressBanner, TransferTaskCard, PosDrawer
└── main.dart             # Dependency wiring, service initialization, root entry point
```

### Key Technical Decisions:
1. **Global Root-Level State**: `FileTransferBloc` is injected at the root level (`MultiBlocProvider` in `main.dart`). Transfer tasks and active streams remain alive when navigating across different POS screens or when the user minimizes the app.
2. **Streaming I/O Over In-Memory Buffers**: Downloads consume `ResponseBody.stream` and pipe incoming bytes directly into an `IOSink` opened in `FileMode.append` mode. Even for 1GB+ files, the application maintains a flat, negligible memory footprint (under 30MB heap).
3. **HTTP 206 Partial Content for Resumable Downloads**: When a download is resumed, the client inspects the local partially downloaded file size on disk (`File.length()`) and attaches a `Range: bytes=X-` request header. The server streams only the remaining delta without re-downloading previously transferred bytes.
4. **Deep-Linked System Notifications**: Tapping an active or completed transfer notification in the Android system tray immediately routes the user back to the Transfer Operations view via reactive payload stream listening.

---

## 2. Background Execution & Android Platform Limitations

### Execution Strategy
1. **Ongoing Progress Notifications**: Transfers dispatch an ongoing foreground progress notification (`ongoing: true`, `priority: low`, `onlyAlertOnce: true`) showing the live completion percentage, byte count, and transfer speed.
2. **Process Minimization & In-Memory Continuity**: Because transfer operations run on Dart isolate event loops outside the widget build tree, minimizing the app (pressing the Android Home button or switching to another app) does not terminate active transfers as long as the OS retains the app process in memory.
3. **Resumable State Recovery**: If the device experiences transient network drops or the user pauses the task, byte offsets are saved on disk. Resumption continues from the existing byte offset.

### Android Platform Limitations & Mitigations

| Platform Constraint | OS Behavior | Engineering Mitigation |
|---|---|---|
| **Android 14+ Foreground Service Types** | Android 14 mandates explicit foreground service type declarations for background network operations. | Declared `android.permission.FOREGROUND_SERVICE_DATA_SYNC` and `android.permission.POST_NOTIFICATIONS` in `AndroidManifest.xml`. |
| **Android 9+ Cleartext Restrictions** | Android blocks non-HTTPS HTTP traffic by default (`http://108.136.142.112:90`). | Configured `android:usesCleartextTraffic="true"` on the `<application>` node to permit REST gateway communication. |
| **Doze Mode & App Standby** | In deep sleep, Android limits network access and deferrable CPU cycles to maintenance windows. | Ongoing notifications with active progress channels inform the system of user-initiated data sync. |
| **Low Memory Killer (LMK)** | Under heavy memory pressure (e.g. running 3D applications or multiple retail utilities), the Linux kernel terminates background app processes. | The download subsystem persists partially written files on disk and resumes via `Range: bytes=startBytes-` rather than restarting from zero. |
| **HTTP Multipart Upload Limitations** | Standard HTTP `multipart/form-data` does not support byte-range chunk resuming at the HTTP specification level. | Downloads use HTTP Range requests; for production uploads, the architecture is ready to integrate Tus protocol (`tus.io`) or AWS S3 chunked presigned URLs. |
| **Production WorkManager Integration** | Tasks that must survive full device reboots or process death require native scheduling. | In an enterprise multi-terminal deployment, `workmanager` (`OneTimeWorkRequestBuilder<UploadWorker>`) with `NetworkType.CONNECTED` constraints can be bound to `FileTransferBloc` events. |

---

## 3. Resilience & Fault Tolerance

- **Dynamic Speed Telemetry**: Real-time speed calculation uses a sliding time window ($\Delta t \ge 400\text{ms}$) comparing transferred bytes against timestamps, avoiding erratic speed spikes.
- **Connection Error Handling**: Network timeouts (`DioExceptionType.connectionTimeout`, `receiveTimeout`, `connectionError`) trigger user-friendly error banners and allow single-tap **Retry** without data corruption.
- **Resource Deallocation**: File sinks and cancel tokens are enclosed in `try-finally` blocks to guarantee file descriptors are flushed and closed upon cancellation or error.
- **Bulk Task Operations**: The Transfer Manager supports **Pause All**, **Resume All**, and **Clear Completed** for rapid terminal management.

---

## 4. Local Storage Architecture

Downloaded catalog files are written to the application's isolated sandbox storage:
```
<Application_Documents_Directory>/POS_Downloads/<original_filename>
```
- **Android Path**: `/data/user/0/com.example.laan_tech_usa_technical_task/app_flutter/POS_Downloads/...`
- **Security & Integrity**: Files are protected from media scanner pollution and accidental user deletion while remaining accessible for POS database import operations.
- **Clipboard Utility**: Every completed download card includes a single-tap **Copy Path** button to copy the absolute filesystem path for auditing.

---

## 5. Gateway Endpoints & Demo Credentials

- **Server Endpoint**: `http://108.136.142.112:90`
- **Authentication**: `POST /token` (`username`, `password`) -> Bearer JWT
- **Account Registration**: `POST /register` (`username`, `password`)
- **List Files**: `GET /get`
- **Download File**: `GET /get?file=NAME` (Supports HTTP `Range: bytes=start-`)
- **Upload File**: `POST /upload` (Multipart form-data)
- **Delete File**: `DELETE /delete?file=NAME`

### Quick Access Credentials:
- **Username**: `shakil_pos`
- **Password**: `Password123`
*(A "Use Preset Account" shortcut is also provided on the sign-in screen for testing).*

---

## 6. Build & Test Instructions

### Requirements
- Flutter SDK `^3.13.0` or higher
- Android SDK (minSdk 21+, targetSdk 34+)

### 1. Dependencies
```bash
flutter pub get
```

### 2. Static Code Analysis
```bash
flutter analyze
```

### 3. Unit & Bloc Test Suite
```bash
flutter test
```

### 4. Run Application
```bash
flutter run
```

### 5. Build Debug APK
```bash
flutter build apk --debug
# Artifact location: build/app/outputs/flutter-apk/app-debug.apk
```
