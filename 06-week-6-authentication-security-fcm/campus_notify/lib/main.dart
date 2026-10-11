import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_providers.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi local notifications untuk notifikasi foreground
  await initLocalNotifications();

  // Daftarkan background handler top-level
  registerBackgroundHandler();

  final container = ProviderContainer();

  // Inisialisasi Firebase & Token Lifecycle (Praktikum 2)
  try {
    await Firebase.initializeApp();
    await initFcmToken(
      onToken: (token) async {
        // Simpan token ke provider agar dapat ditampilkan di debug UI (terpotong)
        container.read(fcmTokenProvider.notifier).setToken(token);

        // Simulasi pengiriman token ke backend (POST /devices)
        debugPrint('[FCM] Token diperbarui & dikirim ke backend: ${token.substring(0, 12)}...');
      },
    );
  } catch (e) {
    debugPrint('[Firebase Init] Firebase belum siap atau google-services.json belum ada: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusNotifyApp(),
    ),
  );
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final loggedIn = authAsync.value ?? false;
      final goingLogin = state.matchedLocation == AppRoutes.login;

      // Guard route: jika belum login dan bukan di halaman login, arahkan ke login
      if (!loggedIn && !goingLogin) return AppRoutes.login;
      // Jika sudah login dan mencoba ke halaman login, kembalikan ke home
      if (loggedIn && goingLogin) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (context, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
});

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      listenForeground((route) => router.go(route));
      handleTerminated((route) => router.go(route));
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}