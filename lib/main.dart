import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart' show FlutterNaverMap;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 네이티브 스플래시를 Flutter 스플래시 화면이 준비될 때까지 유지
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Firebase 초기화
    debugPrint('[Init] Firebase 초기화 시작');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Init] Firebase 초기화 완료');

    // iOS: 앱 재설치 시 Keychain에 남아있는 Firebase 세션 정리
    await _handleFirstLaunch();

    // 카카오 SDK 초기화
    KakaoSdk.init(nativeAppKey: AppConstants.kakaoNativeKey);
    debugPrint('[Init] 카카오 SDK 초기화 완료');

    // 네이버 지도 SDK 초기화
    debugPrint('[Init] 네이버 지도 SDK 초기화 시작');
    await FlutterNaverMap().init(clientId: 'df7ggcsnru');
    debugPrint('[Init] 네이버 지도 SDK 초기화 완료');
  } catch (e, st) {
    debugPrint('[Init] SDK 초기화 오류: $e');
    debugPrint('[Init] 스택트레이스: $st');
  }

  runApp(
    const ProviderScope(
      child: KagongMapApp(),
    ),
  );
}

/// 앱 첫 실행 감지 → iOS Keychain에 남아있는 Firebase 세션 정리
/// iOS에서 앱을 삭제해도 Keychain은 유지되므로, 재설치 시 로그인 화면이 안 나오는 문제 해결
Future<void> _handleFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final hasLaunched = prefs.getBool('has_launched') ?? false;

  if (!hasLaunched) {
    debugPrint('[Init] 첫 실행 감지 - Firebase 로그아웃 처리');
    await FirebaseAuth.instance.signOut();
    await prefs.setBool('has_launched', true);
  }
}

class KagongMapApp extends ConsumerWidget {
  const KagongMapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
