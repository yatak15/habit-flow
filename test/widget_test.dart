import 'package:flutter_test/flutter_test.dart';
import 'package:habit_flow/services/task_service.dart';
import 'package:habit_flow/main.dart';

void main() {
  testWidgets('Habit Flow app loads home screen', (WidgetTester tester) async {
    final service = TaskService();
    await service.init();

    await tester.pumpWidget(HabitFlowApp(taskService: service));
    await tester.pumpAndSettle();

    expect(find.text('Habit Flow'), findsOneWidget);
  });
}
