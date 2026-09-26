import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'models/task.dart';
import 'models/completion_log.dart';
import 'services/task_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 縦向き（ポートレート）に固定し、横向きへの回転を無効化する
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CompletionLogAdapter());

  await initializeDateFormatting('ja_JP');

  final taskService = TaskService();
  await taskService.init();

  final themeService = ThemeService();
  await themeService.init();

  // アカウント・端末間同期（Supabase 未設定の場合は何もしない）
  final syncService = SyncService(taskService);
  try {
    await syncService.init();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  // タイマー終了をバックグラウンドでも通知できるよう初期化しておく
  await NotificationService.instance.init();

  // アプリ起動中は画面を常にオンに保つ
  await WakelockPlus.enable();

  runApp(
    HabitFlowApp(
      taskService: taskService,
      themeService: themeService,
      syncService: syncService,
    ),
  );
}

class HabitFlowApp extends StatefulWidget {
  final TaskService taskService;
  final ThemeService themeService;
  final SyncService syncService;
  const HabitFlowApp({
    super.key,
    required this.taskService,
    required this.themeService,
    required this.syncService,
  });

  @override
  State<HabitFlowApp> createState() => _HabitFlowAppState();
}

class _HabitFlowAppState extends State<HabitFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンドに退避した際はWakelockを解除し、
    // フォアグラウンドに復帰した際は再度有効化する（バッテリー配慮）
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
      widget.syncService.sync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.taskService),
        ChangeNotifierProvider.value(value: widget.themeService),
        ChangeNotifierProvider.value(value: widget.syncService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) => MaterialApp(
          title: 'ととのね',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(themeService.backgroundColor),
          home: const MainNavigation(),
        ),
      ),
    );
  }
}
