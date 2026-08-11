import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  runApp(HabitFlowApp(taskService: taskService));
}

class HabitFlowApp extends StatelessWidget {
  final TaskService taskService;
  const HabitFlowApp({super.key, required this.taskService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: taskService,
      child: MaterialApp(
        title: 'Habit Flow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainNavigation(),
      ),
    );
  }
}
