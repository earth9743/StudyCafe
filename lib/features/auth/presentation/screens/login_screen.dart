import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/auth/presentation/widgets/social_login_button.dart';

/// 에러 메시지를 사용자 친화적 메시지로 변환
/// 사용자가 직접 취소한 경우 null 반환 (표시하지 않음)
String? _getUserFriendlyMessage(String error) {
  final lower = error.toLowerCase();

  // 사용자가 로그인을 직접 취소한 경우 → 무시
  if (lower.contains('canceled') ||
      lower.contains('cancelled') ||
      lower.contains('user canceled') ||
      lower.contains('user_canceled') ||
      lower.contains('access_denied')) {
    return null;
  }

  if (lower.contains('network') || lower.contains('socket')) {
    return '네트워크 연결을 확인해 주세요';
  }
  if (lower.contains('timeout')) {
    return '요청 시간이 초과되었습니다. 다시 시도해 주세요';
  }
  if (lower.contains('account-exists') ||
      lower.contains('already in use')) {
    return '이미 다른 방법으로 가입된 계정입니다';
  }
  if (lower.contains('credential')) {
    return '인증 정보가 유효하지 않습니다. 다시 시도해 주세요';
  }

  return '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요';
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next is AsyncError) {
        final message = _getUserFriendlyMessage(next.error.toString());
        // 사용자가 직접 취소한 경우 에러를 표시하지 않음
        if (message == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textOnPrimary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            duration: const Duration(seconds: 3),
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
