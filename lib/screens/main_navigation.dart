import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';

/// ボトムナビゲーション：ホーム / 履歴
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.self_improvement_outlined), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: '履歴'),
        ],
      ),
    );
  }
}
