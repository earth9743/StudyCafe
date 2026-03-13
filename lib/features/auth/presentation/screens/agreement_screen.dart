import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kagong_map/core/theme/app_colors.dart';
import 'package:kagong_map/core/theme/app_text_styles.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';

class AgreementScreen extends ConsumerStatefulWidget {
  const AgreementScreen({super.key});

  @override
  ConsumerState<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends ConsumerState<AgreementScreen> {
  bool _allAgreed = false;
  bool _termsAgreed = false;      // 필수: 서비스 이용약관
  bool _privacyAgreed = false;    // 필수: 개인정보 수집·이용 동의
  bool _locationAgreed = false;   // 필수: 위치정보 이용 동의
  bool _marketingAgreed = false;  // 선택: 마케팅 수신 동의

  bool get _requiredAgreed =>
      _termsAgreed && _privacyAgreed && _locationAgreed;

  void _toggleAll(bool? value) {
    setState(() {
      _allAgreed = value ?? false;
      _termsAgreed = _allAgreed;
      _privacyAgreed = _allAgreed;
      _locationAgreed = _allAgreed;
      _marketingAgreed = _allAgreed;
    });
  }

  void _updateAllAgreed() {
    setState(() {
      _allAgreed =
          _termsAgreed && _privacyAgreed && _locationAgreed && _marketingAgreed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('약관 동의'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              '카공지도 서비스 이용을 위해\n약관에 동의해 주세요.',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 32),

            // 전체 동의
            _AgreementTile(
              title: '전체 동의',
              isRequired: false,
              value: _allAgreed,
              onChanged: _toggleAll,
              isBold: true,
            ),
            const Divider(height: 32),

            // 필수 동의 항목
            _AgreementTile(
              title: '서비스 이용약관 동의',
              isRequired: true,
              value: _termsAgreed,
              onChanged: (v) {
                setState(() => _termsAgreed = v ?? false);
                _updateAllAgreed();
              },
              onDetailTap: () => _showTermsDetail(context, '서비스 이용약관'),
            ),
            const SizedBox(height: 12),
            _AgreementTile(
              title: '개인정보 수집·이용 동의',
              isRequired: true,
              value: _privacyAgreed,
              onChanged: (v) {
                setState(() => _privacyAgreed = v ?? false);
                _updateAllAgreed();
              },
              onDetailTap: () => _showTermsDetail(context, '개인정보 수집·이용'),
            ),
            const SizedBox(height: 12),
            _AgreementTile(
              title: '위치정보 이용 동의',
              isRequired: true,
              value: _locationAgreed,
              onChanged: (v) {
                setState(() => _locationAgreed = v ?? false);
                _updateAllAgreed();
              },
              onDetailTap: () => _showTermsDetail(context, '위치정보 이용'),
            ),
            const SizedBox(height: 12),

            // 선택 동의 항목
            _AgreementTile(
              title: '마케팅 정보 수신 동의',
              isRequired: false,
              value: _marketingAgreed,
              onChanged: (v) {
                setState(() => _marketingAgreed = v ?? false);
                _updateAllAgreed();
              },
            ),

            const Spacer(),

            // 동의 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _requiredAgreed
                    ? () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .saveAgreements(
                              terms: _termsAgreed,
                              privacy: _privacyAgreed,
                              location: _locationAgreed,
                              marketing: _marketingAgreed,
                            );
                        if (context.mounted) {
                          context.go('/');
                        }
                      }
                    : null,
                child: const Text('동의하고 시작하기'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showTermsDetail(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(title, style: AppTextStyles.h4),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _getTermsContent(title),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTermsContent(String title) {
    switch (title) {
      case '서비스 이용약관':
        return '''제1조 (목적)
이 약관은 카공지도(이하 "서비스")가 제공하는 모바일 애플리케이션 서비스의 이용 조건 및 절차, 이용자와 서비스 간의 권리, 의무 및 책임사항을 규정합니다.

제2조 (정의)
1. "서비스"란 카공지도가 제공하는 카페 정보 공유 플랫폼을 말합니다.
2. "이용자"란 이 약관에 따라 서비스를 이용하는 자를 말합니다.

제3조 (서비스 이용)
1. 서비스는 카페의 혼잡도, 콘센트 가용성, 소음 수준 등의 정보를 제공합니다.
2. 이용자는 서비스를 통해 카페 정보를 조회하고 보고할 수 있습니다.
3. 이용자가 제공하는 정보는 다른 이용자와 공유됩니다.

제4조 (이용자의 의무)
1. 이용자는 허위 정보를 제공하지 않아야 합니다.
2. 이용자는 타인의 권리를 침해하지 않아야 합니다.
3. 이용자는 서비스의 정상적인 운영을 방해하지 않아야 합니다.''';

      case '개인정보 수집·이용':
        return '''1. 수집하는 개인정보 항목
- 소셜 로그인 시: 이메일, 닉네임, 프로필 사진
- 서비스 이용 시: 위치 정보, 카페 보고 내역, 리뷰 내용

2. 수집 및 이용 목적
- 회원 식별 및 서비스 제공
- 카페 혼잡도, 콘센트, 소음 정보 제공
- 서비스 개선 및 통계 분석

3. 보유 및 이용 기간
- 회원 탈퇴 시까지
- 단, 관련 법령에 따라 보존이 필요한 경우 해당 기간 동안 보존

4. 동의 거부 권리
이용자는 개인정보 수집·이용에 동의하지 않을 수 있으나, 동의하지 않을 경우 서비스 이용이 제한됩니다.''';

      case '위치정보 이용':
        return '''1. 위치정보 수집 항목
- GPS를 통한 현재 위치 정보 (위도, 경도)

2. 위치정보 이용 목적
- 주변 카페 검색 및 지도 표시
- 카페까지의 거리 계산
- 카페 혼잡도 보고 시 위치 확인

3. 위치정보 보유 기간
- 위치 정보는 서버에 저장되지 않으며, 실시간 서비스 제공 목적으로만 사용됩니다.

4. 동의 거부 권리
이용자는 위치정보 이용에 동의하지 않을 수 있으나, 주변 카페 검색 기능이 제한됩니다.''';

      default:
        return '';
    }
  }
}

class _AgreementTile extends StatelessWidget {
  final String title;
  final bool isRequired;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onDetailTap;
  final bool isBold;

  const _AgreementTile({
    required this.title,
    required this.isRequired,
    required this.value,
    required this.onChanged,
    this.onDetailTap,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.check_circle_outline,
            color: value ? AppColors.primary : AppColors.textHint,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  if (isRequired)
                    TextSpan(
                      text: '[필수] ',
                      style: (isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium)
                          .copyWith(color: AppColors.primary),
                    ),
                  if (!isRequired && !isBold)
                    TextSpan(
                      text: '[선택] ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  TextSpan(
                    text: title,
                    style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          if (onDetailTap != null)
            IconButton(
              onPressed: onDetailTap,
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
