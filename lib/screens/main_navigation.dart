import 'package:flutter/material.dart';
import '../widgets/habit_flow_widgets.dart';
import 'home_screen.dart';
import 'history_screen.dart';

/// ボトムナビゲーション："Quiet Momentum" デザインの半透明ブラータブバー
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _pages = const [HomeScreen(), HistoryScreen()];

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
