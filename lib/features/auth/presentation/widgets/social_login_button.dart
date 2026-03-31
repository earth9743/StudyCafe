import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          backgroundColor:
              isKakao ? AppColors.kakaoYellow : AppColors.googleWhite,
          foregroundColor:
              isKakao ? AppColors.kakaoBlack : AppColors.textPrimary,
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
            SvgPicture.asset(
              isKakao
                  ? 'assets/icons/kakao_logo.svg'
                  : 'assets/icons/google_logo.svg',
              width: isKakao ? 22 : 24,
              height: isKakao ? 22 : 24,
            ),
            const SizedBox(width: 10),
            Text(
              isKakao ? '카카오 로그인' : 'Google로 시작하기',
              style: AppTextStyles.labelLarge.copyWith(
                color: isKakao ? AppColors.kakaoBlack : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
