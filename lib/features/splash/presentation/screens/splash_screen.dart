import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // 네이티브 스플래시 제거
    FlutterNativeSplash.remove();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // 2초 후 지도 화면으로 이동 (비로그인 사용자도 바로 지도 접근 가능)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF19376D),
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SvgPicture.asset(
            'assets/images/splash_logo.svg',
            width: MediaQuery.of(context).size.width * 0.55,
          ),
        ),
      ),
    );
  }
}
