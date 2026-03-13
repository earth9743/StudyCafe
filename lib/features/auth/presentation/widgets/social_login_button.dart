import 'package:flutter/material.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';

enum SocialLoginType { kakao, google }

class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.type,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isKakao = type == SocialLoginType.kakao;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isKakao ? AppColors.kakaoYellow : AppColors.googleWhite,
          foregroundColor: isKakao ? AppColors.kakaoBlack : AppColors.textPrimary,
          elevation: isKakao ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isKakao
                ? BorderSide.none
                : const BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isKakao ? Icons.chat_bubble : Icons.g_mobiledata,
              size: isKakao ? 20 : 28,
              color: isKakao ? AppColors.kakaoBlack : null,
            ),
            const SizedBox(width: 8),
            Text(
              isKakao ? '카카오로 시작하기' : 'Google로 시작하기',
              style: AppTextStyles.labelLarge.copyWith(
                color: isKakao ? AppColors.kakaoBlack : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
