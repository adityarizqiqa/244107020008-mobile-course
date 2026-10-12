import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/format.dart';
import 'features/announcements/presentation/pages/announcement_detail_page.dart';
import 'features/announcements/presentation/pages/announcements_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRoutes {
  static const String notes = '/notes';
  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.notes,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.notes,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotesPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.announcements,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AnnouncementsPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.announcementDetail,
      builder: (context, state) {
        final id = parseIdFromRoute(state.uri.path) ?? 0;
        return AnnouncementDetailPage(id: id);
      },
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.announcements)) {
      return 1;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.notes);
        break;
      case 1:
        context.go(AppRoutes.announcements);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Pengumuman',
          ),
        ],
      ),
    );
  }
}
