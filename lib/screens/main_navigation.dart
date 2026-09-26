import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/active_timer_store.dart';
import '../services/task_service.dart';
import '../widgets/habit_flow_widgets.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'timer_screen.dart';

/// ボトムナビゲーション："Quiet Momentum" デザインの半透明ブラータブバー
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _pages = const [HomeScreen(), HistoryScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreActiveTimer());
  }

  /// アプリがバックグラウンドでプロセスごと終了していた場合に備え、
  /// 実行中だったタイマーを起動直後に復元表示する
  Future<void> _restoreActiveTimer() async {
    final record = await ActiveTimerStore.load();
    if (record == null || !mounted) return;
    final task = context.read<TaskService>().getTask(record.taskId);
    if (task == null) {
      await ActiveTimerStore.clear();
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          task: task,
          memo: record.memo,
          minutes: record.minutes,
          isStopwatch: record.isStopwatch,
          resumeEndTime: record.isStopwatch ? null : record.referenceTime,
          resumeStartTime: record.isStopwatch ? record.referenceTime : null,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: HFTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
