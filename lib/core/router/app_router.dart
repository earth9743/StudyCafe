import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/auth/presentation/screens/login_screen.dart';
import 'package:kagong_map/features/auth/presentation/screens/agreement_screen.dart';
import 'package:kagong_map/features/map/presentation/screens/map_screen.dart';
import 'package:kagong_map/features/splash/presentation/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // 스플래시 화면은 리다이렉트 제외
      if (state.matchedLocation == '/splash') return null;

      final isLoggedIn = authState.value != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/agreement',
        builder: (context, state) => const AgreementScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MapScreen(),
      ),
    ],
  );
});
