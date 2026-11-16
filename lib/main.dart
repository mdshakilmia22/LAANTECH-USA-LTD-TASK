import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_datasource_impl.dart';
import 'data/datasources/remote_datasource.dart';
import 'data/datasources/transfer_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/file_transfer_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/file_transfer_repository.dart';
import 'domain/usecases/check_session.dart';
import 'domain/usecases/delete_file_usecase.dart';
import 'domain/usecases/download_file_usecase.dart';
import 'domain/usecases/get_files_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/upload_file_usecase.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/file_transfer/file_transfer_bloc.dart';
import 'presentation/blocs/session/app_session_bloc.dart';
import 'presentation/blocs/session/app_session_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService.instance;
  await notificationService.initialize();

  final prefs = await SharedPreferences.getInstance();

  final dio = createDioClient();
  final remoteDataSource = RemoteDataSource(dio);
  final localDataSource = LocalDataSourceImpl(prefs);
  final transferRemoteDataSource = TransferRemoteDataSource(dio);

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );

  final fileTransferRepository = FileTransferRepositoryImpl(
    transferRemoteDataSource,
  );

  final checkSession = CheckSession(authRepository);
  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);

  final getFilesUseCase = GetFilesUseCase(fileTransferRepository);
  final uploadFileUseCase = UploadFileUseCase(fileTransferRepository);
  final downloadFileUseCase = DownloadFileUseCase(fileTransferRepository);
  final deleteFileUseCase = DeleteFileUseCase(fileTransferRepository);

  final appSessionBloc = AppSessionBloc(checkSession: checkSession);
  appSessionBloc.add(const AppSessionCheckRequested());

  final fileTransferBloc = FileTransferBloc(
    getFilesUseCase: getFilesUseCase,
    uploadFileUseCase: uploadFileUseCase,
    downloadFileUseCase: downloadFileUseCase,
    deleteFileUseCase: deleteFileUseCase,
    notificationService: notificationService,
  );

  runApp(
    MyApp(
      authRepository: authRepository,
      fileTransferRepository: fileTransferRepository,
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
      appSessionBloc: appSessionBloc,
      fileTransferBloc: fileTransferBloc,
      sharedPreferences: prefs,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.authRepository,
    required this.fileTransferRepository,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.appSessionBloc,
    required this.fileTransferBloc,
    required this.sharedPreferences,
  });

  final AuthRepository authRepository;
  final FileTransferRepository fileTransferRepository;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final AppSessionBloc appSessionBloc;
  final FileTransferBloc fileTransferBloc;
  final SharedPreferences sharedPreferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeModeNotifier _themeNotifier;
  StreamSubscription<String>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeModeNotifier(widget.sharedPreferences);

    _notificationSub = NotificationService.instance.selectNotificationStream
        .listen((route) {
          AppRouter.navigateTo(route);
        });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.authRepository),
        RepositoryProvider<FileTransferRepository>.value(
          value: widget.fileTransferRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppSessionBloc>.value(value: widget.appSessionBloc),
          BlocProvider<FileTransferBloc>.value(value: widget.fileTransferBloc),
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              loginUseCase: widget.loginUseCase,
              registerUseCase: widget.registerUseCase,
              authRepository: widget.authRepository,
            ),
          ),
        ],
        child: ThemeScope(
          notifier: _themeNotifier,
          child: ListenableBuilder(
            listenable: _themeNotifier,
            builder: (context, _) {
              return MaterialApp.router(
                title: 'LAAN TECH POS File Transfer',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: _themeNotifier.value,
                routerConfig: AppRouter.router(widget.appSessionBloc),
              );
            },
          ),
        ),
      ),
    );
  }
}
