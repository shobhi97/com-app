import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bell/presentation/screens/bell_feed_screen.dart';
import '../../../meet/presentation/screens/sessions_screen.dart';
import '../../../charts/presentation/screens/charts_screen.dart';
import '../../../recordings/presentation/screens/recordings_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = [
    BellFeedScreen(),
    SessionsScreen(),
    ChartsScreen(),
    RecordingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications_rounded), label: 'Bells'),
          NavigationDestination(icon: Icon(Icons.video_call_outlined), selectedIcon: Icon(Icons.video_call_rounded), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart_rounded), label: 'Charts'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie_rounded), label: 'Recordings'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
