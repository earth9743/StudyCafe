import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/features/auth/presentation/screens/login_screen.dart';
import 'package:kagong_map/features/auth/presentation/screens/agreement_screen.dart';
import 'package:kagong_map/features/map/presentation/screens/map_screen.dart';
import 'package:kagong_map/features/profile/presentation/screens/my_page_screen.dart';
import 'package:kagong_map/features/splash/presentation/screens/splash_screen.dart';

/// Firebase Auth 상태 변경을 GoRouter의 refreshListenable로 전달하는 브릿지.
/// GoRouter는 이 Listenable이 notify할 때마다 redirect를 재평가한다.
/// GoRouter 인스턴스를 재생성하지 않으므로 앱이 재시작되지 않는다.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  _AuthChangeNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();

  // Provider가 해제될 때 리스너 정리
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // 스플래시 화면은 리다이렉트 제외
      if (state.matchedLocation == '/splash') return null;

      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isOnLogin = state.matchedLocation == '/login';

      // 비로그인 사용자도 지도 화면(/) 접근 가능
      // 로그인 상태에서 로그인 화면 접근 시에만 지도로 리다이렉트
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
      GoRoute(
        path: '/mypage',
        builder: (context, state) => const MyPageScreen(),
      ),
    ],
  );
});
