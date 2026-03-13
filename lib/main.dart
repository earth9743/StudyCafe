import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart' show FlutterNaverMap;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: AppConstants.kakaoNativeKey);

  // 네이버 지도 SDK 초기화
  await FlutterNaverMap().init(clientId: 'df7ggcsnru');

  runApp(
    const ProviderScope(
      child: KagongMapApp(),
    ),
  );
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
