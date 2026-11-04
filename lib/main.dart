import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DanstreamApp());
}

class DanstreamApp extends StatelessWidget {
  const DanstreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSavedCredentials()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ],
      child: MaterialApp.router(
        title: 'Danstream',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF0DBD8B),
            secondary: const Color(0xFF0DBD8B),
            surface: const Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F0F0F),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF1A1A1A),
            indicatorColor: const Color(0xFF0DBD8B).withOpacity(0.2),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
