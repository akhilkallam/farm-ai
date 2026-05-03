import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/connectivity_watcher.dart';
import 'core/theme.dart';
import 'features/auth/otp_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/history/history_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/voice_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FarmAIApp());
}

class FarmAIApp extends StatelessWidget {
  const FarmAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();
    final authService = AuthService();
    final apiService = ApiService(auth: authService);
    final syncService = SyncService(api: apiService, db: db);

    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<AuthService>.value(value: authService),
        Provider<ApiService>.value(value: apiService),
        Provider<VoiceService>(
          create: (_) => VoiceService(),
          dispose: (_, s) => s.dispose(),
        ),
        Provider<ConnectivityWatcher>(create: (_) => ConnectivityWatcher()),
        Provider<SyncService>.value(value: syncService),
      ],
      child: MaterialApp(
        title: 'FarmAI',
        theme: FarmAITheme.theme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthService>();
    final loggedIn = await auth.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isLoggedIn!) {
      return OtpScreen(onSuccess: () => setState(() => _isLoggedIn = true));
    }
    return const _MainShell();
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    ChatScreen(),
    DashboardScreen(),
    HistoryScreen(),
  ];

  static const _labels = ['Chat', 'Dashboard', 'History'];
  static const _icons = [Icons.chat_bubble_outline, Icons.dashboard_outlined, Icons.history];
  static const _activeIcons = [Icons.chat_bubble, Icons.dashboard, Icons.history];

  @override
  void initState() {
    super.initState();
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    try {
      final sync = context.read<SyncService>();
      final connectivity = context.read<ConnectivityWatcher>();
      if (await connectivity.isOnline) {
        await sync.flushQueue();
      }
    } catch (_) {
      // Sync errors are non-fatal — will retry on next launch
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🌱', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FarmAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Powered by Claude + MCP + RAG',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                SizedBox(width: 4),
                Text('All agents active',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: List.generate(
          3,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
