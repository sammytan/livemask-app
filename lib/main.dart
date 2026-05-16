import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/home_page.dart';
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
    // Load cached config on startup — non-blocking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(configStateProvider.notifier).loadCached();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveMask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
