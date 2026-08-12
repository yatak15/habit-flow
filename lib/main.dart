import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'models/task.dart';
import 'models/completion_log.dart';
import 'services/task_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CompletionLogAdapter());

  await initializeDateFormatting('ja_JP');

  final taskService = TaskService();
  await taskService.init();

  // アプリ起動中は画面を常にオンに保つ
  await WakelockPlus.enable();

  runApp(HabitFlowApp(taskService: taskService));
}

class HabitFlowApp extends StatefulWidget {
  final TaskService taskService;
  const HabitFlowApp({super.key, required this.taskService});

  @override
  State<HabitFlowApp> createState() => _HabitFlowAppState();
}

class _HabitFlowAppState extends State<HabitFlowApp> with WidgetsBindingObserver {
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
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.taskService,
      child: MaterialApp(
        title: 'Habit Flow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainNavigation(),
      ),
    );
  }
}
