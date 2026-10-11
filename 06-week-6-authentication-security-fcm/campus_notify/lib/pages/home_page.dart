import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../messaging/push_service.dart';
import '../providers/auth_providers.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await requestNotificationPermission();
    if (mounted) {
      setState(() => _permissionGranted = granted);
    }
  }

  String _formatToken(String? token) {
    if (token == null || token.isEmpty) return 'Belum tersedia';
    return token.length <= 12 ? token : '${token.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context) {
    final fcmToken = ref.watch(fcmTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: Icon(
                            _permissionGranted
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: _permissionGranted ? Colors.green : Colors.orange,
                          ),
                          title: const Text('Izin Notifikasi'),
                          subtitle: Text(
                            _permissionGranted ? 'Diizinkan' : 'Belum diizinkan',
                          ),
                          trailing: !_permissionGranted
                              ? TextButton(
                                  onPressed: _checkPermission,
                                  child: const Text('Izinkan'),
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.vpn_key),
                          title: const Text('FCM Token (Debug)'),
                          subtitle: Text(
                            _formatToken(fcmToken),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          dense: true,
                          leading: Icon(Icons.campaign),
                          title: Text('Topik'),
                          subtitle: Text('pengumuman-kampus'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.announcement('3')),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Lihat Pengumuman #3'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
