import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:habit_flow/models/completion_log.dart';
import 'package:habit_flow/models/task.dart';
import 'package:habit_flow/services/sync_service.dart';
import 'package:habit_flow/services/task_service.dart';
import 'package:habit_flow/services/theme_service.dart';
import 'package:habit_flow/main.dart';

void main() {
  testWidgets('Habit Flow app loads home screen', (WidgetTester tester) async {
    Hive.init(Directory.systemTemp.createTempSync('habit_flow_test').path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CompletionLogAdapter());
    }
    final service = TaskService();
    await service.init();
    final themeService = ThemeService();
    await themeService.init();

    await tester.pumpWidget(
      HabitFlowApp(
        taskService: service,
        themeService: themeService,
        syncService: SyncService(service),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('今日も、\n静かに続ける。'), findsOneWidget);
  });
}
