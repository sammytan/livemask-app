import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/auth_models.dart';
import 'pages/config_debug_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'providers/auth_providers.dart';
import 'providers/config_providers.dart';

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
      // Load cached config on startup — non-blocking.
      ref.read(configStateProvider.notifier).loadCached();
      // Attempt to restore auth session.
      ref.read(authStateProvider.notifier).tryRestoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'LiveMask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashShell(
              child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: Colors.indigo,
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
            ),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/config-debug': (context) => const ConfigDebugPage(),
      },
      // Handle initial routing based on auth state.
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

    return _AuthGate(authState: authState);
  }
}

/// Listens to [authState] and shows the correct screen.
/// While loading, show a splash; once resolved, show login or home.
class _AuthGate extends ConsumerWidget {
  const _AuthGate({required this.authState});

  final AuthNotifierState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 80, color: Colors.indigo),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('LiveMask'),
            ],
          ),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const HomePage();
    }

    return const LoginPage();
  }
}

/// Simple shell widget that passes the child through.
class SplashShell extends StatelessWidget {
  const SplashShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
