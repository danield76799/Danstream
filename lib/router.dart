import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/player_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PlayerPage(
          title: extra?['title'] ?? 'Afspelen',
          streamUrl: extra?['streamUrl'] ?? '',
        );
      },
    ),
  ],
);
