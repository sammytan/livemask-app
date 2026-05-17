import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/auth_providers.dart';
import 'providers/config_providers.dart';
import 'providers/node_providers.dart';
import 'providers/billing_providers.dart';
import 'widgets/app_layout.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/nodes_screen.dart';
import 'screens/recommended_node_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/config_debug_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: LiveMaskApp(),
    ),
  );
}

class LiveMaskApp extends ConsumerStatefulWidget {
  const LiveMaskApp({super.key});

  @override
  ConsumerState<LiveMaskApp> createState() => _LiveMaskAppState();
}

class _LiveMaskAppState extends ConsumerState<LiveMaskApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(configStateProvider.notifier).loadCached();
      ref.read(authStateProvider.notifier).tryRestoreSession();
      ref.read(nodeListStateProvider.notifier).loadCached();
      ref.read(recommendedNodeStateProvider.notifier).loadCached();
      ref.read(billingPlansStateProvider.notifier).loadCached();
      ref.read(subscriptionStateProvider.notifier).loadCached();
      ref.read(billingHistoryStateProvider.notifier).loadCached();
      ref.read(devicesStateProvider.notifier).loadCached();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveMask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const _AppShell(),
    );
  }
}

/// Root shell that watches auth state and redirects accordingly.
class _AppShell extends ConsumerWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // While loading, show the splash screen
    if (authState.isLoading) {
      return const SplashScreen();
    }

    // Authenticated — show the main app shell with navigation
    if (authState.isAuthenticated) {
      return const _MainShell();
    }

    // Not authenticated — go to login
    return const _MainShell(isLoggedOut: true);
  }
}

/// Main app shell that manages navigation and screen switching.
class _MainShell extends ConsumerStatefulWidget {
  const _MainShell({this.isLoggedOut = false});

  final bool isLoggedOut;

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  String _currentPath = '/home';

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    // On first mount, redirect logged-out users to login
    if (widget.isLoggedOut && _currentPath != '/login') {
      // Use post-frame to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPath = '/login';
        });
      });
    }

    return AppLayout(
      currentPath: _currentPath,
      onNavigate: _navigateTo,
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentPath) {
      case '/login':
        return LoginScreen(onNavigate: _navigateTo);
      case '/register':
        return RegisterScreen(onNavigate: _navigateTo);
      case '/nodes':
        return NodesScreen(onNavigate: _navigateTo);
      case '/nodes/recommended':
        return const RecommendedNodeScreen();
      case '/plan':
        return const PlanScreen();
      case '/profile':
        return ProfileScreen(onLogout: () => _navigateTo('/login'));
      case '/diagnostics':
        return const DiagnosticsScreen();
      case '/config-debug':
        return const ConfigDebugScreen();
      case '/splash':
      case '/home':
      default:
        return HomeScreen(onNavigate: _navigateTo);
    }
  }
}
