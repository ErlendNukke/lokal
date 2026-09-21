import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lokal/core/config.dart';
import 'package:lokal/screens/home_shell.dart';
import 'package:lokal/services/api_client.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/services/marketplace_service.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:provider/provider.dart';

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) {
    return kReleaseMode ? AppConfig.productionApiBaseUrl : 'http://localhost:8080';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:8080';
    default:
      return 'http://localhost:8080';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient(baseUrl: resolveApiBaseUrl());
  final auth = AuthService(api);
  await auth.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider.value(value: auth),
        Provider(create: (_) => MarketplaceService(api)),
      ],
      child: const LokalApp(),
    ),
  );
}

class LokalApp extends StatelessWidget {
  const LokalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokal',
      debugShowCheckedModeBanner: false,
      theme: buildLokalTheme(),
      home: const _BootGate(),
    );
  }
}

class _BootGate extends StatelessWidget {
  const _BootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeShell();
  }
}
