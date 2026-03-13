import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/auth/presentation/widgets/social_login_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // 로고 & 앱 이름
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: AppColors.textOnPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '카공지도',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '카페에서 공부하는 당신을 위한\n실시간 카페 정보',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // 소셜 로그인 버튼들
              SocialLoginButton(
                type: SocialLoginType.kakao,
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithKakao(),
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                type: SocialLoginType.google,
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
              ),

              const SizedBox(height: 24),

              if (isLoading)
                const CircularProgressIndicator(
                  color: AppColors.primary,
                ),

              const Spacer(flex: 2),

              // 하단 안내
              Text(
                '로그인 시 서비스 이용약관 및 개인정보처리방침에\n동의하게 됩니다.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
